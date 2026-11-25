# Dark Store Backend: Auth, Inventory, Orders, and API Gateway

Auth, Inventory, and Gateway use Spring Boot 3.3.5; Cart and Order uses Spring Boot 4.2.0. All four services target Java 17 and have independent Maven POMs under this directory. The repository-root POM aggregates all four services for one build and test command.

## Ports

| Component         | Port | Owner |
|-------------------|------|-------|
| API Gateway       | 8080 | Dev 1 |
| Auth Service      | 8081 | Dev 1 |
| Inventory Service | 8082 | Dev 2 |
| Order Service     | 8083 | Dev 3 |
| PostgreSQL        | 5432 | one server, databases: auth_db, inventory_db, quick_commerce_db |

Flutter talks only to the gateway: `http://10.0.2.2:8080/api/v1` (Android emulator),
`http://localhost:8080/api/v1` (iOS simulator / web), `http://<laptop-ip>:8080/api/v1` (real phone).

## Admin login

| What | URL |
|---|---|
| Admin web page (login, stores, managers, riders) | http://localhost:8080/admin |
| Admin login API | `POST http://localhost:8080/api/v1/auth/login` |

First admin (created automatically): `admin@darkstore.com` / `Admin@123`. Change it after the first login in a real deployment.

The web page is a single file: `api-gateway/src/main/resources/static/admin/login.html`.

## Run

