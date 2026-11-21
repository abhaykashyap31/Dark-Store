# Backend Integration Guide (Flutter ↔ API Gateway)

This document describes how the iDarkStore Flutter app connects to the Spring Cloud API Gateway, which endpoint placeholders exist, and how to flip from mocks to the live backend.

Related docs:

- [`architecture.md`](./architecture.md) — full system architecture and API contracts
- [`README.md`](./README.md) — run instructions and demo accounts

---

## 1. Principles

| Rule | Detail |
|------|--------|
| Gateway only | Dio `baseUrl` = Gateway. Never call Auth / Catalog / Order services directly. |
| No `/internal/**` | Service-to-service routes are blocked in Dio. Do not add them to the app. |
| JWT in `Authorization` | Access token as `Bearer <token>`. Role + `storeId` come from JWT / `/users/me`. |
| Correlation ID | Every request gets `X-Correlation-Id` (UUID) for tracing. |
| Mocks by default | `USE_MOCK_APIS=true` so UI works without a running Gateway. |

---

## 2. Flutter files involved

| File | Purpose |
|------|---------|
| `lib/core/config/app_config.dart` | `API_BASE_URL`, `USE_MOCK_APIS`, timeouts, logging flags |
| `lib/core/network/api_endpoints.dart` | **All** Gateway-relative path constants |
| `lib/core/network/dio_client.dart` | Dio setup, Bearer header, correlation ID, mock stack |
| `lib/core/network/auth_interceptor.dart` | 401 → refresh → retry or clear session |
| `lib/core/network/logging_interceptor.dart` | Optional request/response logs (`ENABLE_API_LOGS`) |
| `lib/core/network/mock_interceptor.dart` | Local JSON when mocks are on |
| `lib/features/*/application/*_repository.dart` | Call sites using `ApiEndpoints.*` |

---

## 3. Dart defines (build / run)

| Define | Default | Meaning |
|--------|---------|---------|
| `API_BASE_URL` | `http://localhost:8080` | Gateway origin (no trailing slash) |
| `USE_MOCK_APIS` | `true` | `false` = real HTTP to Gateway |
| `ENABLE_API_LOGS` | `false` | Log method/path/status in debug (tokens redacted) |
| `API_CONNECT_TIMEOUT_SEC` | `15` | Connect timeout |
| `API_RECEIVE_TIMEOUT_SEC` | `30` | Receive timeout |

### Local mocks (default)

```bash
flutter run
```

### Live Gateway

```bash
flutter run \
  --dart-define=USE_MOCK_APIS=false \
  --dart-define=API_BASE_URL=http://localhost:8080 \
  --dart-define=ENABLE_API_LOGS=true
```

### Production-style build

```bash
flutter build web \
  --dart-define=USE_MOCK_APIS=false \
  --dart-define=API_BASE_URL=https://gateway.example.com
```

**Web / CORS:** Gateway must allow the Flutter origin (e.g. `http://localhost:xxxxx`) and headers `Authorization`, `Content-Type`, `X-Correlation-Id`.

---

## 4. Endpoint placeholders (`ApiEndpoints`)

All paths are relative to `API_BASE_URL`. Source of truth: `lib/core/network/api_endpoints.dart`.

### Auth

| Method | Path | Used by |
|--------|------|---------|
| `POST` | `/auth/register` | AuthRepository |
| `POST` | `/auth/login` | AuthRepository |
| `POST` | `/auth/refresh` | AuthRepository, AuthInterceptor |
| `POST` | `/auth/logout` | AuthRepository |

### Users / profile

| Method | Path | Used by |
|--------|------|---------|
| `GET` | `/users/me` | AuthRepository |
| `GET` / `POST` | `/users/me/addresses` | OrderRepository |
| `PUT` / `DELETE` | `/users/me/addresses/{id}` | Placeholder (ready when UI needs edit/delete) |

### Catalog (USER)

| Method | Path | Used by |
|--------|------|---------|
| `GET` | `/stores` | CatalogRepository |
| `GET` | `/stores/{id}` | Placeholder |
| `GET` / `POST` | `/categories` | Catalog + Admin |
| `GET` | `/products` | CatalogRepository (`storeId`, optional `categoryId`, `q`) |
| `GET` | `/products/{id}` | CatalogRepository |

### Cart / orders (USER)

| Method | Path | Used by |
|--------|------|---------|
| `GET` | `/cart` | CartRepository |
| `POST` | `/cart/items` | CartRepository |
| `PUT` / `DELETE` | `/cart/items/{id}` | CartRepository |
| `GET` / `POST` | `/orders` | OrderRepository |
| `GET` | `/orders/{id}` | Order / Manager / Rider |
| `POST` | `/orders/{id}/cancel` | OrderRepository |

### Admin

