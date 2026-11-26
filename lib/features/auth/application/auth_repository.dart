import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_role.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/dio_error_mapper.dart';
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
      throw mapDioError(e, fallback: 'Login failed');
    }
  }

  /// POST `/auth/register` returns a User (not a session). Call [login] after.
  /// [role] is sent for mock/demo; live Gateway creates CUSTOMER only.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required AppRole role,
    String? phone,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authRegister,
        data: {
          'fullName': name,
          'email': email,
          'password': password,
          // Mock/demo only — live Gateway creates CUSTOMER and ignores role.
          'role': role.apiValue,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      return AppUser.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e, fallback: 'Registration failed');
    }
  }

  Future<AuthSession?> restoreSession() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': refreshToken},
      );
      final session = await _persistSession(response.data!);

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
      throw mapDioError(e, fallback: 'Failed to load profile');
    }
  }

  Future<AppUser> updateMe({
    required String name,
    String? phone,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.usersMe,
        data: {
          'fullName': name,
          'phone': phone,
        },
      );
      return AppUser.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e, fallback: 'Failed to update profile');
    }
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    try {
      await _dio.post<void>(
        ApiEndpoints.authLogout,
        data: {
          if (refreshToken != null && refreshToken.isNotEmpty)
            'refreshToken': refreshToken,
        },
      );
    } catch (_) {
      // Best-effort; always clear local tokens (API returns 204).
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
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});
