# Dark Store API Reference (Auth, Users, Stores, Admin)

Audience: Flutter developers and anyone calling the backend.
Everything below goes through the **API Gateway**. Never call ports 8081, 8082 or 8083 directly.

## 1. Quick facts

| Topic | Value |
|---|---|
| Base URL (Android emulator) | `http://10.0.2.2:8080/api/v1` |
| Base URL (iOS simulator / web / desktop) | `http://localhost:8080/api/v1` |
| Base URL (real phone) | `http://<laptop-ip>:8080/api/v1` (same Wi-Fi, firewall must allow 8080) |
| Format | JSON in, JSON out, `Content-Type: application/json` |
| Auth header | `Authorization: Bearer <accessToken>` |
| Roles | `CUSTOMER`, `MANAGER`, `RIDER`, `ADMIN` (always upper-case strings) |
| Access token life | 15 minutes (`expiresIn` is `900`, in seconds) |
| Refresh token life | 7 days, **single use** (every refresh returns a new pair) |
| IDs | UUID strings (`id`, `storeId`) |
| Test admin | `admin@darkstore.com` / `Admin@123` |

Public endpoints (no header): `/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout`.
Everything else needs the `Authorization` header.

## 2. Error format

Every error has the same body:

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

## 3. Data shapes

### User
```json
{ "id": "550e8400-e29b-41d4-a716-446655440000", "email": "asha@example.com", "fullName": "Asha Rao", "phone": "9876543210",
  "role": "CUSTOMER", "status": "ACTIVE", "storeId": null }
```
`storeId` is set only for `MANAGER` and `RIDER`. `status` is `ACTIVE` or `DISABLED`. `phone` can be `null`.

### Auth response (login and refresh)
```json
{ "accessToken": "eyJhbGciOi...", "refreshToken": "kF3...random...",
  "expiresIn": 900, "user": { "...User..." } }
```

### Address
```json
{ "id": "550e8400-e29b-41d4-a716-446655440001", "label": "Home", "line1": "12 Marine Drive",
  "line2": "Flat 4B", "city": "Mumbai", "state": "Maharashtra", "postalCode": "400020",
  "country": "India", "defaultAddress": true }
```

### Store
```json
{ "id": "550e8400-e29b-41d4-a716-446655440002", "code": "DS-BOM-01", "name": "Andheri Dark Store",
  "line1": "Link Road, Andheri West", "city": "Mumbai", "state": "Maharashtra",
  "postalCode": "400053", "phone": "02212345678", "active": true }
```

### Field limits (violations return `VALIDATION_ERROR`)

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

## 4. Auth

### POST `/auth/register` (public)
Creates a **CUSTOMER**. It does not log in. Call `/auth/login` next.

```json
{ "fullName": "Asha Rao", "email": "asha@example.com", "password": "Secret@123", "phone": "9876543210" }
```
- `201` with a **User**
- `400 VALIDATION_ERROR`, `409 EMAIL_ALREADY_EXISTS`

### POST `/auth/login` (public)
```json
{ "email": "asha@example.com", "password": "Secret@123" }
```
- `200` with an **Auth response**
- `401 INVALID_CREDENTIALS`, `403 ACCOUNT_DISABLED`, `400 VALIDATION_ERROR`

Use `user.role` to decide which screens to open.

### POST `/auth/refresh` (public)
```json
{ "refreshToken": "kF3...random..." }
```
- `200` with an **Auth response** (new access token **and** new refresh token)
- `401 TOKEN_INVALID` (unknown or already used), `401 TOKEN_EXPIRED` (older than 7 days), `403 ACCOUNT_DISABLED`

The old refresh token stops working immediately. Save the new one before doing anything else.
If two requests refresh at the same time with the same token, the second one fails. The Flutter guide shows how to avoid that.

### POST `/auth/logout` (public)
```json
{ "refreshToken": "kF3...random..." }
```
- `204`, no body. Unknown tokens are ignored (still `204`). Always clear local storage afterwards.

## 5. Profile (any logged-in role)

### GET `/users/me`
- `200` with a **User**

