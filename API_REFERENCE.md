# Dark Store API Reference — Authentication, Cart, Orders, Payments and Fulfillment

**Audience:** Flutter developers, API Gateway developers and other microservice developers.

Client requests go through the **API Gateway**. Service ports are internal; direct service access is for local development and testing only.

## 1. Quick facts

| Topic | Value |
|---|---|
| Service name | Cart and Order Service |
| Local service URL | `http://localhost:8083` |
| Base URL (API Gateway) | `http://localhost:8080/api/v1` |
| Base URL (Android emulator) | `http://10.0.2.2:8080/api/v1` |
| Base URL (real phone) | `http://<laptop-ip>:8080/api/v1` (same Wi-Fi; allow port 8080 through the firewall) |
| API Gateway port | `8080` |
| Authentication Service port | `8081` |
| Format | JSON in, JSON out |
| Content-Type | `application/json` |
| Database | PostgreSQL |
| Database name | `quick_commerce_db` |
| Service port | `8083` |
| IDs | UUID |
| Authentication | Gateway validates JWTs and forwards identity headers |
| Auth header | `Authorization: Bearer <accessToken>` |
| Roles | `CUSTOMER`, `MANAGER`, `RIDER`, `ADMIN` |
| Access token life | 15 minutes |
| Refresh token life | 7 days, single-use |
| Payment | Mock payment and COD |
| Inventory Service port | `8082` |

### Gateway identity headers

For protected service routes, the gateway validates the bearer token and supplies these internal headers:

| Header | Purpose |
|---|---|
| `X-User-Id` | Authenticated user's UUID |
| `X-User-Role` | Authenticated user's role |
| `X-Store-Id` | Manager's or rider's store UUID |
| `X-Rider-Id` | Authenticated rider's UUID |

---

## 2. Service responsibilities

This microservice handles:

- Shopping cart management
- Adding, updating and removing cart items
- Checkout and order creation
- Customer order history and tracking
- Order status management
- Order cancellation
- Mock payment processing
- Cash on Delivery (COD)
- Manager order processing
- Rider assignment and delivery

Other services manage authentication, users, stores, products and inventory.

---

## 3. Order lifecycle

An order follows this lifecycle:

`PLACED → CONFIRMED → PREPARING → READY_FOR_PICKUP → OUT_FOR_DELIVERY → DELIVERED`

An eligible order can also be cancelled.

| Status | Description | Responsible party |
|---|---|---|
| PLACED | Customer places an order | Customer |
| CONFIRMED | Manager confirms the order | Manager |
| PREPARING | Store prepares the order | Manager |
| READY_FOR_PICKUP | Order is ready for rider pickup | Manager |
| OUT_FOR_DELIVERY | Rider picks up the order | Rider |
| DELIVERED | Order is delivered | Rider |
| CANCELLED | Order is cancelled | Customer |

---

## 4. Cart APIs

### POST `/cart`

Creates an active cart for a customer.

**Request body**

```json
{
  "userId": "11111111-1111-1111-1111-111111111111",
  "storeId": "22222222-2222-2222-2222-222222222222"
}
```

**Response:** Created or existing active cart.

The service returns the existing active cart if the customer already has one for the same store.

### GET `/cart`

Retrieves the customer's active cart.

**Header**

`X-User-Id: <user-uuid>`

**Response:** Cart details and cart items.

### POST `/cart/items`

Adds a product to the active cart.

**Header**

`X-User-Id: <user-uuid>`

**Request body**

```json
{
  "productId": "33333333-3333-3333-3333-333333333333",
  "productName": "Amul Milk",
  "quantity": 2,
  "unitPrice": 30.00
}
```

Inventory validates that the product is active and available at the cart's store. The product name and unit price are taken from Inventory; request values are not trusted. If the product already exists in the cart, its quantity is increased only if the combined quantity is available.

### PUT `/cart/items/{productId}?quantity=3`

Updates the quantity of an existing cart item.

**Header**

`X-User-Id: <user-uuid>`

### DELETE `/cart/items/{productId}`

Removes a product from the active cart.

**Header**

`X-User-Id: <user-uuid>`

---

## 5. Checkout API

### POST `/checkout`

Converts the active cart into an order.

**Header**

`X-User-Id: <user-uuid>`

No request body is required.

**Processing flow**

