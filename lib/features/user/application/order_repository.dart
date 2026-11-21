import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../shared/models/address.dart';
import '../../../shared/models/order.dart';
import '../../auth/application/auth_controller.dart';

class OrderRepository {
  OrderRepository(this._dio);

  final Dio _dio;

  Future<List<Address>> fetchAddresses() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.usersMeAddresses);
      return parseObjectList(response.data).map(Address.fromJson).toList();
    } on DioException catch (e) {
      throw mapDioError(e, fallback: 'Failed to load addresses');
    }
  }

  Future<Address> addAddress(Address draft) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.usersMeAddresses,
        data: draft.toRequestBody(),
      );
      return Address.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e, fallback: 'Failed to save address');
    }
  }

  Future<Address> updateAddress(Address address) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.userAddress(address.id),
        data: address.toRequestBody(),
      );
      return Address.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e, fallback: 'Failed to update address');
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await _dio.delete<void>(ApiEndpoints.userAddress(addressId));
    } on DioException catch (e) {
      throw mapDioError(e, fallback: 'Failed to delete address');
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
          'addressId': int.tryParse(addressId) ?? addressId,
          'paymentMethod': paymentMethod,
        },
      );
      return Order.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e, fallback: 'Failed to place order');
    }
  }

  Future<List<Order>> fetchOrders() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.orders);
      return parseObjectList(response.data).map(Order.fromJson).toList();
    } on DioException catch (e) {
      throw mapDioError(e, fallback: 'Failed to load orders');
    }
  }

  Future<Order> fetchOrder(String orderId) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiEndpoints.order(orderId));
      return Order.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e, fallback: 'Failed to load order');
    }
  }

  Future<Order> cancelOrder(String orderId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.orderCancel(orderId),
      );
      return Order.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e, fallback: 'Failed to cancel order');
    }
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
