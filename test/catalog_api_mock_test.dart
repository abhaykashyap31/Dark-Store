import 'package:darkstore/placeholders/catalog_api_mock.dart';
import 'package:darkstore/placeholders/mock_ids.dart';
import 'package:darkstore/shared/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = CatalogApiMock();

  test('products are scoped by store stock and price', () {
    final s1 = catalog.products(storeId: MockIds.storeKoramangala);
    final s2 = catalog.products(storeId: MockIds.storeIndiranagar);

    final milkS1 = (s1['items'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((p) => p['id'] == 'p_100');
    final milkS2 = (s2['items'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((p) => p['id'] == 'p_100');

    expect(milkS1['price'], 55.0);
    expect(milkS2['price'], 58.0);

    final waterS1 = Product.fromJson(
      (s1['items'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((p) => p['id'] == 'p_102'),
    );
    expect(waterS1.inStock, isFalse);
    expect(waterS1.stockQty, 0);
  });

  test('category filter and product detail work', () {
    final dairy = catalog.products(
      storeId: MockIds.defaultStore,
      categoryId: 'c_01',
    );
    final items = (dairy['items'] as List).cast<Map<String, dynamic>>();
    expect(items.every((p) => p['categoryId'] == 'c_01'), isTrue);

    final detail = catalog.productById(
      id: 'p_100',
      storeId: MockIds.defaultStore,
    );
    expect(detail['name'], 'Farm Fresh Milk');
    expect(detail['inStock'], isTrue);
  });

  test('stores expose line1 / postalCode', () {
    final stores = (catalog.stores()['items'] as List)
        .cast<Map<String, dynamic>>();
    expect(stores.first['line1'], isNotEmpty);
    expect(stores.first['postalCode'], isNotEmpty);
  });
}