| Method | Path | Used by |
|--------|------|---------|
| `GET` / `POST` | `/admin/stores` | AdminRepository |
| `PUT` | `/admin/stores/{id}` | AdminRepository |
| `PATCH` | `/admin/stores/{id}/active` | AdminRepository |
| `GET` / `POST` | `/admin/users` | AdminRepository |
| `PATCH` | `/admin/users/{id}/active` | AdminRepository |
| `GET` / `POST` | `/admin/products` | AdminRepository |
| `PUT` | `/admin/products/{id}` | AdminRepository |
| `PATCH` | `/admin/products/{id}/active` | AdminRepository |

### Manager

| Method | Path | Used by |
|--------|------|---------|
| `GET` | `/manager/orders` | ManagerRepository |
| `PATCH` | `/manager/orders/{id}/status` | ManagerRepository |
| `POST` | `/manager/orders/{id}/assign-rider` | ManagerRepository |
| `GET` | `/manager/riders` | ManagerRepository |
| `GET` | `/inventory` | ManagerRepository |
| `PUT` | `/inventory/{productId}` | ManagerRepository |
| `GET` | `/inventory/alerts` | ManagerRepository |

### Rider

| Method | Path | Used by |
|--------|------|---------|
| `GET` | `/rider/orders` | RiderRepository |
| `PATCH` | `/rider/orders/{id}/status` | RiderRepository |

### Forbidden

| Path prefix | Reason |
|-------------|--------|
| `/internal/**` | Rejected by Dio; Gateway should also block external clients |

---

## 5. Expected request / response shapes

Keep DTOs aligned with models under `lib/shared/models/`. High-level conventions:

**Auth login / register / refresh success**

```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "expiresIn": 3600,
  "user": {
    "id": "...",
    "name": "...",
    "email": "...",
    "role": "USER|ADMIN|MANAGER|RIDER",
    "storeId": null,
    "active": true
  }
}
```

**List endpoints** — wrap arrays as `{ "items": [ ... ] }`.

**Errors** — prefer `{ "message": "Human readable" }` with appropriate HTTP status (`401`, `403`, `404`, `409`, `422`, `500`).

**JWT claims (recommended)** — `sub` (user id), `role`, `storeId` (for MANAGER/RIDER), `active`.

---

## 6. Headers

| Header | Who sets it | Notes |
|--------|-------------|--------|
| `Authorization: Bearer <access>` | Dio interceptor | Omitted when no token |
| `Content-Type: application/json` | Dio base options | |
| `Accept: application/json` | Dio base options | |
| `X-Correlation-Id` | Dio interceptor | New UUID per request |

On refresh, AuthInterceptor posts to `/auth/refresh` with the refresh token and retries the original request once.

---

## 7. Flip checklist (Phase 8)

Use this when Dev 1–3 Gateway + services are ready:

1. [ ] Gateway URL reachable from the Flutter host (device / browser / emulator).
2. [ ] CORS configured for web (if `flutter run -d chrome`).
3. [ ] Run with `USE_MOCK_APIS=false` and correct `API_BASE_URL`.
4. [ ] Login / register / refresh / logout against live Auth.
5. [ ] `/users/me` returns role + `storeId` matching JWT.
6. [ ] USER: stores → products → cart → checkout → orders.
7. [ ] ADMIN: stores / users / products CRUD + active flags.
8. [ ] MANAGER: orders, assign rider, inventory, alerts (scoped by `storeId`).
9. [ ] RIDER: assigned deliveries + status transitions.
10. [ ] 401 with expired access token refreshes; failed refresh clears session.
11. [ ] Confirm no Flutter calls hit `/internal/**`.
12. [ ] Optional: `ENABLE_API_LOGS=true` while debugging.

---

## 8. Adding a new endpoint

1. Add the path to `lib/core/network/api_endpoints.dart`.
2. Call it from the feature repository via `ApiEndpoints.*`.
3. If mocks are still needed, handle the path in `mock_interceptor.dart` + `lib/placeholders/`.
4. Document method/path in this file and in `architecture.md` §6 if the contract is new.

---

## 9. Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| Still seeing mock data | `USE_MOCK_APIS` still `true` (default) |
| CORS errors in browser | Gateway CORS missing Flutter origin / headers |
| Immediate logout after load | Refresh failing or `/users/me` 401 |
| 403 on manager/rider APIs | JWT missing / wrong `storeId` or role |
| Connection refused | Wrong `API_BASE_URL` or Gateway not running |
| Paths with `/internal` rejected | Intentional — use public Gateway routes only |

---

## 10. Status

| Layer | Status |
|-------|--------|
| Endpoint placeholders (`ApiEndpoints`) | Done |
| Repositories wired to constants | Done |
| Mock interceptor (local JSON) | Done (default on) |
| Live Gateway | Pending Dev 1–3 — flip with dart-defines above |
