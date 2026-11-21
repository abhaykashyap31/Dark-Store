/// App-wide configuration. Override at build time with `--dart-define`.
///
/// Examples:
/// ```bash
/// # Local mocks (default)
/// flutter run
///
/// # Real Gateway
/// flutter run \
///   --dart-define=USE_MOCK_APIS=false \
///   --dart-define=API_BASE_URL=https://gateway.example.com
///
/// # Verbose Dio logs against Gateway
/// flutter run \
///   --dart-define=USE_MOCK_APIS=false \
///   --dart-define=API_BASE_URL=http://localhost:8080 \
///   --dart-define=ENABLE_API_LOGS=true
/// ```
///
/// Full contract: see `BACKEND_INTEGRATION.md`.
class AppConfig {
  const AppConfig._();

  static const String appName = 'iDarkStore';

  /// Gateway base URL only — Flutter never calls microservices directly.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// When true, Dio uses in-app mock placeholders instead of the Gateway.
  static const bool useMockApis = bool.fromEnvironment(
    'USE_MOCK_APIS',
    defaultValue: true,
  );

  /// When true, Dio logs request/response summaries (never tokens in clear).
  static const bool enableApiLogs = bool.fromEnvironment(
    'ENABLE_API_LOGS',
    defaultValue: false,
  );

  /// Connect timeout for Gateway calls (seconds).
  static const int connectTimeoutSeconds = int.fromEnvironment(
    'API_CONNECT_TIMEOUT_SEC',
    defaultValue: 15,
  );

  /// Receive timeout for Gateway calls (seconds).
  static const int receiveTimeoutSeconds = int.fromEnvironment(
    'API_RECEIVE_TIMEOUT_SEC',
    defaultValue: 30,
  );

  /// Header name for distributed tracing / correlation.
  static const String correlationIdHeader = 'X-Correlation-Id';

  /// Whether the app is pointed at live Gateway (not mocks).
  static bool get isLiveBackend => !useMockApis;

  static Duration get connectTimeout =>
      Duration(seconds: connectTimeoutSeconds);

  static Duration get receiveTimeout =>
      Duration(seconds: receiveTimeoutSeconds);
}
