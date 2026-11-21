# iDarkStore (Flutter)

Role-based quick-commerce **web** app for **CUSTOMER**, **ADMIN**, **MANAGER**, and **RIDER**.

- API contract (Auth / Users / Stores / Admin): [`API_REFERENCE.md`](./API_REFERENCE.md)
- Backend wiring: [`BACKEND_INTEGRATION.md`](./BACKEND_INTEGRATION.md)
- Architecture: [`architecture.md`](./architecture.md)

## Run (web)

```bash
flutter pub get
flutter run -d chrome
```

Mock APIs are **on by default** (`USE_MOCK_APIS=true`).

### Live Gateway (web / desktop)

```bash
flutter run -d chrome \
  --dart-define=USE_MOCK_APIS=false \
  --dart-define=API_BASE_URL=http://localhost:8080/api/v1 \
  --dart-define=ENABLE_API_LOGS=true
```

Base URL must include `/api/v1`. Never call ports 8081–8083 from the app.

### Demo logins

| Email | Password | Role |
|-------|----------|------|
| `user@darkstore.com` | `password` | CUSTOMER |
| `admin@darkstore.com` | `Admin@123` | ADMIN |
| `manager@darkstore.com` | `password` | MANAGER (`storeId: 1`) |
| `rider@darkstore.com` | `password` | RIDER (`storeId: 1`) |
| `inactive@darkstore.com` | `password` | DISABLED |

**Register** creates a **CUSTOMER** only, then signs in. Manager/Rider accounts are created by Admin (`POST /admin/users`).

Path constants: `lib/core/network/api_endpoints.dart`.
