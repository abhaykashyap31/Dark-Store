# Inventory Service API

This document describes the Inventory Spring Boot service routes and request/response bodies. The importable Postman collection is [Inventory.postman_collection.json](./postman/Inventory.postman_collection.json).

## Run locally

```bash
cd Inventory
mvn spring-boot:run
```

By default, the service listens on `http://localhost:8082` and uses an in-memory H2 database. To use PostgreSQL, set `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, and `SPRING_DATASOURCE_PASSWORD`.

All examples use JSON. Routes under `/internal` are intended for trusted service-to-service traffic; the service itself does not authenticate requests.

## Catalog

### Category CRUD

| Method | Route | Success |
| --- | --- | --- |
| `GET` | `/categories` | `200`, category array |
| `POST` | `/categories` | `201`, created category |
| `GET` | `/categories/{id}` | `200`, category |
| `PUT` | `/categories/{id}` | `200`, updated category |
| `DELETE` | `/categories/{id}` | `204`, no body |

`POST` and `PUT` request:

```json
{
  "name": "Pantry",
  "description": "Shelf-stable groceries",
  "parentId": null,
  "active": true
}
```

`slug` is generated from `name`. Category names and generated slugs must be unique. A category cannot be deleted while products or child categories reference it.

Category response:

```json
{
  "id": "7eb54e2b-6e39-49c0-b1a5-928aef4b13be",
  "parentId": null,
  "name": "Pantry",
  "slug": "pantry",
  "description": "Shelf-stable groceries",
  "active": true,
  "createdAt": "2026-11-21T05:30:00Z",
  "updatedAt": "2026-11-21T05:30:00Z"
}
```

### Product CRUD

| Method | Route | Success |
| --- | --- | --- |
| `GET` | `/products` | `200`, product array |
| `POST` | `/products` | `201`, created product |
| `GET` | `/products/{id}` | `200`, product |
| `PUT` | `/products/{id}` | `200`, updated product |
| `DELETE` | `/products/{id}` | `204`, no body |

`POST` and `PUT` request:

```json
{
  "name": "Long Grain Rice",
  "description": "Five kilogram bag",
  "sku": "RICE-5KG",
  "categoryId": "7eb54e2b-6e39-49c0-b1a5-928aef4b13be",
  "imageUrl": "https://example.test/rice.png",
  "basePrice": 12.50,
  "active": true
}
```

`sku` and `name` are required; SKU is unique. `categoryId` is optional, but when supplied it must identify an existing category. `basePrice` is optional and defaults to `0`; it cannot be negative. A product with stock, reservation, or movement history cannot be hard-deleted.

Product response:

```json
{
  "id": "19b7c414-44ac-4ce0-89c7-a1ed95062f1d",
  "name": "Long Grain Rice",
  "description": "Five kilogram bag",
  "sku": "RICE-5KG",
  "categoryId": "7eb54e2b-6e39-49c0-b1a5-928aef4b13be",
  "imageUrl": "https://example.test/rice.png",
  "basePrice": 12.50,
  "active": true,
  "createdAt": "2026-11-21T05:30:00Z",
  "updatedAt": "2026-11-21T05:30:00Z"
}
```

## Store inventory

| Method | Route | Success |
| --- | --- | --- |
| `GET` | `/inventory?storeId={uuid}` | `200`, stock rows for the store |
| `GET` | `/inventory` | `200`, all stock rows |
| `PUT` | `/inventory` | `200`, created or updated stock row |
| `GET` | `/inventory/{storeId}/{productId}` | `200`, stock row |
| `POST` | `/inventory/adjust` | `200`, updated stock row |
| `GET` | `/inventory/low-stock?storeId={uuid}` | `200`, low-stock rows; optional store filter |
| `GET` | `/inventory/movements?storeId={uuid}&productId={uuid}` | `200`, movement array, newest first |

Stock upsert request:

```json
{
  "storeId": "a9bfe29d-7c7d-412b-99d5-4db04cb6a6af",
  "productId": "19b7c414-44ac-4ce0-89c7-a1ed95062f1d",
  "price": 4.50,
  "onHand": 10,
  "lowStockThreshold": 2
}
```

Stock adjustment request:

```json
{
  "storeId": "a9bfe29d-7c7d-412b-99d5-4db04cb6a6af",
  "productId": "19b7c414-44ac-4ce0-89c7-a1ed95062f1d",
  "quantityChange": -2,
  "reason": "DAMAGED",
  "referenceId": null
}
```

The adjustment must be non-zero and cannot reduce on-hand stock below reserved stock. Price, on-hand quantity, and low-stock threshold cannot be negative. A stock row is upserted by the `(storeId, productId)` pair; it is not deleted through the API because movements and reservations form an audit trail.

Stock response:

```json
{
  "id": "1cd706fe-df2d-4c28-9c31-617512345678",
  "storeId": "a9bfe29d-7c7d-412b-99d5-4db04cb6a6af",
  "productId": "19b7c414-44ac-4ce0-89c7-a1ed95062f1d",
  "onHand": 10,
  "reserved": 0,
  "available": 10,
  "lowStockThreshold": 2,
  "price": 4.50,
  "version": 0,
  "updatedAt": "2026-11-21T05:30:00Z"
}
```

Movement response items include `id`, `storeInventoryId`, `storeId`, `productId`, `quantityChange`, `quantityDelta`, `balanceAfter`, `type`, `referenceType`, `reason`, `referenceId`, `createdBy`, and `createdAt`.

## Reservations and validation

The public and internal reservation routes have the same behavior. The internal routes are called by other services; use the public `/inventory/...` aliases for API gateway/client integrations.

| Method | Route | Success |
| --- | --- | --- |
| `POST` | `/inventory/reserve` | `201`, reservation result |
| `POST` | `/inventory/release` | `200`, released reservation result |
| `POST` | `/inventory/confirm` | `200`, confirmed reservation result |
| `POST` | `/internal/products/validate` | `200`, availability and store price |
| `POST` | `/internal/inventory/reserve` | `201`, reservation result |
| `POST` | `/internal/inventory/release` | `200`, released reservation result |
| `POST` | `/internal/inventory/confirm` | `200`, confirmed reservation result |

Reserve request:

```json
{
  "orderId": "20b7c414-44ac-4ce0-89c7-a1ed95062f1d",
  "storeId": "a9bfe29d-7c7d-412b-99d5-4db04cb6a6af",
  "items": [
    { "productId": "19b7c414-44ac-4ce0-89c7-a1ed95062f1d", "quantity": 2 }
  ]
}
```

Release and confirm request:

```json
{
  "orderId": "20b7c414-44ac-4ce0-89c7-a1ed95062f1d"
}
```

Reserve response:

```json
{
  "orderId": "20b7c414-44ac-4ce0-89c7-a1ed95062f1d",
  "status": "CONFIRMED",
  "items": [
    {
      "productId": "19b7c414-44ac-4ce0-89c7-a1ed95062f1d",
      "quantity": 2,
      "status": "RESERVED",
      "available": 8
    }
  ]
}
```

The response `status` is `FAILED` if any requested quantity cannot be reserved; the `items` array lists the failing item(s) and available stock. Reservation item quantities must be positive and the `items` array cannot be empty. Repeating an identical reservation request is idempotent. Release restores availability; confirm consumes reserved and on-hand stock. Released reservations cannot be confirmed, and confirmed reservations cannot be released.

Validation request:

```json
{
  "storeId": "a9bfe29d-7c7d-412b-99d5-4db04cb6a6af",
  "productIds": ["19b7c414-44ac-4ce0-89c7-a1ed95062f1d"]
}
```

Validation response:

```json
{
  "storeId": "a9bfe29d-7c7d-412b-99d5-4db04cb6a6af",
  "items": [
    {
      "productId": "19b7c414-44ac-4ce0-89c7-a1ed95062f1d",
      "name": "Long Grain Rice",
      "available": 10,
      "price": 4.50
    }
  ]
}
```

## Errors

| Status | Meaning | Example body |
| --- | --- | --- |
| `400` | Invalid field or operation | `{"error":"VALIDATION_ERROR","message":"One or more fields are invalid"}` |
| `404` | Category, product, or store stock not found | `{"error":"NOT_FOUND","message":"Product not found: ..."}` |
| `409` | Insufficient stock or resource cannot be deleted because it is referenced | `{"error":"CONFLICT","message":"..."}` |

## Postman collection

Import [Inventory.postman_collection.json](./postman/Inventory.postman_collection.json) into Postman. Run the entire collection in sequence; it generates fresh IDs, exercises catalog CRUD and inventory/reservation flows, and stores generated IDs in collection variables. Set `baseUrl` to the service URL if it is not `http://localhost:8082`. 

The inventory fixture is intentionally left in place because stock movements/reservations are audit history; use a disposable database when running repeated checks.
