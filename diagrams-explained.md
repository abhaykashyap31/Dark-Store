# Darkstore Diagrams Explained

This document explains the two reference diagrams and how they fit together for the **Flutter frontend**.

| File | What it shows |
|------|----------------|
| [`1-architecture.png`](./1-architecture.png) | **Runtime architecture** — who talks to whom (Flutter → Gateway → microservices → DBs) |
| [`entities-erd-v2.png`](./entities-erd-v2.png) | **Data model (ERD)** — tables, fields, and relationships the APIs will eventually persist |

> **Frontend approach:** build Flutter with **Riverpod + Dio** against **mock JSON** shaped like the ERD, calling paths from the architecture diagram. Swap mocks for the real Spring Boot Gateway later.  
> Full phase plan: [`architecture.md`](./architecture.md)

---

## 1. How the two diagrams relate

Think of them as two views of the same system:

```
┌──────────────────────────┐         ┌──────────────────────────┐
│  1-architecture.png      │         │  entities-erd-v2.png     │
│  “How the app is wired”  │◀───────▶│  “What data looks like”  │
│                          │  maps   │                          │
│  Flutter / Gateway /     │   to    │  Tables & FKs / REFs     │
│  3 services / 3 DBs      │         │  grouped by service DB   │
└──────────────────────────┘         └──────────────────────────┘
                 │                                │
                 └────────────┬───────────────────┘
                              ▼
                    Flutter mock JSON
              (API responses shaped like ERD rows,
               exposed on Gateway-style paths)
```

| Architecture piece | Owns this ERD data (conceptually) |
|--------------------|-----------------------------------|
| **Auth & User Service** → `auth_db` | `users`, `addresses`, `refresh_tokens`, `stores` |
| **Catalog & Inventory Service** → `inventory_db` | `categories`, `products`, `store_inventory`, `stock_movements`, `reservations`, `reservation_items` |
| **Order & Fulfillment Service** → `orders_db` | `carts`, `cart_items`, `orders`, `order_items`, `order_status_history`, `payments` |

**Important for Flutter:** you never talk to the three databases. You talk only to the **Gateway** (or mocks that pretend to be the Gateway). The ERD tells you **what fields** those JSON responses should contain.

---

## 2. Architecture diagram (`1-architecture.png`)

### Layers (top → bottom)

1. **Flutter App (Dev 4)** — one app, role-based UIs
2. **API Gateway (Dev 1)** — Spring Cloud Gateway: JWT, routing, CORS; blocks `/internal/`**
3. **Three microservices (Java / Spring Boot)** — Auth, Catalog/Inventory, Order/Fulfillment
4. **Three PostgreSQL databases** — one DB per service

### Gateway routing (what Flutter will call)

| Path prefix | Goes to | Frontend use |
|-------------|---------|--------------|
| `/auth`, `/users`, `/stores` | Auth & User Service | Login, profile, addresses, stores, admin user/store ops |
| `/products`, `/categories`, `/inventory` | Catalog & Inventory | Browse, stock, prices, low-stock |
| `/cart`, `/orders`, `/manager/orders`, `/rider/orders` | Order & Fulfillment | Cart, checkout, track, manager queue, rider deliveries |

### Rules that bind the frontend

- Flutter talks **only** to the Gateway (never to services or `/internal/`**).
- After JWT validation, Gateway forwards: `X-User-Id`, `X-User-Role`, `X-Store-Id`, `X-Correlation-Id`.
- Only **Order → Inventory** may call across services (stock reserve/release/confirm) — invisible to Flutter.
- One database per service; **no cross-service foreign keys** in real DBs.
- Rider APIs need `RIDER` + store mapping; riders update only **assigned** orders.

### Diagram vs our agreed product rules

The PNG still shows older wording in places. For this project we follow:

| Topic | Use this (project truth) |
|-------|---------------------------|
| Roles | `USER`, `ADMIN`, `MANAGER`, `RIDER` (exactly one per user) |
| State management | **Riverpod** only (not Bloc) |
| Role storage | Single `users.role` column — **no** separate `roles` / `store_staff` tables (ERD is the source of truth here) |
| JWT | Includes `role` + `storeId` (null for USER/ADMIN) |

---

## 3. ER diagram (`entities-erd-v2.png`)

Color clusters match the architecture services:

### Blue — User & store identity (`auth_db`)

| Table | Purpose for UI |
|-------|----------------|
| `users` | Login identity; `role`; optional `store_id` for MANAGER/RIDER |
| `addresses` | USER saved delivery addresses |
| `refresh_tokens` | Session refresh (handled by Dio interceptor; rarely shown in UI) |
| `stores` | Dark-store locations; admin CRUD; USER picks a store to shop |

**Role model in ERD:** `users.role` is a single value (`USER` / `ADMIN` / `MANAGER` / `RIDER`). Managers and riders link to a store via `users.store_id`.

### Green — Catalog & inventory (`inventory_db`)

| Table | Purpose for UI |
|-------|----------------|
| `categories` | Browse hierarchy (`parent_id`) |
| `products` | Global catalogue (`sku`, `base_price`, image, …) |
| `store_inventory` | Per-store **price**, `quantity_on_hand`, `reserved_quantity`, low-stock threshold |
| `stock_movements` | Manager audit of stock changes |
| `reservations` / `reservation_items` | Hold stock during checkout — **backend-only**; Flutter does not call these |

### Orange — Cart & orders (`orders_db`)

| Table | Purpose for UI |
|-------|----------------|
| `carts` / `cart_items` | USER cart for a chosen store |
| `orders` | Placed order + delivery snapshot fields + `status` |
| `order_items` | Line items frozen at purchase time |
| `order_status_history` | Tracking timeline (who changed what, when) |
| `payments` | COD / mock payment status |