1. Retrieve the customer's active cart.
2. Validate that the cart contains items and re-check current inventory availability and prices.
3. Calculate the subtotal from Inventory's current store prices.
4. Calculate the delivery fee.
5. Create an order with status `PLACED`.
6. Copy cart items into order items.
7. Create an order status history entry.
8. Mark the cart as `CHECKED_OUT`.
9. Reserve the order quantities in Inventory. If stock cannot be reserved, checkout is rolled back.

**Example response**

```json
{
  "orderId": "07059be8-9b89-45f6-9cb0-e44d2eaadb9b",
  "status": "PLACED",
  "subtotal": 60.00,
  "deliveryFee": 0.00,
  "totalAmount": 60.00
}
```

---

## 6. Customer Order APIs

### GET `/orders`

Retrieves all orders belonging to the customer.

**Header**

`X-User-Id: <user-uuid>`

Returns the customer's orders, newest first.

### GET `/orders/{orderId}`

Retrieves a particular order.

**Header**

`X-User-Id: <user-uuid>`

The service verifies that the order belongs to the requesting customer.

### GET `/orders/{orderId}/history`

Retrieves the status history of an order.

**Header**

`X-User-Id: <user-uuid>`

Example history:

```json
[
  {
    "status": "PLACED",
    "changedBy": "11111111-1111-1111-1111-111111111111",
    "remarks": "Order placed successfully"
  },
  {
    "status": "CONFIRMED",
    "changedBy": "44444444-4444-4444-4444-444444444444",
    "remarks": "Order confirmed"
  }
]
```

### PATCH `/orders/{orderId}/cancel`

Cancels an eligible order.

**Header**

`X-User-Id: <user-uuid>`

Cancellation is currently allowed only when the order is `PLACED` or `CONFIRMED`.
Cancelling an order releases its stock reservation.

---

## 7. Manager APIs

Manager endpoints are used for processing orders belonging to the manager's store.

### GET `/manager/orders?status=PLACED`

Retrieves orders belonging to the manager's store filtered by status.

**Header**

`X-Store-Id: <store-uuid>`

Supported statuses:

- PLACED
- CONFIRMED
- PREPARING
- READY_FOR_PICKUP
- OUT_FOR_DELIVERY
- DELIVERED
- CANCELLED

### PATCH `/manager/orders/{orderId}/status`

Updates the order status.

**Request body**

```json
{
  "status": "CONFIRMED",
  "changedBy": "44444444-4444-4444-4444-444444444444"
}
```

The manager processing flow is:

`PLACED → CONFIRMED → PREPARING → READY_FOR_PICKUP`

Every status update creates an entry in `order_status_history`.

---

## 8. Rider APIs

Rider endpoints manage order pickup and delivery.

### GET `/rider/orders/available`

Retrieves orders that are ready for pickup and have not already been assigned.

**Header**

`X-Store-Id: <store-uuid>`

### PATCH `/rider/orders/{orderId}/accept`

Accepts an available order.

**Headers**

`X-Rider-Id: <rider-uuid>`

`X-Store-Id: <store-uuid>`

Creates a rider assignment with status `ASSIGNED`.

### PATCH `/rider/orders/{orderId}/pickup`

Marks an assigned order as picked up.

**Header**

`X-Rider-Id: <rider-uuid>`

Updates:

- Assignment status to `PICKED_UP`
- Pickup timestamp
- Order status to `OUT_FOR_DELIVERY`
- Order status history

### PATCH `/rider/orders/{orderId}/deliver`

Marks an order as delivered.

**Header**

`X-Rider-Id: <rider-uuid>`

Updates:

- Assignment status to `DELIVERED`
- Delivery timestamp
- Order status to `DELIVERED`
- Order status history

Successful delivery confirms the Inventory reservation and consumes the reserved stock.

---

## 9. Payment APIs

This service currently supports mock payment processing and Cash on Delivery.

No actual payment gateway or real money transfer is integrated.

### POST `/orders/{orderId}/payments`

Creates a payment record for an order.

**Request body**

```json
{
  "paymentMethod": "UPI"
}
```

Supported payment methods:

- UPI
- CARD
- COD
- MOCK

### POST `/payments/{paymentId}/process?success=true`

Processes a mock payment.

Set `success=true` to simulate success or `success=false` to simulate failure.
An unsuccessful mock payment cancels the newly placed order and releases its stock reservation.

### GET `/orders/{orderId}/payments`

Retrieves payment records associated with an order.

