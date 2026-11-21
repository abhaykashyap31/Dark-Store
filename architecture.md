# Darkstore — Phase-wise Architecture

> **Scope:** Flutter frontend (Dev 4) first, with **API / microservice placeholders** for a Java/Spring Boot backend (Dev 1–3). Backend services are **not built in this repo** — only contracts and mocks so Flutter can proceed.  
> **Roles (exactly one per user):** `USER` · `ADMIN` · `MANAGER` · `RIDER`

---

## 1. System Overview

```
┌─────────────────────────────────────────────────────────────┐
│  Flutter App (Dev 4)                                        │
│  User UI · Admin UI · Manager UI · Rider UI                 │
│  Dio · Riverpod · Secure Storage (JWT)                      │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTPS REST + JWT
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  API Gateway (Dev 1) — Spring Cloud Gateway                 │
│  JWT check · Routing · CORS · Block /internal/**            │
│  Forwards: X-User-Id · X-User-Role · X-Store-Id             │
│            X-Correlation-Id                                 │
└───────┬─────────────────────┬───────────────────┬───────────┘
        │ /auth /users /stores│ /products /cats   │ /cart /orders
        │ /admin/**           │ /inventory        │ /manager|/rider
        ▼                     ▼                   ▼
┌───────────────┐   ┌──────────────────┐   ┌────────────────────┐
│ Auth & User   │   │ Catalog &        │   │ Order &            │
│ Service       │   │ Inventory Svc    │   │ Fulfillment Svc    │
│ Java/Spring   │   │ Java/Spring      │   │ Java/Spring        │
│ Boot (Dev 1)  │   │ Boot (Dev 2)     │   │ Boot (Dev 3)       │
│ auth_db       │   │ inventory_db     │   │ orders_db          │
└───────────────┘   └────────▲─────────┘   └─────────┬──────────┘
                             │ REST (Feign) only     │
                             └───────────────────────┘
```

### Rules (non-negotiable)

| Rule | Detail |
|------|--------|
| Flutter → Gateway only | No direct calls to Auth / Catalog / Order services |
| JWT carries identity | Login token includes **role** and **storeId** (null for USER/ADMIN); every service trusts gateway-forwarded headers |
| One role per user | Stored as a single `role` column on `users` — **no separate roles table** |
| One DB per service | No cross-service foreign keys |
| Cross-service call | Only Order → Inventory via `/internal/**` (gateway blocks this from Flutter) |
| Idempotency | Reserve / release / confirm inventory must be idempotent |
| Store-scoped staff | MANAGER and RIDER are linked to one store via `store_id`; services enforce that scope |
| Rider access | `RIDER` + `storeId` in JWT; riders update only orders assigned to them |

---

## 2. Roles & Capabilities

Each person has **exactly one** role. Role + `storeId` are embedded in the JWT at login; Flutter routes to the matching UI shell, and every backend service re-checks them for authorization.

| Role | Who | `storeId` in JWT | Capabilities |
|------|-----|------------------|--------------|
| **USER** | Customer who places orders | `null` | Profile, saved delivery addresses, browse products, cart, place/track orders, **cancel before packing**, order history |
| **ADMIN** | Platform operator | `null` | Create/edit stores, create MANAGER & RIDER accounts, manage product catalogue, activate/deactivate any account |
| **MANAGER** | Runs one dark store | required | Manage that store’s stock & prices, view/process incoming orders (picking & packing), hand packed orders to a rider |
| **RIDER** | Delivery staff for one store | required | See assigned orders, pick up packed orders, mark out-for-delivery, mark delivered |

### Order cancellation rule (USER)

USER may cancel only **before packing** begins (statuses before `PICKING` / packing — typically `CREATED` / `CONFIRMED`). Once picking/packing starts, cancel is disabled in the UI and rejected by the Order service.

### Order state machine (UI labels)

```
CREATED → CONFIRMED → PICKING → PACKED → ASSIGNED →
OUT_FOR_DELIVERY → DELIVERED

CREATED / CONFIRMED ──(USER cancel)──▶ CANCELLED
```

| Actor | Typical transitions |
|-------|---------------------|
| USER | Place order → track; cancel while `CREATED` / `CONFIRMED` |
| MANAGER | `CONFIRMED` → `PICKING` → `PACKED`; then assign rider → `ASSIGNED` |
| RIDER | `ASSIGNED` → `OUT_FOR_DELIVERY` → `DELIVERED` |

---

## 3. Frontend Stack (Flutter)

