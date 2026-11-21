import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/inventory_item.dart';
import '../../../shared/models/order.dart';
import '../../auth/application/auth_controller.dart';

class ManagerRepository {
  ManagerRepository(this._dio);

  final Dio _dio;

  Future<List<Order>> fetchOrders({
    required String storeId,
    String? status,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.managerOrders,
        queryParameters: {
          'storeId': storeId,
          'status': ?status,
        },
      );
      final items = (response.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      return items.map(Order.fromJson).toList();
    } on DioException catch (e) {
      throw _error(e, 'Failed to load store orders');
    }
  }

  Future<Order> fetchOrder(String orderId) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiEndpoints.order(orderId));
      return Order.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to load order');
    }
  }

  Future<Order> patchStatus({
    required String orderId,
    required String toStatus,
    required String storeId,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.managerOrderStatus(orderId),
        data: {'status': toStatus, 'storeId': storeId},
      );
      return Order.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to update order status');
    }
  }

  Future<Order> assignRider({
    required String orderId,
    required String storeId,
    required String riderId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.managerAssignRider(orderId),
        data: {'storeId': storeId, 'riderId': riderId},
      );
      return Order.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to assign rider');
    }
  }

  Future<List<AppUser>> fetchStoreRiders(String storeId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.managerRiders,
        queryParameters: {'storeId': storeId},
      );
      final items = (response.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      return items.map(AppUser.fromJson).toList();
    } on DioException catch (e) {
      throw _error(e, 'Failed to load riders');
    }
  }

  Future<List<InventoryItem>> fetchInventory(String storeId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.inventory,
        queryParameters: {'storeId': storeId},
      );
      final items = (response.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      return items.map(InventoryItem.fromJson).toList();
    } on DioException catch (e) {
      throw _error(e, 'Failed to load inventory');
    }
  }

  Future<InventoryItem> updateInventory({
    required String storeId,
    required String productId,
    double? price,
    int? stockQty,
    int? lowStockThreshold,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.inventoryProduct(productId),
        data: {
          'storeId': storeId,
          'price': ?price,
          'stockQty': ?stockQty,
          'lowStockThreshold': ?lowStockThreshold,
        },
      );
      return InventoryItem.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to update inventory');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAvailableProducts(
    String storeId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.inventoryAvailableProducts,
        queryParameters: {'storeId': storeId},
      );
      return (response.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _error(e, 'Failed to load available products');
    }
  }

  Future<InventoryItem> addInventoryItem({
    required String storeId,
    String? productId,
    String? name,
    String? sku,
    required double price,
    required int stockQty,
    int lowStockThreshold = 10,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.inventory,
        data: {
          'storeId': storeId,
          'productId': ?productId,
          'name': ?name,
          'sku': ?sku,
          'price': price,
          'stockQty': stockQty,
          'lowStockThreshold': lowStockThreshold,
        },
      );
      return InventoryItem.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to add inventory item');
    }
  }

  Future<List<InventoryItem>> fetchAlerts(String storeId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.inventoryAlerts,
        queryParameters: {'storeId': storeId},
      );
      final items = (response.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      return items.map(InventoryItem.fromJson).toList();
    } on DioException catch (e) {
      throw _error(e, 'Failed to load low-stock alerts');
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

final managerRepositoryProvider = Provider<ManagerRepository>((ref) {
  return ManagerRepository(ref.watch(dioProvider));
});

final managerStoreIdProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider).user?.storeId;
});

final managerOrdersProvider =
    FutureProvider.autoDispose.family<List<Order>, String?>((ref, status) {
  final storeId = ref.watch(managerStoreIdProvider);
  if (storeId == null || storeId.isEmpty) {
    throw ApiException(message: 'Manager store mapping is missing');
  }
  return ref.watch(managerRepositoryProvider).fetchOrders(
        storeId: storeId,
        status: status,
      );
});

final managerOrderDetailProvider =
    FutureProvider.autoDispose.family<Order, String>((ref, orderId) {
  return ref.watch(managerRepositoryProvider).fetchOrder(orderId);
});

final managerInventoryProvider =
    FutureProvider.autoDispose<List<InventoryItem>>((ref) {
  final storeId = ref.watch(managerStoreIdProvider);
  if (storeId == null || storeId.isEmpty) {
    throw ApiException(message: 'Manager store mapping is missing');
  }
  return ref.watch(managerRepositoryProvider).fetchInventory(storeId);
});

final managerAlertsProvider =
    FutureProvider.autoDispose<List<InventoryItem>>((ref) {
  final storeId = ref.watch(managerStoreIdProvider);
  if (storeId == null || storeId.isEmpty) {
    throw ApiException(message: 'Manager store mapping is missing');
  }
  return ref.watch(managerRepositoryProvider).fetchAlerts(storeId);
});

final managerRidersProvider = FutureProvider.autoDispose<List<AppUser>>((ref) {
  final storeId = ref.watch(managerStoreIdProvider);
  if (storeId == null || storeId.isEmpty) {
    throw ApiException(message: 'Manager store mapping is missing');
  }
  return ref.watch(managerRepositoryProvider).fetchStoreRiders(storeId);
});
