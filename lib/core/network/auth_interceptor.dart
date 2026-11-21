import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_endpoints.dart';
import 'api_response.dart';

/// On 401 `TOKEN_EXPIRED`: refresh once, retry original request, or clear session.
/// On `TOKEN_INVALID` / `ACCOUNT_DISABLED`: clear session (do not retry).
/// On `ACCESS_DENIED` (403): pass through — do not log out.
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

  void attachRefreshInterceptors(List<Interceptor> interceptors) {
    _refreshDio.interceptors
      ..clear()
      ..addAll(interceptors);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final code = apiErrorCode(err.response?.data);
    final path = err.requestOptions.path;
    final isAuthPath = path.contains(ApiEndpoints.authLogin) ||
        path.contains(ApiEndpoints.authRegister) ||
        path.contains(ApiEndpoints.authRefresh) ||
        path.contains(ApiEndpoints.authLogout);

    if (code == 'ACCESS_DENIED') {
      handler.next(err);
      return;
    }

    if (code == 'TOKEN_INVALID' || code == 'ACCOUNT_DISABLED') {
      await _failSession(handler, err);
      return;
    }

    final shouldRefresh = status == 401 &&
        (code == 'TOKEN_EXPIRED' || code == null) &&
        !isAuthPath &&
        !_refreshing;

    if (!shouldRefresh) {
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
      );

      final data = refreshResponse.data;
      final accessToken = data?['accessToken'] as String?;
      final newRefresh = data?['refreshToken'] as String?;
      if (accessToken == null ||
          accessToken.isEmpty ||
          newRefresh == null ||
          newRefresh.isEmpty) {
        await _failSession(handler, err);
        return;
      }

      // Refresh tokens are single-use — persist the new pair before anything else.
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
