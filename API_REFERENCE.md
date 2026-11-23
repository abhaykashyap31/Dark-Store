# Dark Store API Reference — Cart, Orders, Payments and Fulfillment

**Service:** Cart and Order Service  
**Port:** 8082  
**Audience:** Flutter developers, API Gateway developers and other microservice developers.

All endpoints are intended to be accessed through the **API Gateway**. Direct service access is currently used for local development and testing.

---

## 1. Quick facts

| Topic | Value |
|---|---|
| Service name | Cart and Order Service |
| Local service URL | `http://localhost:8082` |
| Base URL (API Gateway) | `http://localhost:8080/api/v1` |
| Format | JSON in, JSON out |
| Content-Type | `application/json` |
| Database | PostgreSQL |
| Database name | `quick_commerce_db` |
| Service port | `8082` |
| IDs | UUID |
| Authentication | JWT integration pending |
| Payment | Mock payment and COD |

### Temporary testing headers

The following headers are currently used for local testing:

| Header | Purpose |
|---|---|
| `X-USER-ID` | Identifies the customer |
| `X-STORE-ID` | Identifies the manager's or rider's store |
| `X-RIDER-ID` | Identifies the rider |

These are temporary testing headers. They will be replaced by authenticated JWT claims during integration.

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

`X-USER-ID: <user-uuid>`

**Response:** Cart details and cart items.

### POST `/cart/items`

Adds a product to the active cart.

**Header**

`X-USER-ID: <user-uuid>`

**Request body**

```json
{
  "productId": "33333333-3333-3333-3333-333333333333",
  "productName": "Amul Milk",
  "quantity": 2,
  "unitPrice": 30.00
}
```

If the product already exists in the cart, its quantity is increased.

### PUT `/cart/items/{productId}?quantity=3`

Updates the quantity of an existing cart item.

**Header**

`X-USER-ID: <user-uuid>`

### DELETE `/cart/items/{productId}`

Removes a product from the active cart.

**Header**

`X-USER-ID: <user-uuid>`

---

## 5. Checkout API

### POST `/checkout`

Converts the active cart into an order.

**Header**

`X-USER-ID: <user-uuid>`

No request body is required.

**Processing flow**

1. Retrieve the customer's active cart.
2. Validate that the cart contains items.
3. Calculate the subtotal.
4. Calculate the delivery fee.
5. Create an order with status `PLACED`.
6. Copy cart items into order items.
7. Create an order status history entry.
8. Mark the cart as `CHECKED_OUT`.

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

`X-USER-ID: <user-uuid>`

Returns the customer's orders, newest first.

### GET `/orders/{orderId}`

Retrieves a particular order.

**Header**

`X-USER-ID: <user-uuid>`

The service verifies that the order belongs to the requesting customer.

### GET `/orders/{orderId}/history`

Retrieves the status history of an order.

**Header**

`X-USER-ID: <user-uuid>`

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

`X-USER-ID: <user-uuid>`

Cancellation is currently allowed only when the order is `PLACED` or `CONFIRMED`.

---

## 7. Manager APIs

Manager endpoints are used for processing orders belonging to the manager's store.

### GET `/manager/orders?status=PLACED`

Retrieves orders belonging to the manager's store filtered by status.

**Header**

`X-STORE-ID: <store-uuid>`

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

`X-STORE-ID: <store-uuid>`

### PATCH `/rider/orders/{orderId}/accept`

Accepts an available order.

**Headers**

`X-RIDER-ID: <rider-uuid>`

`X-STORE-ID: <store-uuid>`

Creates a rider assignment with status `ASSIGNED`.

### PATCH `/rider/orders/{orderId}/pickup`

Marks an assigned order as picked up.

**Header**

`X-RIDER-ID: <rider-uuid>`

Updates:

- Assignment status to `PICKED_UP`
- Pickup timestamp
- Order status to `OUT_FOR_DELIVERY`
- Order status history

### PATCH `/rider/orders/{orderId}/deliver`

Marks an order as delivered.

**Header**

`X-RIDER-ID: <rider-uuid>`

Updates:

- Assignment status to `DELIVERED`
- Delivery timestamp
- Order status to `DELIVERED`
- Order status history

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

The service has a global exception handler.

| HTTP status | Meaning |
|---|---|
| 400 | Bad request or invalid input |
| 404 | Resource not found |
| 405 | HTTP method not supported |
| 409 | Database constraint conflict |
| 500 | Unexpected server error |

The current exception mapping is still being tested and refined.

401 and 403 authentication and authorization responses will be integrated with Spring Security and JWT.

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

server.port=8082

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
./mvnw clean compile -DskipTests
```

Run:

```bash
./mvnw spring-boot:run
```

On Windows PowerShell:

```powershell
.\mvnw.cmd spring-boot:run
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

### JWT integration pending

The authentication service defines these JWT claims:

- `userId`
- `role`
- `storeId`
- `sub`
- `iat`
- `exp`

The Cart and Order Service will use authenticated identity and role information instead of temporary testing headers after integration.

---

**Document status:** Initial API reference. Endpoint paths and request examples reflect the current implementation; response schemas and some error mappings should be verified against the running service before final integration.