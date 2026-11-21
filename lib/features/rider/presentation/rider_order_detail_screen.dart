import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_role.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/role_shell_scaffold.dart';
import '../../user/presentation/widgets/order_status_timeline.dart';
import '../application/rider_repository.dart';

class RiderOrderDetailScreen extends ConsumerStatefulWidget {
  const RiderOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<RiderOrderDetailScreen> createState() =>
      _RiderOrderDetailScreenState();
}

class _RiderOrderDetailScreenState
    extends ConsumerState<RiderOrderDetailScreen> {
  bool _busy = false;

  Future<void> _advance(String toStatus) async {
    setState(() => _busy = true);
    try {
      await ref.read(riderRepositoryProvider).patchStatus(
            orderId: widget.orderId,
            toStatus: toStatus,
          );
      ref.invalidate(riderOrderDetailProvider(widget.orderId));
      ref.invalidate(riderDeliveriesProvider);
      if (!mounted) return;
      if (toStatus == OrderStatus.delivered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked delivered')),
        );
        context.go('/rider');
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeId = ref.watch(riderStoreIdProvider);
    final orderAsync = ref.watch(riderOrderDetailProvider(widget.orderId));

    return RoleShellScaffold(
      role: AppRole.rider,
      title: 'Delivery',
      maxContentWidth: 720,
      actions: [
        HeaderActionButton(
          icon: Icons.delivery_dining_outlined,
          label: 'Deliveries',
          onPressed: () => context.go('/rider'),
        ),
      ],
      body: storeId == null || storeId.isEmpty
          ? const Center(
              child: Text('Missing storeId — contact an admin.'),
            )
          : orderAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppErrorView(
                message: error.toString(),
                onRetry: () =>
                    ref.invalidate(riderOrderDetailProvider(widget.orderId)),
              ),
              data: (order) {
                final next = OrderStatus.riderNextStatus(order.status);
                final cod = order.codLabel;

                return ListView(
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
                      [
                        OrderStatus.label(order.status),
                        order.customerName ?? 'Customer',
                        order.totalLabel,
                      ].join(' · '),
                    ),
                    if (order.deliveryAddressText != null) ...[
                      const SizedBox(height: 8),
                      Text(order.deliveryAddressText!),
                    ],
                    if (cod != null) ...[
                      const SizedBox(height: 12),
                      Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: ListTile(
                          leading: const Icon(Icons.payments_outlined),
                          title: Text(cod),
                          subtitle: const Text('Collect cash on delivery'),
                        ),
                      ),
                    ] else if (order.paymentMethod != null) ...[
                      const SizedBox(height: 12),
                      Text('Payment: ${order.paymentMethod} (already paid)'),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Items',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final item in order.items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.name),
                        subtitle: Text('× ${item.quantity}'),
                        trailing: Text(
                          '₹${item.lineTotal.toStringAsFixed(0)}',
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Actions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (next != null)
                      FilledButton(
                        onPressed: _busy ? null : () => _advance(next),
                        child: Text(
                          next == OrderStatus.outForDelivery
                              ? 'Start delivery (Out for delivery)'
                              : 'Mark delivered',
                        ),
                      )
                    else
                      Text(
                        'No further rider actions for this status.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Timeline',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    OrderStatusTimeline(order: order),
                  ],
                );
              },
            ),
    );
  }
}
