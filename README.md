# Dark Store

Dark Store is a dark-grocery platform for browsing products, placing orders, managing inventory, and processing customer and manager order workflows. The application is organized as a Flutter client, an API gateway, and separate domain services.

## Product structure

### Client

- **Flutter App (Dev 4):** Customer and manager UI built around role-based experiences.
- **Customer features:** Browse products, manage profile and addresses, place orders, and track order history.
- **Manager features:** Manage catalog, inventory, orders, stores, and store staff.
- **Platform services:** Dio for HTTP communication, BLoC or Riverpod for state management, and secure storage for credentials.

### API and services

- **API Gateway (Dev 1):** Spring Cloud Gateway is the public entry point. It validates JWTs and routes requests to the services.
- **Auth and User Service (Dev 1):** Registration, login, token refresh and logout, role management, profiles and addresses, store data, and store-to-user mappings.
- **Catalog and Inventory Service (Dev 2):** Product and category management, store-specific pricing, stock reservations and releases, stock movements, and low-stock reporting.
- **Order and Fulfillment Service (Dev 3):** Cart and order placement, order status transitions, manager order handling, payment status, order history, and tracking.

All external requests enter through the API gateway. The gateway forwards user, catalog, inventory, and order routes to the corresponding service and propagates identity and correlation headers.

### Data ownership

Each service owns its PostgreSQL database and must not access another service's database directly:

| Service | Database | Main data |
| --- | --- | --- |
| Auth and User | `auth_db` | Users, roles, addresses, stores, and store staff |
| Catalog and Inventory | `inventory_db` | Products, categories, store inventory, stock movement and reservations |
| Order and Fulfillment | `quick_commerce_db` | Carts, orders, order items, status history and payments |

## Service interaction rules

- The Flutter app communicates with services only through the API gateway.
- The gateway validates JWTs and forwards `X-User-Id`, `X-User-Role`, `X-Store-Id`, and `X-Correlation-Id`.
- Catalog, inventory, and order records use cross-service foreign keys only as stable references; services do not share databases.
- Inventory changes are part of the order lifecycle:
  - `CREATED` reserves stock.
  - `CONFIRMED` keeps the reservation.
  - `OUT_FOR_DELIVERY` confirms inventory use.
  - `CANCELLED` releases reserved stock.
- Reservation and release operations are idempotent and follow internal service APIs.

## Order lifecycle

The order lifecycle is:

`CREATED -> CONFIRMED -> PICKING -> PACKED -> OUT_FOR_DELIVERY -> DELIVERED`

An order can move to `CANCELLED` from `CONFIRMED` or `PICKING`. If stock reservation fails, the order becomes `FAILED`.

Invalid status transitions are rejected as `INVALID_STATUS_TRANSITION`.

## Run locally

### Prerequisites

- Java 17 (all backend services target Java 17)
- Maven 3.9+ (the repository Maven Wrapper is included)
- PostgreSQL running on `localhost:5432`
- Postman Desktop for the API workflow

The root `pom.xml` is the Maven aggregator for all four independent applications. Run this from the repository root to compile and test every service:

```powershell
.\mvnw.cmd test
```

Start PostgreSQL first and create `auth_db`, `inventory_db`, and `quick_commerce_db` if they do not already exist. In PowerShell, connect with:

```powershell
psql -U postgres -h localhost -p 5432
```

Then create any missing databases in the `psql` prompt:

```sql
CREATE DATABASE auth_db;
CREATE DATABASE inventory_db;
CREATE DATABASE quick_commerce_db;
\q
```

Use your local PostgreSQL password in the service terminals. Do not commit credentials or tokens.

Open four PowerShell terminals at the repository root. Set the required environment variables and start one service in each terminal; leave them open while testing.

**Terminal 1 — Auth Service (port 8081):**

```powershell
$env:DB_PASSWORD = '<your-local-postgres-password>'
$env:JWT_SECRET = '<one-shared-local-jwt-secret>'
$env:ADMIN_PASSWORD = '<your-local-admin-password>'
.\mvnw.cmd -f darkstore-backend\auth-service\pom.xml spring-boot:run
```

**Terminal 2 — Catalog and Inventory Service (port 8082):**

```powershell
$env:SPRING_DATASOURCE_PASSWORD = '<your-local-postgres-password>'
$env:INVENTORY_INTERNAL_TOKEN = '<one-shared-local-inventory-token>'
.\mvnw.cmd -f darkstore-backend\Inventory\pom.xml spring-boot:run
```

**Terminal 3 — Cart-Order Service (port 8083):**

```powershell
$env:DB_PASSWORD = '<your-local-postgres-password>'
$env:INVENTORY_INTERNAL_TOKEN = '<same-inventory-token-as-terminal-2>'
.\mvnw.cmd -f darkstore-backend\order-service\pom.xml spring-boot:run
```

**Terminal 4 — API Gateway (port 8080):**

```powershell
$env:JWT_SECRET = '<same-jwt-secret-as-terminal-1>'
.\mvnw.cmd -f darkstore-backend\api-gateway\pom.xml spring-boot:run
```

Run each command from the repository root and set the variables in that terminal as shown; this avoids depending on the process working directory to find `.env`. Wait for each startup message. Client/Postman requests go through the Gateway at `http://localhost:8080`; the JWT secret and Inventory internal token must match across their respective services.

Check listeners in PowerShell:

```powershell
Get-NetTCPConnection -State Listen |
    Where-Object { $_.LocalPort -in 5432, 8080, 8081, 8082, 8083 } |
    Sort-Object LocalPort |
    Select-Object LocalAddress, LocalPort, OwningProcess
```

Check Inventory health with:

```powershell
Invoke-RestMethod http://localhost:8082/actuator/health
```

## Product diagrams

### System architecture

![Dark Store system architecture](Arc.drawio.png)

This diagram shows the Flutter client, API gateway, three domain services, and each service's separate PostgreSQL database.

### Order status flow

![Dark Store order status flow](Order-flow.drawio.png)

This diagram shows normal fulfillment, cancellation paths, reservation failure, and the inventory effects associated with each transition.

### Order placement sequence

![Dark Store order placement sequence](Order-placement-flow.drawio.png)

This sequence starts when the Flutter app sends `POST /orders` through the gateway. The order service calculates prices, validates inventory, saves the order, reserves stock, and returns the final status and timeline. The app refreshes order status every 10-15 seconds; a manager or inventory confirmation action advances or confirms the relevant workflow.

## Postman: all services

Import [the all-services collection](./postman/DarkStore-All-Services.postman_collection.json) and [the local environment](./postman/DarkStore-Local.postman_environment.json). Start PostgreSQL and the four applications using the [local run instructions](#run-locally). Set `adminPassword` to the password configured for Auth and `inventoryInternalToken` to the same value configured in Inventory and Cart-Order.

Run the full collection in order with Postman's Collection Runner, or run the `9. Catalog CRUD` folder from its first request (`Login admin for catalog CRUD`). Do not send dependent catalog requests individually: they require the login and IDs created earlier in the folder. The collection covers the CRUD actions exposed by Auth, catalog, inventory, and cart APIs, plus checkout, payment, cancellation, fulfillment, and inventory reservation interactions. It creates persistent local test data; use a development database, not production. The API does not expose delete operations for users, stores, orders, or payments, so the collection does not invent them.