See the repository-root [Run locally](../README.md#run-locally) section for prerequisites, PostgreSQL database setup, the required shared environment values, and the exact command to launch each application in its own terminal. Start Auth, Inventory, and Cart-Order before the Gateway.

## Test with Postman

1. From the repository root, import `postman/DarkStore-All-Services.postman_collection.json` and `postman/DarkStore-Local.postman_environment.json`.
2. The local environment defaults `adminPassword` to `Admin@123`; change it if Auth uses another `ADMIN_PASSWORD`. Set `inventoryInternalToken` to the same value configured in Inventory and Order Service.
3. Use Postman's Collection Runner to run the full collection in order. To run only Catalog CRUD, run that folder from its first request, `Login admin for catalog CRUD`; its later requests depend on that token and IDs created by earlier requests.
4. The run covers Auth/profile/address/store/staff operations, Inventory category/product CRUD and stock operations, Cart operations, Order checkout/status transitions, rider fulfillment, payment failure/refund, and Order-to-Inventory reservation lifecycle. It includes delete operations only where the API exposes them.

## How requests flow

1. Flutter calls the gateway.
2. Routes marked `JwtAuth` need a valid token. The gateway checks it, removes any `X-User-*` headers sent by the client, and adds
   `X-User-Id`, `X-User-Role` and `X-Store-Id` (managers and riders) to the request.
3. Auth Service, Inventory, and Order Service read those headers and enforce their role rules. For rider requests, the gateway also supplies `X-Rider-Id` from a `RIDER` token.
4. Order Service calls Inventory's internal product validation and stock reservation APIs with `X-Internal-Service-Token`; order cancellation releases reservations, and completed delivery confirms them.

Gateway routes:

| Path prefix | Goes to | Token needed |
|---|---|---|
| /api/v1/auth/** | 8081 Auth | no |
| /api/v1/users, /stores, /admin | 8081 Auth | yes |
| /api/v1/products, /categories, /inventory | 8082 Inventory | yes |
| /api/v1/internal/products/validate, /api/v1/internal/inventory/** | 8082 Inventory | yes (MANAGER or ADMIN) |
| /api/v1/cart, /checkout, /orders, /payments, /manager, /rider | 8083 Order | yes |

The inventory route strips `/api/v1` before forwarding because its controllers use `/products`, `/categories`, and `/inventory`. Auth Service receives its `/api/v1/...` paths unchanged.

Important: keep service ports 8081 to 8083 private; only the gateway (8080) should be public. Auth, Inventory, and Order Service trust forwarded identity headers from the gateway; Inventory additionally requires the internal service token for Order Service calls. Do not expose service ports to clients.

## Auth endpoints

| Method | Endpoint | Who | Notes |
|---|---|---|---|
| POST | /auth/register | public | creates a CUSTOMER, returns the user (201) |
| POST | /auth/login | public | returns accessToken, refreshToken, expiresIn, user |
| POST | /auth/refresh | public | body `{refreshToken}`, returns a new pair |
| POST | /auth/logout | public | body `{refreshToken}`, 204 |
| GET, PUT | /users/me | logged in | profile |
| GET, POST | /users/me/addresses | CUSTOMER | |
| PUT, DELETE | /users/me/addresses/{id} | CUSTOMER | |
| GET | /stores, /stores/{id} | logged in | |
| POST | /stores | ADMIN | |
| PUT | /stores/{id} | ADMIN | |
| POST | /admin/users | ADMIN | creates MANAGER or RIDER (needs storeId) |
| GET | /admin/users?role= | ADMIN | list |
| PATCH | /admin/users/{id}/status | ADMIN | ACTIVE or DISABLED |

Error body: `{ "status": 401, "code": "TOKEN_EXPIRED", "message": "..." }`
Codes: INVALID_CREDENTIALS, TOKEN_EXPIRED, TOKEN_INVALID, ACCESS_DENIED, ACCOUNT_DISABLED,
NOT_FOUND, EMAIL_ALREADY_EXISTS, STORE_CODE_EXISTS, VALIDATION_ERROR (and INTERNAL_ERROR for unexpected 500s).

Access token: JWT, 15 minutes, contains userId, role and storeId.
Refresh token: random string, 7 days, stored hashed, works once.

## Service ownership and integration

- Auth owns users, roles, stores, and JWT issuance.
- Inventory owns the catalog, per-store stock, and stock reservations.
- Order owns carts, orders, and payments. It obtains product names and prices from Inventory rather than trusting cart values.
- Client requests go through the Gateway. The Gateway validates JWTs and forwards identity headers; keep the Auth, Inventory, and Order ports private.
- Order calls Inventory directly for validation, reservation, release, and delivery confirmation. Configure the same strong `INVENTORY_INTERNAL_TOKEN` in both services; do not send it through the public Gateway.
- Store IDs are UUIDs owned by Auth and referenced by Inventory and Order. Use the Auth store ID when creating Inventory stock so all three services refer to the same store.
- Each service owns its database (`auth_db`, `inventory_db`, or `quick_commerce_db`); services communicate over HTTP, not by sharing databases.

## For Dev 4 (Flutter)

1. `POST /auth/login`, then save `accessToken` and `refreshToken` in `flutter_secure_storage`.
2. Use `user.role` to open the Customer, Manager, Rider or Admin screens.
3. Send `Authorization: Bearer <accessToken>` on every call except register, login, refresh and logout.
4. If a call returns 401 with `code == TOKEN_EXPIRED`, call `POST /auth/refresh` once, save the new tokens,
   and repeat the call. If refresh fails, or the code is `TOKEN_INVALID` or `ACCOUNT_DISABLED`, clear storage and show login.
5. Logout: `POST /auth/logout` with the refresh token, then clear storage.

Android emulator on plain http needs `android:usesCleartextTraffic="true"` in `AndroidManifest.xml`.

## Troubleshooting

- `password authentication failed`: wrong `DB_PASSWORD` / password in `auth-service/application.yml`.
- `database "auth_db" does not exist`: run `CREATE DATABASE auth_db;` once.
- 401 `TOKEN_INVALID` on everything: `JWT_SECRET` differs between gateway and auth-service.
- 503 or "Connection refused" from the gateway: the target service is not running or `INVENTORY_SERVICE_URL` points to the wrong host/port.
- Port already in use: stop the old process or change `server.port`.
