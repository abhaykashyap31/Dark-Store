/// App-wide configuration. Override at build time with `--dart-define`.
///
/// Web / desktop Gateway (API_REFERENCE.md):
/// ```bash
/// flutter run -d chrome \
///   --dart-define=USE_MOCK_APIS=false \
///   --dart-define=API_BASE_URL=http://localhost:8080/api/v1
/// ```
///
/// Contract: see `API_REFERENCE.md`.
class AppConfig {
  const AppConfig._();

  static const String appName = 'iDarkStore';

  /// Gateway base URL including `/api/v1` — Flutter never calls microservices
  /// on 8081–8083 directly.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  /// When true, Dio uses in-app mock placeholders instead of the Gateway.
  static const bool useMockApis = bool.fromEnvironment(
    'USE_MOCK_APIS',
    defaultValue: false,
  );

  /// When true, Dio logs request/response summaries (never tokens in clear).
  static const bool enableApiLogs = bool.fromEnvironment(
    'ENABLE_API_LOGS',
    defaultValue: true,
  );

  static const int connectTimeoutSeconds = int.fromEnvironment(
    'API_CONNECT_TIMEOUT_SEC',
    defaultValue: 15,
  );

  static const int receiveTimeoutSeconds = int.fromEnvironment(
    'API_RECEIVE_TIMEOUT_SEC',
    defaultValue: 30,
  );

  static const String correlationIdHeader = 'X-Correlation-Id';

  static bool get isLiveBackend => !useMockApis;

  static Duration get connectTimeout =>
      Duration(seconds: connectTimeoutSeconds);

  static Duration get receiveTimeout =>
      Duration(seconds: receiveTimeoutSeconds);
}