### POST `/payments/{paymentId}/collect-cod`

Marks a COD payment as collected.

### Payment statuses

| Status | Description |
|---|---|
| PENDING | Payment awaiting processing |
| SUCCESS | Payment successful |
| FAILED | Payment failed |
| REFUNDED | Payment refunded |

---

## 10. Database tables

The service currently manages the following tables:

| Table | Purpose |
|---|---|
| `carts` | Customer shopping carts |
| `cart_items` | Products added to carts |
| `orders` | Main order information |
| `order_items` | Products belonging to orders |
| `order_status_history` | Order status audit history |
| `payments` | Payment records |
| `rider_assignments` | Rider and order assignment information |

### Main relationships

- One cart can contain multiple cart items.
- One order can contain multiple order items.
- One order can have multiple status history entries.
- An order can have a payment record.
- Each order currently has at most one rider assignment.

---

## 11. Error handling

The Cart and Order Service returns an error body containing `timestamp`, `status`, `error`, `message`, and `validationErrors`. For example:

```json
{
  "timestamp": "2025-01-15T10:30:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "validationErrors": {
    "quantity": "must be greater than or equal to 1"
  }
}
```

The service has a global exception handler.

| HTTP status | Meaning |
|---|---|
| 400 | Bad request or invalid input |
| 404 | Resource not found |
| 405 | HTTP method not supported |
| 409 | Database constraint conflict |
| 500 | Unexpected server error |

The API Gateway returns authentication errors as `{"status":401,"code":"TOKEN_INVALID","message":"..."}`. See the authentication error reference below for auth-specific codes and handling.

---

## 12. Project configuration

### Requirements

- Java 17
- Spring Boot
- Maven
- PostgreSQL
- Postman

### Environment configuration

The service uses environment variables for database credentials.

Example `.env` file:

```properties
DB_PASSWORD=your_database_password
```

The `.env` file must not be committed to GitHub.

### application.properties

```properties
spring.application.name=cart-order-service

server.port=8083

spring.datasource.url=jdbc:postgresql://localhost:5432/quick_commerce_db
spring.datasource.username=postgres
spring.datasource.password=${DB_PASSWORD}
spring.datasource.driver-class-name=org.postgresql.Driver

spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
spring.jpa.open-in-view=false
```

### Run locally

Compile:

```bash
bash mvnw clean compile -DskipTests
```

Run:

```bash
bash mvnw -f darkstore-backend/order-service/pom.xml spring-boot:run
```

On Windows PowerShell:

```powershell
.\mvnw.cmd -f darkstore-backend\order-service\pom.xml spring-boot:run
```

---

## 13. Integration notes

The service is intended to communicate with the following microservices:

| Microservice | Responsibility |
|---|---|
| Authentication Service | User identity, roles and JWT |
| Product Service | Product information |
| Inventory Service | Product availability and stock |
| Store Service | Store information |
| Cart and Order Service | Cart, checkout, orders, payments and fulfillment |

### JWT integration

The authentication service defines these JWT claims:

- `userId`
- `role`
- `storeId`
- `sub`
- `iat`
- `exp`

The API Gateway validates the access token and forwards the authenticated identity and role as internal headers to downstream services. Use the gateway for protected requests.

---

## 14. Authentication, Users, Stores, and Admin APIs

Public authentication endpoints do not require a bearer token: `/auth/register`, `/auth/login`, `/auth/refresh`, and `/auth/logout`. All other endpoints in this section require `Authorization: Bearer <accessToken>`.

### Authentication and gateway error format

Authentication and gateway errors use this body:

```json
{ "status": 401, "code": "TOKEN_EXPIRED", "message": "Access token expired" }
```

Always branch on `code`, never on `message` (messages can change and are for developers, not end users).

