import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_role.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/catalog_item_card.dart';
import '../../../shared/widgets/role_shell_scaffold.dart';
import '../application/manager_repository.dart';

class ManagerAlertsScreen extends ConsumerWidget {
  const ManagerAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeId = ref.watch(managerStoreIdProvider);
    final alertsAsync = ref.watch(managerAlertsProvider);

    return RoleShellScaffold(
      role: AppRole.manager,
      title: 'Low-stock alerts',
      actions: [
        HeaderActionButton(
          icon: Icons.inventory_2_outlined,
          label: 'Stock',
          onPressed: () => context.go('/manager/inventory'),
        ),
        HeaderActionButton(
          icon: Icons.add,
          label: 'Add Product',
          onPressed: () => context.go('/manager/inventory?add=1'),
        ),
      ],
      body: storeId == null
          ? const AppEmptyState(
              title: 'Missing storeId',
              subtitle: 'Alerts are scoped to your store mapping',
            )
          : alertsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(managerAlertsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppEmptyState(
                            title: 'No low-stock items',
                            subtitle:
                                'All tracked SKUs are above threshold',
                            icon: Icons.check_circle_outline,
                          ),
                          FilledButton.icon(
                            onPressed: () =>
                                context.go('/manager/inventory'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Product in Stock'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(managerAlertsProvider);
                    await ref.read(managerAlertsProvider.future);
                  },
                  child: CatalogCardGrid(
                    childAspectRatio: 0.78,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return CatalogItemCard(
                        title: item.name,
                        priceLabel: item.priceLabel,
                        subtitle:
                            'qty ${item.quantityOnHand} · threshold ${item.lowStockThreshold}',
                        badge: 'LOW STOCK',
                        badgeColor: const Color(0xFFFFE0E0),
                        onTap: () => context.go('/manager/inventory'),
                        footer: Text(
                          'Open Stock & prices to restock',
                          style: Theme.of(context).textTheme.bodySmall,
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
