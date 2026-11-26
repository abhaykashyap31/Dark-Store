# Inventory API — Flutter integration

This guide documents the Catalog and Inventory Spring Boot microservice for the Flutter client.
The source service listens at `http://localhost:8082` by default. In deployed environments,
Flutter should call the API gateway, not this service directly; use the gateway's configured
inventory route prefix in place of the paths below. The gateway may require a bearer token even
though this service does not authenticate requests itself.

All endpoints accept and return JSON. Send `Content-Type: application/json` for requests with a
body and `Accept: application/json` for responses. IDs are UUID strings, timestamps are ISO-8601
UTC strings, and prices are JSON numbers (decimal currency values).

## Catalog

### Categories

| Method and path | Request | Success response |
| --- | --- | --- |
| `GET /categories` | None | `200`, `Category[]` |
| `POST /categories` | `CategoryRequest` | `201`, `Category` |
| `GET /categories/{id}` | None | `200`, `Category` |
| `PUT /categories/{id}` | `CategoryRequest` | `200`, `Category` |
| `DELETE /categories/{id}` | None | `204`, empty |

`CategoryRequest`:

```json
{
  "name": "Pantry",
  "description": "Shelf-stable groceries",
  "parentId": null,
  "active": true
}
```

`name` is required. `parentId` may be `null` or an existing category UUID. The service generates
`slug` from `name`; category names and slugs must be unique. Deleting a category referenced by
products or child categories returns `409`.

`Category`:

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

### Products

| Method and path | Request | Success response |
| --- | --- | --- |
| `GET /products` | None | `200`, `Product[]` |
| `POST /products` | `ProductRequest` | `201`, `Product` |
| `GET /products/{id}` | None | `200`, `Product` |
| `PUT /products/{id}` | `ProductRequest` | `200`, `Product` |
| `DELETE /products/{id}` | None | `204`, empty |

`ProductRequest`:

```json
{
  "name": "Long Grain Rice",
  "description": "Five kilogram bag",
  "sku": "RICE-5KG",
  "categoryId": "7eb54e2b-6e39-49c0-b1a5-928aef4b13be",
  "imageUrl": "https://example.test/rice.png",
  "basePrice": 12.5,
  "active": true
}
```

`name` and `sku` are required; SKU is unique. `categoryId` is optional but must identify an
existing category when supplied. `basePrice` defaults to `0` and cannot be negative. A product
referenced by stock, a reservation, or stock movement history cannot be deleted (`409`).

`Product`:

```json
{
  "id": "19b7c414-44ac-4ce0-89c7-a1ed95062f1d",
  "name": "Long Grain Rice",
  "description": "Five kilogram bag",
  "sku": "RICE-5KG",
  "categoryId": "7eb54e2b-6e39-49c0-b1a5-928aef4b13be",
  "imageUrl": "https://example.test/rice.png",
  "basePrice": 12.5,
  "active": true,
  "createdAt": "2026-11-21T05:30:00Z",
  "updatedAt": "2026-11-21T05:30:00Z"
}
```

## Store inventory

| Method and path | Request | Success response |
| --- | --- | --- |
| `GET /inventory?storeId={uuid}` | None; `storeId` is optional | `200`, `InventoryItem[]` |
| `PUT /inventory` | `StockRequest` | `200`, `InventoryItem` |
| `GET /inventory/{storeId}/{productId}` | None | `200`, `InventoryItem` |
| `POST /inventory/adjust` | `StockAdjustment` | `200`, `InventoryItem` |
| `GET /inventory/low-stock?storeId={uuid}` | None; `storeId` is optional | `200`, `InventoryItem[]` |
| `GET /inventory/movements?storeId={uuid}&productId={uuid}` | None; both IDs required | `200`, `StockMovement[]` |

`StockRequest` upserts the row for the `(storeId, productId)` pair. It requires `storeId`,
`productId`, and `price`. `onHand` and `lowStockThreshold` default to `0` if omitted. Price and
quantities cannot be negative. `reserved` is maintained by reservation operations; clients cannot
set it directly.

```json
{
  "storeId": "a9bfe29d-7c7d-412b-99d5-4db04cb6a6af",
  "productId": "19b7c414-44ac-4ce0-89c7-a1ed95062f1d",
  "price": 4.5,
  "onHand": 10,
  "lowStockThreshold": 2
}
```

`StockAdjustment` applies a non-zero delta to on-hand stock; it cannot reduce on-hand below the
reserved amount. `reason` is required and `referenceId` may be `null`.

```json
{
  "storeId": "a9bfe29d-7c7d-412b-99d5-4db04cb6a6af",
  "productId": "19b7c414-44ac-4ce0-89c7-a1ed95062f1d",
  "quantityChange": -2,
  "reason": "DAMAGED",
  "referenceId": null
}
```

`InventoryItem` (returned by inventory list, detail, upsert, adjustment, and low-stock routes):

