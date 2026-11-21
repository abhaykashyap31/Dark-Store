import 'package:darkstore/core/constants/order_status.dart';
import 'package:darkstore/placeholders/order_api_mock.dart';
import 'package:darkstore/shared/models/order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late OrderApiMock orders;

  setUp(() {
    orders = OrderApiMock()..resetForTests();
  });

  test('timeline seed orders cover cancelable and non-cancelable states', () {
    final confirmed = Order.fromJson(orders.orderById('o_500'));
    final picking = Order.fromJson(orders.orderById('o_510'));
    final out = Order.fromJson(orders.orderById('o_520'));

    expect(confirmed.canCancel, isTrue);
    expect(picking.canCancel, isFalse);
    expect(out.canCancel, isFalse);

    expect(
      out.statusHistory.map((e) => e.toStatus),
      containsAll([
        OrderStatus.created,
        OrderStatus.confirmed,
        OrderStatus.picking,
        OrderStatus.packed,
        OrderStatus.assigned,
        OrderStatus.outForDelivery,
      ]),
    );
  });

  test('cancel allowed only before packing', () {
    final cancelled = Order.fromJson(orders.cancelOrder('o_500'));
    expect(cancelled.status, OrderStatus.cancelled);
    expect(cancelled.canCancel, isFalse);
    expect(
      cancelled.statusHistory.last.toStatus,
      OrderStatus.cancelled,
    );

    expect(
      () => orders.cancelOrder('o_510'),
      throwsA(isA<Exception>()),
    );
  });
}
