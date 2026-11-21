import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_role.dart';
import '../../../core/constants/order_status.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/role_shell_scaffold.dart';
import '../application/order_repository.dart';

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return RoleShellScaffold(
      role: AppRole.user,
      title: 'My orders',
      actions: [
        HeaderActionButton(
          icon: Icons.storefront_outlined,
          label: 'Shop',
          onPressed: () => context.go('/user'),
        ),
      ],
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(ordersProvider),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppEmptyState(
                      title: 'No orders yet',
                      subtitle: 'Place an order from the catalog to track it here.',
                      icon: Icons.receipt_long_outlined,
                    ),
                    FilledButton(
                      onPressed: () => context.go('/user/products'),
                      child: const Text('Browse products'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ordersProvider);
              await ref.read(ordersProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final order = orders[index];
                final scheme = Theme.of(context).colorScheme;
                final statusColor = order.isCancelled
                    ? scheme.error
                    : order.canCancel
                        ? scheme.primary
                        : scheme.tertiary;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.15),
                      child: Icon(
                        order.isCancelled
                            ? Icons.cancel_outlined
                            : Icons.local_shipping_outlined,
                        color: statusColor,
                      ),
                    ),
                    title: Text(order.orderNumber),
                    subtitle: Text(
                      [
                        OrderStatus.label(order.status),
                        order.totalLabel,
                        '${order.itemsCount} items',
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/user/orders/${order.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