```json
{
  "id": "1cd706fe-df2d-4c28-9c31-617512345678",
  "storeId": "a9bfe29d-7c7d-412b-99d5-4db04cb6a6af",
  "productId": "19b7c414-44ac-4ce0-89c7-a1ed95062f1d",
  "onHand": 10,
  "reserved": 0,
  "available": 10,
  "lowStockThreshold": 2,
  "price": 4.5,
  "version": 0,
  "updatedAt": "2026-11-21T05:30:00Z"
}
```

`available` is `onHand - reserved`. Low stock means `available <= lowStockThreshold`.
`StockMovement` response objects have this shape:

```json
{
  "id": "b7591670-17fc-47d7-af14-45a20e5bfc98",
  "storeInventoryId": "1cd706fe-df2d-4c28-9c31-617512345678",
  "type": "ADJUSTMENT",
  "quantityDelta": -2,
  "balanceAfter": 8,
  "referenceType": "ADJUSTMENT",
  "referenceId": null,
  "reason": "DAMAGED",
  "performedBy": null,
  "createdAt": "2026-11-21T05:30:00Z"
}
```

Movement results are newest first. An initial stock upsert does not create a movement; stock
adjustments and reservation lifecycle changes do.

## Reservations

| Method and path | Request | Success response |
| --- | --- | --- |
| `POST /inventory/reserve` | `ReserveRequest` | `201`, `ReserveResponse` |
| `POST /inventory/release` | `OrderRequest` | `200`, `ReserveResponse` |
| `POST /inventory/confirm` | `OrderRequest` | `200`, `ReserveResponse` |

`ReserveRequest` reserves all listed quantities atomically. Duplicate product IDs are combined.
An identical retry is idempotent; reusing the same order/store with different items returns a
`FAILED` response and does not change stock.

```json
{
  "orderId": "20b7c414-44ac-4ce0-89c7-a1ed95062f1d",
  "storeId": "a9bfe29d-7c7d-412b-99d5-4db04cb6a6af",
  "items": [
    { "productId": "19b7c414-44ac-4ce0-89c7-a1ed95062f1d", "quantity": 2 },
    { "productId": "5cd206fe-df2d-4c28-9c31-617512345678", "quantity": 1 }
  ]
}
```

`items` must not be empty and each quantity must be positive. Reserve success returns status
`RESERVED`; insufficient stock returns status `FAILED` (the route still responds with HTTP `201`).
The app must inspect both the HTTP response and the response body's `status`.

```json
{
  "orderId": "20b7c414-44ac-4ce0-89c7-a1ed95062f1d",
  "status": "RESERVED",
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

`OrderRequest`, used for release and confirm:

```json
{ "orderId": "20b7c414-44ac-4ce0-89c7-a1ed95062f1d" }
```

Both routes return the same `ReserveResponse` shape. Release sets the top-level and item statuses
to `RELEASED` and restores availability. Confirm sets them to `CONFIRMED` and consumes the
reserved on-hand stock. Repeating the same release or confirm is idempotent; confirming a released
reservation or releasing a confirmed reservation is rejected with `400`.

## Internal service-to-service endpoints

These are intended for trusted backend services, not direct Flutter calls. They use the same
request/response structures as the public reservation routes.

| Method and path | Request | Success response |
| --- | --- | --- |
| `POST /internal/products/validate` | `ValidateRequest` | `200`, `ValidateResponse` |
| `POST /internal/inventory/reserve` | `ReserveRequest` | `201`, `ReserveResponse` |
| `POST /internal/inventory/release` | `OrderRequest` | `200`, `ReserveResponse` |
| `POST /internal/inventory/confirm` | `OrderRequest` | `200`, `ReserveResponse` |

`ValidateRequest`:

```json
{
  "storeId": "a9bfe29d-7c7d-412b-99d5-4db04cb6a6af",
  "productIds": ["19b7c414-44ac-4ce0-89c7-a1ed95062f1d"]
}
```

`ValidateResponse`:

```json
{
  "storeId": "a9bfe29d-7c7d-412b-99d5-4db04cb6a6af",
  "items": [
    {
      "productId": "19b7c414-44ac-4ce0-89c7-a1ed95062f1d",
      "name": "Long Grain Rice",
      "available": 10,
      "price": 4.5
    }
  ]
}
```

## Errors and client handling

Error responses have an `error` code and human-readable `message`:

```json
{
  "error": "NOT_FOUND",
  "message": "Product not found: 19b7c414-44ac-4ce0-89c7-a1ed95062f1d"
}
```

| HTTP status | Error codes | Client guidance |
| --- | --- | --- |
| `400` | `VALIDATION_ERROR`, `BAD_REQUEST` | Show or log the returned message; correct the request. |
| `404` | `NOT_FOUND` | Resource or store/product stock row does not exist. |
| `409` | `CONFLICT`, `INSUFFICIENT_STOCK` | Refresh stock or resolve the conflicting resource. |

The service does not paginate list responses. Catalog and inventory list endpoints return JSON
arrays, and successful `DELETE` calls have no response body.
