import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/product.dart';
import '../../../shared/models/store.dart';

class CatalogRepository {
  CatalogRepository(this._dio);

  final Dio _dio;

  Future<List<Store>> fetchStores() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.stores);
      return parseObjectList(response.data)
          .map(Store.fromJson)
          .where((store) => store.active)
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e, fallback: 'Failed to load stores');
    }
  }

  Future<List<Category>> fetchCategories() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.categories);
      return parseObjectList(response.data).map(Category.fromJson).toList();
    } on DioException catch (e) {
      throw mapDioError(e, fallback: 'Failed to load categories');
    }
  }

  Future<List<Product>> fetchProducts({
    required String storeId,
    String? categoryId,
    String? query,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.products,
        queryParameters: {
          'storeId': storeId,
          if (categoryId != null && categoryId.isNotEmpty)
            'categoryId': categoryId,
          if (query != null && query.isNotEmpty) 'q': query,
        },
      );
      return parseObjectList(response.data).map(Product.fromJson).toList();
    } on DioException catch (e) {
      throw mapDioError(e, fallback: 'Failed to load products');
    }
  }

  Future<Product> fetchProduct({
    required String productId,
    required String storeId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.product(productId),
        queryParameters: {'storeId': storeId},
      );
      return Product.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e, fallback: 'Failed to load product');
    }
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(dioProvider));
});

final storesProvider = FutureProvider.autoDispose<List<Store>>((ref) {
  return ref.watch(catalogRepositoryProvider).fetchStores();
});

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(catalogRepositoryProvider).fetchCategories();
});

final productsProvider = FutureProvider.autoDispose
    .family<List<Product>, ({String storeId, String? categoryId, String? query})>(
  (ref, args) {
    return ref.watch(catalogRepositoryProvider).fetchProducts(
          storeId: args.storeId,
          categoryId: args.categoryId,
          query: args.query,
        );
  },
);

final productDetailProvider = FutureProvider.autoDispose
    .family<Product, ({String productId, String storeId})>((ref, args) {
  return ref.watch(catalogRepositoryProvider).fetchProduct(
        productId: args.productId,
        storeId: args.storeId,
      );
});