### Solid lines vs dashed red lines

| Line style | Meaning | Frontend implication |
|------------|---------|----------------------|
| **Solid** | Real FK **inside** the same service DB | Nested objects in that service’s JSON are safe |
| **Dashed red (REF)** | Logical link across services (e.g. `orders.user_id` → `users.id`) | APIs return **copied / denormalized** fields (name, phone, address text) — Flutter must not assume joins |

That is why `orders` stores delivery snapshot fields and `order_items` stores `sku` / `name` / `unit_price`: Order service cannot FK into Auth or Catalog databases.

---

## 4. Service ↔ table map (the join between the two PNGs)

```
Auth & User Service (auth_db)
  users · addresses · refresh_tokens · stores
           │
           │  JWT: userId, role, storeId
           ▼
Catalog & Inventory (inventory_db)          Order & Fulfillment (orders_db)
  categories · products                       carts · cart_items
  store_inventory · stock_movements           orders · order_items
  reservations · reservation_items ◀─Feign──  order_status_history · payments
         (/internal reserve|release|confirm)
```

| If Flutter needs… | Mock / call… | Shape data like… |
|-------------------|--------------|------------------|
| Login, me, addresses, stores, admin users | `/auth`, `/users`, `/stores`, `/admin/...` | `users`, `addresses`, `stores` |
| Browse products & stock | `/products`, `/categories`, `/inventory` | `products`, `categories`, `store_inventory` |
| Cart, place order, track, cancel | `/cart`, `/orders` | `carts`, `cart_items`, `orders`, `order_items`, `order_status_history`, `payments` |
| Manager queue / assign rider | `/manager/orders` | `orders` (+ rider user id) |
| Rider deliveries | `/rider/orders` | `orders` filtered by assignee |
| Reserve stock | — | **Not a Flutter API** (Order→Inventory internal) |

---

## 5. Role → screens → ERD tables → architecture paths

| Role | Main screens | ERD tables involved | Gateway paths |
|------|--------------|---------------------|---------------|
| **USER** | Browse, cart, checkout, track, cancel, profile | `stores`, `categories`, `products`, `store_inventory`, `carts`, `cart_items`, `addresses`, `orders`, `order_items`, `order_status_history`, `payments` | `/stores`, `/products`, `/categories`, `/cart`, `/orders`, `/users/me/addresses` |
| **ADMIN** | Stores, create manager/rider, catalogue, activate accounts | `stores`, `users`, `products`, `categories` | `/admin/stores`, `/admin/users`, `/admin/products`, `/categories` |
| **MANAGER** | Stock/prices, pick/pack queue, assign rider | `store_inventory`, `stock_movements`, `orders`, `order_status_history`, `users` (riders) | `/inventory`, `/manager/orders` |
| **RIDER** | Assigned list, out-for-delivery, delivered | `orders`, `order_status_history`, `payments` (COD) | `/rider/orders` |

---

## 6. Mock JSON strategy (frontend-first)

Until Spring Boot is ready:

1. Keep Dio base URL / clients pointed at **Gateway-shaped paths**.
2. Serve **local JSON** (assets or in-memory mocks) whose objects match **ERD fields**.
3. Put `role` + `storeId` on the mock login response (same as future JWT claims).
4. Filter manager/rider mocks by `storeId`; rider mocks only return assigned orders.
5. When backend is live, flip `useMockApis = false` — **screen code should not change**, only the data source.

### Example: ERD row → mock API response

**ERD** `products` **+** `store_inventory` become one customer-facing product DTO:

```json
{
  "id": "p_100",
  "sku": "MLK-1L",
  "name": "Milk 1L",
  "categoryId": "c_01",
  "imageUrl": null,
  "price": 55.0,
  "currency": "INR",
  "stockQty": 42,
  "inStock": true
}
```

(`price` / stock come from `store_inventory` for the selected store; catalogue fields from `products`.)

**ERD** `orders` **+** `order_status_history` become track-order UI:

```json
{
  "id": "o_500",
  "orderNumber": "DS-10021",
  "status": "ASSIGNED",
  "storeId": "s_001",
  "totalAmount": 320.0,
  "delivery": {
    "recipientName": "Asha",
    "phone": "9xxxxxxxxx",
    "addressText": "12 MG Road, …"
  },
  "items": [
    { "sku": "MLK-1L", "name": "Milk 1L", "unitPrice": 55.0, "quantity": 2 }
  ],
  "statusHistory": [
    { "fromStatus": null, "toStatus": "CREATED", "changedAt": "2026-11-19T10:00:00Z" },
    { "fromStatus": "PACKED", "toStatus": "ASSIGNED", "changedByRole": "MANAGER", "changedAt": "…" }
  ]
}
```

---

## 7. What Flutter should ignore (backend-only)

These appear on the ERD / architecture but **must not** be called from the app:

| Concern | Why |
|---------|-----|
| `/internal/**` inventory reserve/release/confirm | Only Order → Inventory (Feign) |
| `reservations` / `reservation_items` tables | Internal stock holds |
| `refresh_tokens` table rows | Opaque tokens via `/auth/refresh` only |
| Cross-DB joins | Use snapshot / denormalized API fields instead |

---

## 8. Quick mental model

| Question                                  | Look at               |
| ----------------------------------------- | --------------------- |
| Which microservice / URL do I call?       | `1-architecture.png`  |
| Which fields go in my models & mock JSON? | `entities-erd-v2.png` |
| Which screens / phases to build?          | `architecture.md`     |

**One line summary:** the architecture PNG is the **wiring**; the ERD PNG is the **data shape**; Flutter mocks sit in between until the Java/Spring Boot Gateway is connected.