| HTTP | code | When | What the app should do |
|---|---|---|---|
| 400 | `VALIDATION_ERROR` | Missing or invalid field, bad enum value, malformed JSON | Show field errors. `message` lists them, e.g. `email must be a well-formed email address; password size must be between 8 and 72` |
| 401 | `INVALID_CREDENTIALS` | Wrong email or password (login) | Show "Email or password is wrong" |
| 401 | `TOKEN_EXPIRED` | Access token (or refresh token) expired | Call `/auth/refresh` once and retry. If this came from `/auth/refresh`, go to login |
| 401 | `TOKEN_INVALID` | No token, bad token, unknown or already-used refresh token | Clear storage, go to login |
| 403 | `ACCESS_DENIED` | Logged in but the role is not allowed | Show "not allowed". **Do not log out** |
| 403 | `ACCOUNT_DISABLED` | Admin disabled this account (login, refresh) | Clear storage, go to login, show "account disabled" |
| 404 | `NOT_FOUND` | Unknown store, address or user | Show not-found state |
| 409 | `EMAIL_ALREADY_EXISTS` | Register or create-user with an existing email | Show "email already registered" |
| 409 | `STORE_CODE_EXISTS` | Store code already used | Show "store code already used" |
| 500 | `INTERNAL_ERROR` | Unexpected server error | Show generic error, allow retry |

Network failures (server down, no internet) have **no body**. Handle them separately in the app.

### Authentication data shapes

#### User
```json
{ "id": "550e8400-e29b-41d4-a716-446655440000", "email": "asha@example.com", "fullName": "Asha Rao", "phone": "9876543210",
  "role": "CUSTOMER", "status": "ACTIVE", "storeId": null }
```
`storeId` is set only for `MANAGER` and `RIDER`. `status` is `ACTIVE` or `DISABLED`. `phone` can be `null`.

#### Auth response (login and refresh)
```json
{ "accessToken": "eyJhbGciOi...", "refreshToken": "kF3...random...",
  "expiresIn": 900, "user": { "...User..." } }
```

#### Address
```json
{ "id": "550e8400-e29b-41d4-a716-446655440001", "label": "Home", "line1": "12 Marine Drive",
  "line2": "Flat 4B", "city": "Mumbai", "state": "Maharashtra", "postalCode": "400020",
  "country": "India", "defaultAddress": true }
```

#### Store
```json
{ "id": "550e8400-e29b-41d4-a716-446655440002", "code": "DS-BOM-01", "name": "Andheri Dark Store",
  "line1": "Link Road, Andheri West", "city": "Mumbai", "state": "Maharashtra",
  "postalCode": "400053", "phone": "02212345678", "active": true }
```

#### Field limits (violations return `VALIDATION_ERROR`)

| Field | Rule |
|---|---|
| `fullName` | required, max 100 |
| `email` | required, valid email |
| `password` | required, 8 to 72 characters |
| `phone` | optional, max 20 |
| address `line1` / `city` / `postalCode` | required (`postalCode` max 20), `line1` max 200, `city` max 100 |
| address `label` | optional, max 50 |
| store `code` | required, max 20 (saved upper-case) |
| store `name` | required, max 100 |

### Authentication APIs

#### POST `/auth/register` (public)
Creates a **CUSTOMER**. It does not log in. Call `/auth/login` next.

```json
{ "fullName": "Asha Rao", "email": "asha@example.com", "password": "Secret@123", "phone": "9876543210" }
```
- `201` with a **User**
- `400 VALIDATION_ERROR`, `409 EMAIL_ALREADY_EXISTS`

#### POST `/auth/login` (public)
```json
{ "email": "asha@example.com", "password": "Secret@123" }
```
- `200` with an **Auth response**
- `401 INVALID_CREDENTIALS`, `403 ACCOUNT_DISABLED`, `400 VALIDATION_ERROR`

Use `user.role` to decide which screens to open.

#### POST `/auth/refresh` (public)
```json
{ "refreshToken": "kF3...random..." }
```
- `200` with an **Auth response** (new access token **and** new refresh token)
- `401 TOKEN_INVALID` (unknown or already used), `401 TOKEN_EXPIRED` (older than 7 days), `403 ACCOUNT_DISABLED`

The old refresh token stops working immediately. Save the new one before doing anything else.
If two requests refresh at the same time with the same token, the second one fails. The Flutter guide shows how to avoid that.

#### POST `/auth/logout` (public)
```json
{ "refreshToken": "kF3...random..." }
```
- `204`, no body. Unknown tokens are ignored (still `204`). Always clear local storage afterwards.

### Profile APIs (any logged-in role)

#### GET `/users/me`
- `200` with a **User**

#### PUT `/users/me`
```json
{ "fullName": "Asha R.", "phone": "9123456780" }
```
- `200` with the updated **User**
- `name` is required. Leaving out `phone` (or sending `null`) **clears** the phone number, so always send the current value.

### Address APIs (CUSTOMER only; other roles get `403 ACCESS_DENIED`)

