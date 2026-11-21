import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/address.dart';
import '../../../shared/models/order.dart';
import '../../auth/application/auth_controller.dart';

class OrderRepository {
  OrderRepository(this._dio);

  final Dio _dio;

  Future<List<Address>> fetchAddresses() async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>(ApiEndpoints.usersMeAddresses);
      final items = (response.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      return items.map(Address.fromJson).toList();
    } on DioException catch (e) {
      throw _error(e, 'Failed to load addresses');
    }
  }

  Future<Address> addAddress(Address draft) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.usersMeAddresses,
        data: draft.toJson()..remove('id'),
      );
      return Address.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to save address');
    }
  }

  Future<Address> updateAddress(Address address) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.userAddress(address.id),
        data: address.toJson()..remove('id'),
      );
      return Address.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to update address');
    }
  }

  Future<Order> placeOrder({
    required String addressId,
    String paymentMethod = 'COD',
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.orders,
        data: {
          'addressId': addressId,
          'paymentMethod': paymentMethod,
        },
      );
      return Order.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to place order');
    }
  }

  Future<List<Order>> fetchOrders() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiEndpoints.orders);
      final items = (response.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      return items.map(Order.fromJson).toList();
    } on DioException catch (e) {
      throw _error(e, 'Failed to load orders');
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

  Future<Order> cancelOrder(String orderId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.orderCancel(orderId),
      );
      return Order.fromJson(response.data!);
    } on DioException catch (e) {
      throw _error(e, 'Failed to cancel order');
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

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(dioProvider));
});

final addressesProvider = FutureProvider.autoDispose<List<Address>>((ref) {
  return ref.watch(orderRepositoryProvider).fetchAddresses();
});

final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(orderRepositoryProvider).fetchOrders();
});

final orderDetailProvider =
    FutureProvider.autoDispose.family<Order, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).fetchOrder(orderId);
});