### PUT `/users/me`
```json
{ "fullName": "Asha R.", "phone": "9123456780" }
```
- `200` with the updated **User**
- `name` is required. Leaving out `phone` (or sending `null`) **clears** the phone number, so always send the current value.

## 6. Addresses (CUSTOMER only; other roles get `403 ACCESS_DENIED`)

### GET `/users/me/addresses`
- `200` with a list of **Address**

### POST `/users/me/addresses`
```json
{ "label": "Home", "line1": "12 Marine Drive", "line2": "Flat 4B", "city": "Mumbai",
  "state": "Maharashtra", "postalCode": "400020", "country": "India", "defaultAddress": true }
```
- `201` with the **Address**
- The first address is always the default. Sending `defaultAddress: true` makes this one the default and removes the flag from the others.

### PUT `/users/me/addresses/{id}`
Same body as POST. Replaces all fields.
- `200` with the **Address**, `404 NOT_FOUND` if it is not the caller's address
- `defaultAddress: true` moves the default here. `false` or missing does not remove the default.

### DELETE `/users/me/addresses/{id}`
- `204`, or `404 NOT_FOUND`
- Deleting the default address does not pick a new default automatically.

## 7. Stores

### GET `/stores` and GET `/stores/{id}` (any logged-in role)
- `200` with a list of **Store** / one **Store**. The list includes inactive stores, so filter on `active` in the app.
- `404 NOT_FOUND`

### POST `/stores` (ADMIN)
```json
{ "code": "DS-BOM-01", "name": "Andheri Dark Store", "line1": "Link Road, Andheri West",
  "city": "Mumbai", "state": "Maharashtra", "postalCode": "400053",
  "phone": "02212345678", "active": true }
```
- `201` with the **Store**, `409 STORE_CODE_EXISTS`, `403 ACCESS_DENIED`

### PUT `/stores/{id}` (ADMIN)
Same body. Replaces all fields (omitted optional fields become `null`; omitted `active` keeps the current value).
- `200`, `404`, `409 STORE_CODE_EXISTS`

## 8. Admin: manager and rider accounts (ADMIN only)

### POST `/admin/users`
```json
{ "fullName": "Store Manager", "email": "mgr@darkstore.com", "password": "Manager@123",
  "phone": "9000000001", "role": "MANAGER", "storeId": "550e8400-e29b-41d4-a716-446655440002" }
```
- `role` must be `MANAGER` or `RIDER`. `storeId` is required and must exist.
- `201` with a **User**
- `400 VALIDATION_ERROR` (wrong role, missing storeId), `404 NOT_FOUND` (store), `409 EMAIL_ALREADY_EXISTS`

### GET `/admin/users?role=`
`role` is optional (`CUSTOMER`, `MANAGER`, `RIDER`, `ADMIN`). No paging yet (returns everyone).
- `200` with a list of **User**, `400` for an unknown role value

### PATCH `/admin/users/{id}/status`
```json
{ "status": "DISABLED" }
```
- `200` with the **User**. An admin cannot change their own status (`400 VALIDATION_ERROR`).
- A disabled user can still use a token they already have until it expires (max 15 minutes), but cannot log in or refresh.

## 9. Who can call what

| Endpoint | CUSTOMER | MANAGER | RIDER | ADMIN |
|---|:-:|:-:|:-:|:-:|
| `/auth/*` | yes | yes | yes | yes |
| `GET, PUT /users/me` | yes | yes | yes | yes |
| `/users/me/addresses*` | yes | no | no | no |
| `GET /stores*` | yes | yes | yes | yes |
| `POST, PUT /stores*` | no | no | no | yes |
| `/admin/users*` | no | no | no | yes |

Routes owned by other teams (all need a token): `/products`, `/categories`, `/inventory` (Inventory service) and `/cart`, `/orders`, `/manager`, `/rider` (Order service).

## 10. What is inside the access token

JWT claims: `sub` and `userId` (user id), `role`, `storeId` (only for MANAGER and RIDER), `iat`, `exp`.
The app may decode it to read the role, but must never trust it for security. The server decides. Prefer `user.role` from the login response.

## 11. curl examples

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
