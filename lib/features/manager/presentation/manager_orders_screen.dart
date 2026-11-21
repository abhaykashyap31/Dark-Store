import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_role.dart';
import '../../../core/constants/order_status.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/role_shell_scaffold.dart';
import '../application/manager_repository.dart';

class ManagerOrdersScreen extends ConsumerStatefulWidget {
  const ManagerOrdersScreen({super.key});

  @override
  ConsumerState<ManagerOrdersScreen> createState() =>
      _ManagerOrdersScreenState();
}

class _ManagerOrdersScreenState extends ConsumerState<ManagerOrdersScreen> {
  String? _statusFilter;

  static const _filters = <String?>[
    null,
    OrderStatus.confirmed,
    OrderStatus.picking,
    OrderStatus.packed,
    OrderStatus.assigned,
  ];

  @override
  Widget build(BuildContext context) {
    final storeId = ref.watch(managerStoreIdProvider);
    final ordersAsync = ref.watch(managerOrdersProvider(_statusFilter));

    return RoleShellScaffold(
      role: AppRole.manager,
      title: 'Order queue',
      actions: [
        HeaderActionButton(
          icon: Icons.home_outlined,
          label: 'Home',
          onPressed: () => context.go('/manager'),
        ),
      ],
      body: storeId == null
          ? const AppEmptyState(
              title: 'Missing storeId',
              subtitle: 'Cannot load queue without store mapping',
            )
          : Column(
              children: [
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    children: [
                      for (final status in _filters)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              status == null
                                  ? 'All'
                                  : OrderStatus.label(status),
                            ),
                            selected: _statusFilter == status,
                            onSelected: (_) {
                              setState(() => _statusFilter = status);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ordersAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => AppErrorView(
                      message: error.toString(),
                      onRetry: () =>
                          ref.invalidate(managerOrdersProvider(_statusFilter)),
                    ),
                    data: (orders) {
                      // Client-side safety filter (also applied by Gateway mock).
                      final filtered = _statusFilter == null
                          ? orders
                          : orders
                              .where((o) => o.status == _statusFilter)
                              .toList();
                      if (filtered.isEmpty) {
                        return AppEmptyState(
                          title: _statusFilter == null
                              ? 'No orders in this queue'
                              : 'No ${OrderStatus.label(_statusFilter!)} orders',
                          icon: Icons.inbox_outlined,
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(managerOrdersProvider(_statusFilter));
                          await ref.read(
                            managerOrdersProvider(_statusFilter).future,
                          );
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final order = filtered[index];
                            return Card(
                              child: ListTile(
                                title: Text(order.orderNumber),
                                subtitle: Text(
                                  [
                                    OrderStatus.label(order.status),
                                    order.customerName ?? 'Customer',
                                    order.totalLabel,
                                  ].join(' · '),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.go(
                                  '/manager/orders/${order.id}',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