| Concern | Choice | Notes |
|---------|--------|--------|
| HTTP | **Dio** | Interceptors: JWT attach, refresh, `X-Correlation-Id` |
| State | **Riverpod** | App-wide only; providers under `lib/features/`** and `lib/core/` |
| Auth storage | **flutter_secure_storage** | Access + refresh tokens only |
| Routing | **go_router** | Role-based redirects after login (`USER` / `ADMIN` / `MANAGER` / `RIDER`) |
| Models | Freezed / json_serializable | Match API DTOs once backends stabilize |
| Env | `--dart-define` / `.env` | `API_BASE_URL` → gateway only |

### Suggested package layout

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/          # base URL, feature flags (useMockApis)
│   ├── network/         # Dio client, interceptors, API clients
│   ├── storage/         # secure token store
│   ├── router/          # go_router + role guards
│   ├── theme/
│   └── constants/       # AppRole enum: user, admin, manager, rider
├── features/
│   ├── auth/
│   ├── user/            # customer (USER role)
│   ├── admin/
│   ├── manager/
│   └── rider/
├── shared/
│   ├── widgets/
│   ├── models/          # User, Store, Product, OrderSummary, …
│   └── utils/
└── placeholders/        # mock responses until Spring services are live
    ├── auth_api_mock.dart
    ├── catalog_api_mock.dart
    ├── order_api_mock.dart
    └── admin_api_mock.dart
