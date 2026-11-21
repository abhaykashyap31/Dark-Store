import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_role.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/role_shell_scaffold.dart';
import '../application/order_repository.dart';
import 'widgets/order_status_timeline.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _cancelling = false;

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text(
          'You can cancel only before packing starts (CREATED / CONFIRMED).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(orderRepositoryProvider).cancelOrder(widget.orderId);
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(ordersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return RoleShellScaffold(
      role: AppRole.user,
      title: 'Order tracking',
      actions: [
        HeaderActionButton(
          icon: Icons.storefront_outlined,
          label: 'Shop',
          onPressed: () => context.go('/user'),
        ),
      ],
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
        data: (order) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(orderDetailProvider(widget.orderId));
              await ref.read(orderDetailProvider(widget.orderId).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  order.orderNumber,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  OrderStatus.label(order.status),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: Text(order.totalLabel),
                    subtitle: Text(
                      [
                        if (order.paymentMethod != null)
                          'Payment: ${order.paymentMethod}',
                        if (order.deliveryAddressText != null)
                          order.deliveryAddressText!,
                      ].join('\n'),
                    ),
                    isThreeLine: order.deliveryAddressText != null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tracking',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                OrderStatusTimeline(order: order),
                const SizedBox(height: 16),
                Text(
                  'Items',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final item in order.items)
                  Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text('Qty ${item.quantity}'),
                      trailing: Text('₹${item.lineTotal.toStringAsFixed(0)}'),
                    ),
                  ),
                const SizedBox(height: 20),
                if (order.canCancel)
                  OutlinedButton.icon(
                    onPressed: _cancelling ? null : _cancelOrder,
                    icon: _cancelling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel order'),
                  )
                else if (!order.isCancelled)
                  Text(
                    'Cancel is unavailable after packing starts.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
