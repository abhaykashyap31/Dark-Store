import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/models/app_user.dart';

class AuthRepository {
  AuthRepository({
    required this._dio,
    required this._tokenStorage,
  });

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authLogin,
        data: {'email': email, 'password': password},
      );
      return await _persistSession(response.data!);
    } on DioException catch (e) {
      throw _asApiException(e, fallback: 'Login failed');
    }
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authRegister,
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      return await _persistSession(response.data!);
    } on DioException catch (e) {
      throw _asApiException(e, fallback: 'Registration failed');
    }
  }

  Future<AuthSession?> restoreSession() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {'Authorization': 'Bearer $refreshToken'},
        ),
      );
      final session = await _persistSession(response.data!);

      // Prefer live profile from /users/me after refresh.
      try {
        final me = await fetchMe();
        return AuthSession(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
          expiresIn: session.expiresIn,
          user: me,
        );
      } catch (_) {
        return session;
      }
    } catch (_) {
      await _tokenStorage.clear();
      return null;
    }
  }

  Future<AppUser> fetchMe() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiEndpoints.usersMe);
      return AppUser.fromJson(response.data!);
    } on DioException catch (e) {
      throw _asApiException(e, fallback: 'Failed to load profile');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>(ApiEndpoints.authLogout);
    } catch (_) {
      // Best-effort; always clear local tokens.
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<AuthSession> _persistSession(Map<String, dynamic> data) async {
    final session = AuthSession.fromJson(data);
    await _tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  ApiException _asApiException(DioException e, {required String fallback}) {
    return ApiException(
      message: _messageFrom(e) ?? fallback,
      statusCode: e.response?.statusCode,
    );
  }

  String? _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return e.message;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});
