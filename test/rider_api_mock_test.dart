import 'package:darkstore/core/constants/order_status.dart';
import 'package:darkstore/placeholders/order_api_mock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late OrderApiMock orders;

  setUp(() {
    orders = OrderApiMock()..resetForTests();
  });

  test('rider only sees orders assigned to them for their store', () {
    final mine = orders.riderOrders(storeId: '1', riderId: '20');
    final items = (mine['items'] as List).cast<Map<String, dynamic>>();
    expect(items, isNotEmpty);
    expect(items.every((o) => o['assignedRiderId'] == '20'), isTrue);
    expect(
      items.every(
        (o) =>
            o['status'] == OrderStatus.assigned ||
            o['status'] == OrderStatus.outForDelivery,
      ),
      isTrue,
    );

    final other = orders.riderOrders(storeId: '1', riderId: '999');
    expect((other['items'] as List), isEmpty);
  });

  test('missing storeId fails clearly', () {
    expect(
      () => orders.riderOrders(storeId: '', riderId: '20'),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('storeId'),
        ),
      ),
    );
  });

  test('rider status transitions and COD amount on assigned order', () {
    final list = orders.riderOrders(storeId: '1', riderId: '20');
    final assigned = (list['items'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((o) => o['status'] == OrderStatus.assigned);
    expect(assigned['codAmount'], greaterThan(0));

    final out = orders.patchRiderStatus(
      orderId: assigned['id'] as String,
      toStatus: OrderStatus.outForDelivery,
      storeId: '1',
      riderId: '20',
    );
    expect(out['status'], OrderStatus.outForDelivery);

    expect(
      () => orders.patchRiderStatus(
        orderId: assigned['id'] as String,
        toStatus: OrderStatus.assigned,
        storeId: '1',
        riderId: '20',
      ),
      throwsA(isA<Exception>()),
    );

    final delivered = orders.patchRiderStatus(
      orderId: assigned['id'] as String,
      toStatus: OrderStatus.delivered,
      storeId: '1',
      riderId: '20',
    );
    expect(delivered['status'], OrderStatus.delivered);
    expect(delivered['paymentStatus'], 'COLLECTED');
  });
}
