import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';
import 'mock_interceptor.dart';
import 'session_invalidation.dart';

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  final authInterceptor = AuthInterceptor(
    dio: dio,
    tokenStorage: tokenStorage,
    onSessionExpired: () {
      ref.read(sessionInvalidationProvider.notifier).state++;
    },
  );

  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        // Guard: never call service-internal routes from the app.
        if (options.path.contains(ApiEndpoints.forbiddenInternalPrefix)) {
          handler.reject(
            DioException(
              requestOptions: options,
              error:
                  'Flutter must not call ${ApiEndpoints.forbiddenInternalPrefix} routes',
              type: DioExceptionType.unknown,
            ),
          );
          return;
        }

        options.headers[AppConfig.correlationIdHeader] = const Uuid().v4();

        final accessToken = await tokenStorage.readAccessToken();
        if (accessToken != null && accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }

        handler.next(options);
      },
    ),
  );

  if (AppConfig.enableApiLogs) {
    dio.interceptors.add(LoggingInterceptor());
  }

  // Mock must run before AuthInterceptor's error/retry path hits the network.
  // Token header is already attached by the wrapper above.
  if (AppConfig.useMockApis) {
    final mock = MockInterceptor();
    dio.interceptors.add(mock);
    dio.interceptors.add(authInterceptor);
    authInterceptor.attachRefreshInterceptors([
      if (AppConfig.enableApiLogs) LoggingInterceptor(),
      mock,
    ]);
  } else {
    dio.interceptors.add(authInterceptor);
  }

  return dio;
});
