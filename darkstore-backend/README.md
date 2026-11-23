# Dark Store Backend: API Gateway + Auth Service

Spring Boot 3.3, Java 17+, PostgreSQL, Maven.

## Ports

| Component         | Port | Owner |
|-------------------|------|-------|
| API Gateway       | 8080 | Dev 1 |
| Auth Service      | 8081 | Dev 1 |
| Inventory Service | 8082 | Dev 2 |
| Order Service     | 8083 | Dev 3 |
| PostgreSQL        | 5432 | one server, databases: auth_db, inventory_db, orders_db |

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

1. In PostgreSQL create the database once: `CREATE DATABASE auth_db;`
2. Put your PostgreSQL password in `auth-service/src/main/resources/application.yml` (or env `DB_PASSWORD`). The user defaults to `postgres` (env `DB_USERNAME`).
3. Start the services, auth first:

   ```
   cd auth-service && mvn spring-boot:run
   cd api-gateway  && mvn spring-boot:run      # in a second terminal
   ```

   or run `AuthServiceApplication`, then `GatewayApplication` from your IDE.
4. Open http://localhost:8080/admin or import the Postman collection (see below).

`JWT_SECRET` must be the same in both `application.yml` files (the defaults already match, at least 32 characters).

## Test with Postman

1. Import `postman/DarkStore-Gateway-Auth.postman_collection.json` (and optionally the environment file).
2. Open the collection, click **Run**, and run the whole collection in order.
   Each request has tests, and the folders are ordered so variables (tokens, ids) carry over.
3. Folders: Auth, Profile, Addresses, Stores, Admin (manager and rider accounts), Security and error checks, Logout.

## How requests flow

1. Flutter calls the gateway.
2. Routes marked `JwtAuth` need a valid token. The gateway checks it, removes any `X-User-*` headers sent by the client, and adds
   `X-User-Id`, `X-User-Role` and `X-Store-Id` (managers and riders) to the request.
3. The service reads those headers. Role rules are checked in the service with `@PreAuthorize`.

Gateway routes:

| Path prefix | Goes to | Token needed |
|---|---|---|
| /api/v1/auth/** | 8081 Auth | no |
| /api/v1/users, /stores, /admin | 8081 Auth | yes |
| /api/v1/products, /categories, /inventory | 8082 Inventory | yes |
| /api/v1/cart, /orders, /manager, /rider | 8083 Order | yes |

The gateway does not rewrite paths, so every service must use controllers under `/api/v1/...`.

Important: services trust the `X-User-*` headers, so ports 8081 to 8083 must not be reachable from outside. Only the gateway (8080) should be public.

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

## For Dev 2 and Dev 3

Run on your port, put controllers under `/api/v1/...`, and never read the JWT.
Copy these files from `auth-service` into your service and change the package name:

- `domain/Role.java`
- `security/AuthUser.java`
- `security/HeaderAuthFilter.java`
- `config/SecurityConfig.java` (remove the `/api/v1/auth/**` permitAll line and the PasswordEncoder bean)

Your service also needs `spring-boot-starter-security` in its pom.

Then in controllers:

```java
@PreAuthorize("hasRole('MANAGER')")
@GetMapping("/manager/orders")
public List<OrderResponse> storeOrders(@AuthenticationPrincipal AuthUser user) {
    return orders.findByStore(user.storeId());    // take storeId from the token, never from the request
}

@PreAuthorize("hasRole('CUSTOMER')")
@GetMapping("/orders")
public List<OrderResponse> myOrders(@AuthenticationPrincipal AuthUser user) {
    return orders.findByUser(user.userId());      // take userId from the token, never from the request
}
```

Use your own database (`inventory_db`, `orders_db`) and `ddl-auto: update`.
The same `JWT_SECRET` is not needed in your services, only the gateway and auth use it.

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
- 503 or "Connection refused" from the gateway: the target service is not running (inventory and orders are not part of this project).
- Port already in use: stop the old process or change `server.port`.
