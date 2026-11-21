import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/cart.dart';
import '../../auth/application/auth_controller.dart';
import 'selected_store_controller.dart';

class CartRepository {
  CartRepository(this._dio);

  final Dio _dio;

  Future<Cart> fetchCart({String? storeId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.cart,
        queryParameters: {
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );
      return Cart.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw _error(e, 'Failed to load cart');
    }
  }

  Future<Cart> addItem({
    required String productId,
    required String storeId,
    int quantity = 1,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.cartItems,
        data: {
          'productId': productId,
          'storeId': storeId,
          'quantity': quantity,
        },
      );
      return Cart.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw _error(e, 'Failed to add item');
    }
  }

  Future<Cart> updateItem({
    required String itemId,
    required int quantity,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.cartItem(itemId),
        data: {'quantity': quantity},
      );
      return Cart.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw _error(e, 'Failed to update cart item');
    }
  }

  Future<Cart> removeItem({required String itemId}) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.cartItem(itemId),
      );
      return Cart.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw _error(e, 'Failed to remove cart item');
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

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(dioProvider));
});

final cartProvider = FutureProvider.autoDispose<Cart>((ref) async {
  ref.watch(authControllerProvider);
  final storeId = ref.watch(selectedStoreProvider)?.id;
  return ref.watch(cartRepositoryProvider).fetchCart(storeId: storeId);
});
