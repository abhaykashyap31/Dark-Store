# Dark Store Backend: Auth, Inventory, Orders, and API Gateway

Auth, Inventory, and Gateway use Spring Boot 3.3.5; Cart and Order Service is a separate Spring Boot 4.2.0 project at the repository root. Auth and Gateway target Java 17; Inventory targets Java 21.

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

1. In PostgreSQL create these databases once: `auth_db`, `inventory_db`, and `quick_commerce_db`.
2. Set `DB_PASSWORD` for Auth and Cart/Order Service and `SPRING_DATASOURCE_PASSWORD` for Inventory Service. All usernames default to `postgres`.
3. Set the same `JWT_SECRET` for Auth Service and API Gateway. Set the same `INVENTORY_INTERNAL_TOKEN` for Inventory and Cart/Order Service; use a high-entropy value outside local development.
4. Start each application in its own terminal, with the three backends running before the gateway:

   ```
   bash mvnw -f darkstore-backend/auth-service/pom.xml spring-boot:run
   bash mvnw -f darkstore-backend/Inventory/pom.xml spring-boot:run
   bash mvnw spring-boot:run
   bash mvnw -f darkstore-backend/api-gateway/pom.xml spring-boot:run
   ```

   The order service calls Inventory directly using `INVENTORY_SERVICE_URL` (default `http://localhost:8082`) and the internal service token. The gateway routes client requests to Order Service on port `8083`.
5. Open http://localhost:8080/admin or import the Postman collection (see below).

`JWT_SECRET` must be the same in both `application.yml` files (the defaults already match, at least 32 characters).

## Test with Postman

1. Import `postman/DarkStore-Complete.postman_collection.json` and the `postman/DarkStore-Local.postman_environment.json` environment.
2. Set `adminPassword` and `inventoryInternalToken` in the environment. The internal token must match the value configured in both Inventory and Order Service.
3. Open the collection, click **Run**, and run the whole collection in order. Requests contain assertions and pass IDs/tokens between service workflows.
4. The run covers Auth/profile/address/store/staff operations, Inventory category/product/stock CRUD, Cart operations, Order checkout/status transitions, rider fulfillment, payment failure/refund, and Order-to-Inventory reservation lifecycle.

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
