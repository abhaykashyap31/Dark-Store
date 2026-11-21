import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Lightweight request/response logger for Gateway debugging.
/// Does not print Authorization bearer values.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppConfig.enableApiLogs && kDebugMode) {
      final correlation = options.headers[AppConfig.correlationIdHeader];
      debugPrint(
        '[API] → ${options.method} ${options.baseUrl}${options.path}'
        ' corr=$correlation',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (AppConfig.enableApiLogs && kDebugMode) {
      debugPrint(
        '[API] ← ${response.statusCode} ${response.requestOptions.path}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (AppConfig.enableApiLogs && kDebugMode) {
      debugPrint(
        '[API] ✕ ${err.response?.statusCode} ${err.requestOptions.path}'
        ' ${err.message}',
      );
    }
    handler.next(err);
  }
}