#### GET `/users/me/addresses`
- `200` with a list of **Address**

#### POST `/users/me/addresses`
```json
{ "label": "Home", "line1": "12 Marine Drive", "line2": "Flat 4B", "city": "Mumbai",
  "state": "Maharashtra", "postalCode": "400020", "country": "India", "defaultAddress": true }
```
- `201` with the **Address**
- The first address is always the default. Sending `defaultAddress: true` makes this one the default and removes the flag from the others.

#### PUT `/users/me/addresses/{id}`
Same body as POST. Replaces all fields.
- `200` with the **Address**, `404 NOT_FOUND` if it is not the caller's address
- `defaultAddress: true` moves the default here. `false` or missing does not remove the default.

#### DELETE `/users/me/addresses/{id}`
- `204`, or `404 NOT_FOUND`
- Deleting the default address does not pick a new default automatically.

### Store APIs

#### GET `/stores` and GET `/stores/{id}` (any logged-in role)
- `200` with a list of **Store** / one **Store**. The list includes inactive stores, so filter on `active` in the app.
- `404 NOT_FOUND`

#### POST `/stores` (ADMIN)
```json
{ "code": "DS-BOM-01", "name": "Andheri Dark Store", "line1": "Link Road, Andheri West",
  "city": "Mumbai", "state": "Maharashtra", "postalCode": "400053",
  "phone": "02212345678", "active": true }
```
- `201` with the **Store**, `409 STORE_CODE_EXISTS`, `403 ACCESS_DENIED`

#### PUT `/stores/{id}` (ADMIN)
Same body. Replaces all fields (omitted optional fields become `null`; omitted `active` keeps the current value).
- `200`, `404`, `409 STORE_CODE_EXISTS`

### Admin APIs: manager and rider accounts (ADMIN only)

#### POST `/admin/users`
```json
{ "fullName": "Store Manager", "email": "mgr@darkstore.com", "password": "Manager@123",
  "phone": "9000000001", "role": "MANAGER", "storeId": "550e8400-e29b-41d4-a716-446655440002" }
```
- `role` must be `MANAGER` or `RIDER`. `storeId` is required and must exist.
- `201` with a **User**
- `400 VALIDATION_ERROR` (wrong role, missing storeId), `404 NOT_FOUND` (store), `409 EMAIL_ALREADY_EXISTS`

#### GET `/admin/users?role=`
`role` is optional (`CUSTOMER`, `MANAGER`, `RIDER`, `ADMIN`). No paging yet (returns everyone).
- `200` with a list of **User**, `400` for an unknown role value

#### PATCH `/admin/users/{id}/status`
```json
{ "status": "DISABLED" }
```
- `200` with the **User**. An admin cannot change their own status (`400 VALIDATION_ERROR`).
- A disabled user can still use a token they already have until it expires (max 15 minutes), but cannot log in or refresh.

### Role access summary

| Endpoint | CUSTOMER | MANAGER | RIDER | ADMIN |
|---|:-:|:-:|:-:|:-:|
| `/auth/*` | yes | yes | yes | yes |
| `GET, PUT /users/me` | yes | yes | yes | yes |
| `/users/me/addresses*` | yes | no | no | no |
| `GET /stores*` | yes | yes | yes | yes |
| `POST, PUT /stores*` | no | no | no | yes |
| `/admin/users*` | no | no | no | yes |

Routes owned by other services (all need a token): `/products`, `/categories`, `/inventory` (Inventory service) and `/cart`, `/checkout`, `/orders`, `/payments`, `/manager`, `/rider` (Cart and Order Service).

### Access token claims

JWT claims: `sub` and `userId` (user id), `role`, `storeId` (only for MANAGER and RIDER), `iat`, `exp`.
The app may decode it to read the role, but must never trust it for security. The server decides. Prefer `user.role` from the login response.

### curl examples

```bash
BASE=http://localhost:8080/api/v1

# login
curl -s -X POST $BASE/auth/login -H 'Content-Type: application/json' \
  -d '{"email":"admin@darkstore.com","password":"Admin@123"}'

# call a protected endpoint
curl -s $BASE/stores -H "Authorization: Bearer $ACCESS_TOKEN"

# refresh
curl -s -X POST $BASE/auth/refresh -H 'Content-Type: application/json' \
  -d "{\"refreshToken\":\"$REFRESH_TOKEN\"}"
```
