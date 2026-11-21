import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/admin_product.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/store.dart';

class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  Future<List<Store>> fetchStores() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiEndpoints.adminStores);
      final items = (response.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      return items.map(Store.fromJson).toList();
    } on DioException catch (e) {
      throw _error(e, 'Failed to load stores');
    }
  }

  Future<Store> createStore(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.adminStores,
        data: body,
      );
      return Store.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to create store');
    }
  }

  Future<Store> updateStore(String id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.adminStore(id),
        data: body,
      );
      return Store.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to update store');
    }
  }

  Future<Store> setStoreActive(String id, bool active) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.adminStoreActive(id),
        data: {'active': active},
      );
      return Store.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to update store status');
    }
  }

  Future<List<AppUser>> fetchUsers({String? role, bool? active}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.adminUsers,
        queryParameters: {
          'role': ?role,
          'active': ?active,
        },
      );
      final items = (response.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      return items.map(AppUser.fromJson).toList();
    } on DioException catch (e) {
      throw _error(e, 'Failed to load users');
    }
  }

  Future<AppUser> createStaffUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required String storeId,
    String? phone,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.adminUsers,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'storeId': storeId,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      return AppUser.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to create account');
    }
  }

  Future<AppUser> setUserActive(String id, bool active) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.adminUserActive(id),
        data: {'active': active},
      );
      return AppUser.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to update account status');
    }
  }

  Future<List<AdminProduct>> fetchProducts() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiEndpoints.adminProducts);
      final items = (response.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      return items.map(AdminProduct.fromJson).toList();
    } on DioException catch (e) {
      throw _error(e, 'Failed to load products');
    }
  }

  Future<AdminProduct> createProduct(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.adminProducts,
        data: body,
      );
      return AdminProduct.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to create product');
    }
  }

  Future<AdminProduct> updateProduct(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.adminProduct(id),
        data: body,
      );
      return AdminProduct.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to update product');
    }
  }

  Future<AdminProduct> setProductActive(String id, bool active) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.adminProductActive(id),
        data: {'active': active},
      );
      return AdminProduct.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to update product status');
    }
  }

  Future<List<Category>> fetchCategories() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiEndpoints.categories);
      final items = (response.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      return items.map(Category.fromJson).toList();
    } on DioException catch (e) {
      throw _error(e, 'Failed to load categories');
    }
  }

  Future<Category> createCategory({required String name}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.categories,
        data: {'name': name},
      );
      return Category.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to create category');
    }
  }

  ApiException _error(DioException e, String fallback) {
    final data = e.response?.data;
    final message = data is Map && data['message'] is String
        ? data['message'] as String
        : e.message;
    return ApiException(
      message: message ?? fallback,
      statusCode: e.response?.statusCode,
    );
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(dioProvider));
});

final adminStoresProvider = FutureProvider.autoDispose<List<Store>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchStores();
});

final adminUsersProvider = FutureProvider.autoDispose<List<AppUser>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchUsers();
});

final adminProductsProvider =
    FutureProvider.autoDispose<List<AdminProduct>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchProducts();
});

final adminCategoriesProvider =
    FutureProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchCategories();
});