```

---

## 4. Backend (Java / Spring Boot) — placeholders only

> **Not implemented in this repo.** Flutter talks only to the Gateway contract below. When Spring Boot services go live, flip `useMockApis = false`.

| Component | Stack (expected) | Responsibility |
|-----------|------------------|----------------|
| API Gateway | Spring Cloud Gateway | JWT validation, routing, CORS, block `/internal/**` |
| Auth & User Service | Spring Boot + PostgreSQL (`auth_db`) | Auth, users (single `role` column), addresses, stores, account active flag |
| Catalog & Inventory | Spring Boot + PostgreSQL (`inventory_db`) | Products, categories, per-store stock/prices, reserve/release/confirm |
| Order & Fulfillment | Spring Boot + PostgreSQL (`orders_db`) | Cart, orders, manager/rider flows, COD/mock pay; Feign → Inventory `/internal/**` |

### Auth DB shape (conceptual — for frontend mocks)

```
users:     id, email, password_hash, name, role, store_id, active, …
addresses: id, user_id, …          # USER delivery addresses
stores:    id, name, address, active, …
```

- `role` ∈ {`USER`, `ADMIN`, `MANAGER`, `RIDER`} — **no** `roles` **table**
- `store_id` required for MANAGER / RIDER; null for USER / ADMIN

### JWT claims (contract)

```json
{
  "sub": "u_001",
  "role": "MANAGER",
  "storeId": "s_001",
  "exp": 1730000000
}
```

Gateway validates JWT and forwards:

- `X-User-Id`
- `X-User-Role`
- `X-Store-Id` (empty/absent when null)
- `X-Correlation-Id`

---

## 5. Role → UI & Gateway Paths

| Role | Primary Flutter shell | Gateway paths used |
|------|------------------------|--------------------|
| **USER** | Browse, cart, checkout, track, cancel, profile/addresses | `/auth`, `/users`, `/stores`, `/products`, `/categories`, `/cart`, `/orders` |
| **ADMIN** | Stores, staff accounts, catalogue, activate/deactivate users | `/auth`, `/users`, `/admin/stores`, `/admin/users`, `/admin/products`, `/categories` |
| **MANAGER** | Store stock/prices, order queue (pick/pack), assign rider | `/auth`, `/users`, `/products`, `/inventory`, `/manager/orders` |
| **RIDER** | Assigned deliveries, status updates | `/auth`, `/users`, `/rider/orders` |

After login, Flutter reads `role` (and `storeId` if present) from the login response / JWT and opens the matching shell.

---

## 6. API Placeholders (Gateway contract)

> All paths are **relative to the Gateway**. Flutter **never** calls `/internal/`**.

### 6.1 Auth & User Service

| Method | Path | Purpose | Roles |
|--------|------|---------|-------|
| `POST` | `/auth/register` | Self-register as **USER** only | Public |
| `POST` | `/auth/login` | Login → JWT + refresh (claims: role, storeId) | Public |
| `POST` | `/auth/refresh` | Refresh access token | Authenticated |
| `POST` | `/auth/logout` | Invalidate refresh | Authenticated |
| `GET` | `/users/me` | Profile + role + storeId + active | All |
| `PUT` | `/users/me` | Update own profile | All |
| `GET` | `/users/me/addresses` | List addresses | USER |
| `POST` | `/users/me/addresses` | Add address | USER |
| `PUT` | `/users/me/addresses/{id}` | Update address | USER |
| `DELETE` | `/users/me/addresses/{id}` | Delete address | USER |
| `GET` | `/stores` | List active stores (service area) | USER |
| `GET` | `/stores/{id}` | Store detail | USER, MANAGER |

**Login placeholder:**

```json
{
  "accessToken": "jwt...",
  "refreshToken": "refresh...",
  "expiresIn": 900,
  "user": {
    "id": "u_001",
    "email": "user@example.com",
    "name": "Asha",
    "role": "USER",
    "storeId": null,
    "active": true
  }
}
```

**Manager login example (**`storeId` **present):**

```json
{
  "accessToken": "jwt...",
  "refreshToken": "refresh...",
  "expiresIn": 900,
  "user": {
    "id": "u_010",
    "email": "manager@store.com",
    "name": "Store Manager",
    "role": "MANAGER",
    "storeId": "s_001",
    "active": true
  }
}
```

---

### 6.2 Admin APIs (Auth + Catalog via Gateway)

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/admin/stores` | List all stores |
| `POST` | `/admin/stores` | Create store |
| `PUT` | `/admin/stores/{id}` | Edit store |
| `PATCH` | `/admin/stores/{id}/active` | Activate / deactivate store |
| `GET` | `/admin/users` | List accounts (`?role=&active=`) |
| `POST` | `/admin/users` | Create MANAGER or RIDER (`role`, `storeId`, credentials) |
| `PATCH` | `/admin/users/{id}/active` | Activate / deactivate any account |
| `GET` | `/admin/products` | Catalogue admin list |
| `POST` | `/admin/products` | Create product |
| `PUT` | `/admin/products/{id}` | Edit product |
| `PATCH` | `/admin/products/{id}/active` | Activate / deactivate product |
| `GET/POST/PUT` | `/categories` | Manage categories *(admin)* |

> Self-registration never creates ADMIN / MANAGER / RIDER — those accounts are created by Admin (or seeded).

---

### 6.3 Catalog & Inventory Service

| Method | Path | Purpose | Roles |
|--------|------|---------|-------|
| `GET` | `/categories` | Category list | USER, ADMIN |
| `GET` | `/products` | Products (`?storeId=&categoryId=&q=`) | USER, MANAGER |
| `GET` | `/products/{id}` | Product detail | USER |
| `GET` | `/inventory` | Per-store stock (`storeId` from JWT for manager) | MANAGER |
| `GET` | `/inventory/{productId}` | One SKU at store | MANAGER |
| `PUT` | `/inventory/{productId}` | Update stock and/or price for store | MANAGER |
| `GET` | `/inventory/alerts` | Low-stock alerts | MANAGER |

> **Not called from Flutter:** `/internal/inventory/reserve|release|confirm` — Order Service only.

**Product list placeholder:**

```json
{
  "items": [
    {
      "id": "p_100",
      "name": "Milk 1L",
      "categoryId": "c_01",
      "price": 55.0,
      "currency": "INR",
      "inStock": true,
      "stockQty": 42,
      "imageUrl": null
    }
  ],
  "page": 0,
  "total": 1
}
```

---

### 6.4 Order & Fulfillment Service

| Method | Path | Purpose | Roles |
|--------|------|---------|-------|
| `GET` | `/cart` | Get cart | USER |
| `POST` | `/cart/items` | Add line (`productId`, `qty`, `storeId`) | USER |
| `PUT` | `/cart/items/{id}` | Update qty | USER |
| `DELETE` | `/cart/items/{id}` | Remove line | USER |
| `POST` | `/orders` | Place order (COD / mock pay) | USER |
| `GET` | `/orders` | My order history | USER |
| `GET` | `/orders/{id}` | Order detail + tracking | USER |
| `POST` | `/orders/{id}/cancel` | Cancel if before packing | USER |
| `GET` | `/manager/orders` | Store queue (`?status=`) | MANAGER |
| `PATCH` | `/manager/orders/{id}/status` | Picking / packing transitions | MANAGER |
| `POST` | `/manager/orders/{id}/assign-rider` | Hand over packed order to rider | MANAGER |
| `GET` | `/rider/orders` | Assigned deliveries | RIDER |
| `PATCH` | `/rider/orders/{id}/status` | Out-for-delivery / delivered | RIDER |

**Rider list placeholder:**

```json
{
  "items": [
    {
      "id": "o_500",
      "status": "ASSIGNED",
      "storeId": "s_001",
      "customerName": "Asha",
      "addressSummary": "12 MG Road",
      "itemsCount": 4,
      "codAmount": 320.0
    }
  ]
}
```

---

## 7. Phase-wise Delivery Plan

Phases ship **Flutter UI + Riverpod + mocks first**, then swap to the live Spring Cloud Gateway.

---

### Phase 0 — Project bootstrap *(Frontend)*

**Goal:** Runnable Flutter app with Riverpod, role router, and networking stubs.

| Task | Done when |
|------|-----------|
| Create Flutter project + folder layout | App builds |
| Riverpod root (`ProviderScope`) + core providers | App state wired |
| Dio client + `X-Correlation-Id` + mock toggle | Requests hit mock layer |
| Secure storage for tokens | Tokens survive restart |
| go_router: splash → login → role home (4 shells) | Mock JWT role redirects correctly |
| `useMockApis = true` feature flag | Easy swap later |
| Theme + shared widgets | Consistent UI kit |

**Backend:** not required — local mocks only.

---

### Phase 1 — Auth & session *(all 4 roles)*

**Goal:** Register (USER) / login / logout / refresh; route into correct shell.

| Screens | API placeholders |
|---------|------------------|
| Splash / session restore | `POST /auth/refresh` |
| Login | `POST /auth/login` |
| Register (USER only) | `POST /auth/register` |
| Profile shell | `GET /users/me` |

**Acceptance**

- [x] Mock login as `USER` / `ADMIN` / `MANAGER` / `RIDER` opens the correct home
- [x] Inactive account (`active: false`) cannot enter the app
- [x] MANAGER / RIDER mocks include `storeId` in token payload
- [x] Dio attaches `Authorization: Bearer <accessToken>`

**Later dependency:** Auth & User Service (Spring Boot) + Gateway JWT validation.

---

### Phase 2 — USER browse & catalog

**Goal:** Store selection → categories → products → detail.

| Screens | API placeholders |
|---------|------------------|
| Store picker | `GET /stores` |
| Home / categories | `GET /categories` |
| Product grid | `GET /products?storeId=` |
| Product detail | `GET /products/{id}` |

**Acceptance**

- [x] USER picks a store and browses mock catalog
- [x] Out-of-stock items labeled / not addable
- [x] Selected `storeId` held in Riverpod for cart/orders

---

### Phase 3 — USER cart & checkout

**Goal:** Cart CRUD → place order (COD / mock) → confirmation.

| Screens | API placeholders |
|---------|------------------|
| Cart | `GET/POST/PUT/DELETE /cart…` |
| Checkout (address + payment) | `GET /users/me/addresses`, `POST /orders` |
| Confirmation | `GET /orders/{id}` |

**Acceptance**

- [x] Empty cart / missing address blocks checkout
- [x] Confirmation shows `CREATED` / `CONFIRMED`

---

### Phase 4 — USER orders, tracking & cancel

**Goal:** History, timeline, cancel-before-packing.

| Screens | API placeholders |
|---------|------------------|
| Order list | `GET /orders` |
| Order detail / tracking | `GET /orders/{id}` |
| Cancel action | `POST /orders/{id}/cancel` |

**Acceptance**

- [x] Timeline matches state machine
- [x] Cancel enabled only for `CREATED` / `CONFIRMED`; hidden/disabled after packing starts
- [x] Pull-to-refresh updates status

---

### Phase 5 — ADMIN workspace

**Goal:** Platform management UI.

| Screens | API placeholders |
|---------|------------------|
| Stores list / create / edit | `GET/POST/PUT /admin/stores`, activate patch |
| Create manager / rider accounts | `POST /admin/users` (role + storeId) |
| Accounts list + activate/deactivate | `GET /admin/users`, `PATCH …/active` |
| Product catalogue CRUD | `GET/POST/PUT /admin/products`, categories |

**Acceptance**

- [x] Only `ADMIN` reaches this shell
- [x] Creating MANAGER/RIDER requires selecting a store
- [x] Deactivated user cannot log in (mock enforces)

---

### Phase 6 — MANAGER workspace

**Goal:** One-store stock/prices + pick/pack + handoff to rider.

| Screens | API placeholders |
|---------|------------------|
| Manager home (order queue) | `GET /manager/orders?status=` |
| Pick / pack status actions | `PATCH /manager/orders/{id}/status` |
| Assign rider | `POST /manager/orders/{id}/assign-rider` |
| Stock & prices | `GET /inventory`, `PUT /inventory/{productId}` |
| Low-stock alerts | `GET /inventory/alerts` |

**Acceptance**

- [x] `storeId` comes from JWT / `/users/me`, never hard-coded
- [x] UI only offers legal next statuses (`PICKING` → `PACKED` → assign)
- [x] Inventory edits scoped to manager’s store

---

### Phase 7 — RIDER workspace

**Goal:** Assigned deliveries and delivery status updates.

| Screens | API placeholders |
|---------|------------------|
| Rider home | `GET /rider/orders` |
| Delivery detail | Order fields from list/detail |
| Status actions | `PATCH /rider/orders/{id}/status` |

**Allowed rider transitions:**

```
ASSIGNED → OUT_FOR_DELIVERY → DELIVERED
```

**Acceptance**

- [x] Missing `storeId` shows a clear error
- [x] Only assigned orders visible (mock filter)
- [x] COD amount shown on delivery card

---

### Phase 8 — Gateway integration *(Flutter ↔ Spring Boot)*

**Goal:** Point Dio at real Gateway; disable mocks for integration builds.

> **Flutter prep done:** see [`BACKEND_INTEGRATION.md`](./BACKEND_INTEGRATION.md) and `lib/core/network/api_endpoints.dart`.

| Task | Notes |
|------|--------|
| `API_BASE_URL` = Gateway | HTTPS + CORS |
| Real JWT (role + storeId claims) | Auth service live |
| Error mapping | 401 → refresh → logout; 403 role; 409 stock |
| Correlation id | Verify in gateway/service logs |
| Mocks | Debug / offline flag only (`USE_MOCK_APIS`) |

**Do not call from Flutter:** any `/internal/`** route.

---

### Phase 9 — Hardening & QA

| Area | Work |
|------|------|
| Idempotency UX | Safe retries on place-order / status patch |
| Empty / error states | Per-role consistent widgets |
| Security | Tokens only in secure storage; no secrets in logs |
| QA matrix | USER / ADMIN / MANAGER / RIDER happy paths + cancel rules + inactive accounts |
| Performance | Paginated products & orders |

---

## 8. Flutter ↔ Gateway Contract Checklist

- [ ] Base URL = Gateway only  
- [ ] `Authorization: Bearer <accessToken>` on protected routes  
- [ ] `X-Correlation-Id` per request (UUID)  
- [ ] UI shell driven by JWT / `/users/me` **role** (`USER`  `ADMIN`  `MANAGER`  `RIDER`)  
- [ ] `storeId` for MANAGER / RIDER from token — never hard-coded  
- [ ] USER cancel only before packing  
- [ ] No `/internal/**` in Dio paths  
- [ ] Refresh: 401 → refresh once → retry → logout  
- [ ] State management is **Riverpod** only  

---

## 9. Ownership

| Component | Owner | Status for frontend |
|-----------|-------|---------------------|
| Flutter app (USER / ADMIN / MANAGER / RIDER) + Riverpod | **Dev 4** | **Build now** |
| API Gateway (Spring Cloud Gateway) | Dev 1 | Placeholder → Phase 8 |
| Auth & User Service (Spring Boot) + `auth_db` | Dev 1 | Mock until Phase 8 |
| Catalog & Inventory (Spring Boot) + `inventory_db` | Dev 2 | Mock until Phase 8 |
| Order & Fulfillment (Spring Boot) + `orders_db` | Dev 3 | Mock until Phase 8 |

---

## 10. Phase Summary

| Phase | Focus | Live Spring Boot needed? |
|-------|--------|---------------------------|
| **0** | Bootstrap, Dio, Riverpod, router, mocks | No |
| **1** | Auth & 4 role shells | No (mock) |
| **2** | USER catalog | No (mock) |
| **3** | USER cart & checkout | No (mock) |
| **4** | USER tracking & cancel | No (mock) |
| **5** | ADMIN platform UI | No (mock) |
| **6** | MANAGER store ops | No (mock) |
| **7** | RIDER deliveries | No (mock) |
| **8** | Real Gateway + services | **Yes** |
| **9** | Hardening & QA | Yes |

---

## 11. Next immediate step

Start **Phase 0**: scaffold the Flutter project with Riverpod, the four role shells, Dio + mock toggle, and go_router guards so Phases 1–7 can proceed against API placeholders.
