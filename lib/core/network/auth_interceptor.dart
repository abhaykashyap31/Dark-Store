import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_endpoints.dart';

/// On 401: refresh once with a bare Dio client, retry original request, or
/// clear the session.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this._dio,
    required this._tokenStorage,
    required this._onSessionExpired,
  }) : _refreshDio = Dio(
          BaseOptions(
            baseUrl: _dio.options.baseUrl,
            connectTimeout: _dio.options.connectTimeout,
            receiveTimeout: _dio.options.receiveTimeout,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage _tokenStorage;
  final void Function() _onSessionExpired;

  bool _refreshing = false;

  /// Attach the same mock/network stack used by the main client (except auth).
  void attachRefreshInterceptors(List<Interceptor> interceptors) {
    _refreshDio.interceptors
      ..clear()
      ..addAll(interceptors);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    final isAuthPath = path.contains(ApiEndpoints.authLogin) ||
        path.contains(ApiEndpoints.authRegister) ||
        path.contains(ApiEndpoints.authRefresh);

    if (status != 401 || isAuthPath || _refreshing) {
      handler.next(err);
      return;
    }

    _refreshing = true;
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _failSession(handler, err);
        return;
      }

      final refreshResponse = await _refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {'Authorization': 'Bearer $refreshToken'},
        ),
      );

      final data = refreshResponse.data;
      final accessToken = data?['accessToken'] as String?;
      final newRefresh = data?['refreshToken'] as String?;
      if (accessToken == null || newRefresh == null) {
        await _failSession(handler, err);
        return;
      }

      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefresh,
      );

      final request = err.requestOptions;
      request.headers['Authorization'] = 'Bearer $accessToken';
      final response = await _dio.fetch<dynamic>(request);
      handler.resolve(response);
    } catch (_) {
      await _failSession(handler, err);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _failSession(
    ErrorInterceptorHandler handler,
    DioException err,
  ) async {
    await _tokenStorage.clear();
    _onSessionExpired();
    handler.next(err);
  }
}
