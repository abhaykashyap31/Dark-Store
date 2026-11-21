import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/order.dart';
import '../../auth/application/auth_controller.dart';

class RiderRepository {
  RiderRepository(this._dio);

  final Dio _dio;

  Future<List<Order>> fetchDeliveries() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiEndpoints.riderOrders);
      final items = (response.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      return items.map(Order.fromJson).toList();
    } on DioException catch (e) {
      throw _error(e, 'Failed to load deliveries');
    }
  }

  Future<Order> fetchOrder(String orderId) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiEndpoints.order(orderId));
      return Order.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to load delivery');
    }
  }

  Future<Order> patchStatus({
    required String orderId,
    required String toStatus,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.riderOrderStatus(orderId),
        data: {'status': toStatus},
      );
      return Order.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to update delivery status');
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

final riderRepositoryProvider = Provider<RiderRepository>((ref) {
  return RiderRepository(ref.watch(dioProvider));
});

final riderStoreIdProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider).user?.storeId;
});

final riderDeliveriesProvider =
    FutureProvider.autoDispose<List<Order>>((ref) {
  final storeId = ref.watch(riderStoreIdProvider);
  if (storeId == null || storeId.isEmpty) {
    throw ApiException(message: 'Rider store mapping is missing');
  }
  return ref.watch(riderRepositoryProvider).fetchDeliveries();
});

final riderOrderDetailProvider =
    FutureProvider.autoDispose.family<Order, String>((ref, orderId) {
  return ref.watch(riderRepositoryProvider).fetchOrder(orderId);
});
