# iDarkStore (Flutter)

Role-based quick-commerce **web** app for **CUSTOMER**, **ADMIN**, **MANAGER**, and **RIDER**.

- **UI flow (screens & files for managers):** [`UI_FLOW.md`](./UI_FLOW.md)
- API contract (Auth / Users / Stores / Admin): [`API_REFERENCE.md`](./API_REFERENCE.md)
- Backend wiring: [`BACKEND_INTEGRATION.md`](./BACKEND_INTEGRATION.md)
- Architecture: [`architecture.md`](./architecture.md)

## Run (web)

Frontend is pinned to **http://localhost:5000** (`--web-port=5000`).

```bash
flutter pub get
flutter run -d chrome --web-hostname=localhost --web-port=5000
```

Mock APIs are **on by default** (`USE_MOCK_APIS=true`).

### Live Gateway (web)

```bash
flutter run -d chrome --web-hostname=localhost --web-port=5000 \
  --dart-define=USE_MOCK_APIS=false \
  --dart-define=API_BASE_URL=http://localhost:8080/api/v1 \
  --dart-define=ENABLE_API_LOGS=true
```

Open **http://localhost:5000**. Gateway must enable **CORS** for origin `http://localhost:5000` (headers `Authorization`, `Content-Type`, `X-Correlation-Id`).

Base URL must include `/api/v1`. Never call ports 8081–8083 from the app.

### Demo logins

| Email | Password | Role |
|-------|----------|------|
| `user@darkstore.com` | `password` | CUSTOMER |
| `admin@darkstore.com` | `Admin@123` | ADMIN |
| `manager@darkstore.com` | `password` | MANAGER (Koramangala store UUID) |
| `rider@darkstore.com` | `password` | RIDER (Koramangala store UUID) |
| `inactive@darkstore.com` | `password` | DISABLED |

**Register** creates a **CUSTOMER** only, then signs in. Manager/Rider accounts are created by Admin (`POST /admin/users`).

Path constants: `lib/core/network/api_endpoints.dart`.
