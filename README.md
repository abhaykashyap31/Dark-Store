# iDarkStore (Flutter)

Role-based quick-commerce web app for **USER**, **ADMIN**, **MANAGER**, and **RIDER**.

- Architecture: [`architecture.md`](./architecture.md)
- Diagrams: [`diagrams-explained.md`](./diagrams-explained.md)
- **Backend integration:** [`BACKEND_INTEGRATION.md`](./BACKEND_INTEGRATION.md)

## Current phase: Phase 8 prep (Gateway placeholders)

Phases 0–7 UI/mocks are in place. Endpoint constants, Dio config, and the integration checklist live in [`BACKEND_INTEGRATION.md`](./BACKEND_INTEGRATION.md). Flip to the live Gateway with the dart-defines below when services are ready.

### Run

```bash
flutter pub get
flutter run
```

Mock APIs are **on by default** (`USE_MOCK_APIS=true`).

### Demo logins (password: `password`)

| Email | Role |
|-------|------|
| `user@darkstore.com` | USER |
| `admin@darkstore.com` | ADMIN |
| `manager@darkstore.com` | MANAGER (`storeId: s_001`) |
| `rider@darkstore.com` | RIDER (`storeId: s_001`) |
| `inactive@darkstore.com` | Blocked (`active: false`) |

Customers can also use **Create account** on the login screen (USER self-register only).

### Dart defines (Gateway)

```bash
# Live Gateway
flutter run \
  --dart-define=USE_MOCK_APIS=false \
  --dart-define=API_BASE_URL=https://your-gateway \
  --dart-define=ENABLE_API_LOGS=true
```

Path constants: `lib/core/network/api_endpoints.dart`. Full contract and checklist: [`BACKEND_INTEGRATION.md`](./BACKEND_INTEGRATION.md).
