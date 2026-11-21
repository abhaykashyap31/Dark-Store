import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_role.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/role_shell_scaffold.dart';
import '../../user/presentation/widgets/order_status_timeline.dart';
import '../application/manager_repository.dart';

class ManagerOrderDetailScreen extends ConsumerStatefulWidget {
  const ManagerOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<ManagerOrderDetailScreen> createState() =>
      _ManagerOrderDetailScreenState();
}

class _ManagerOrderDetailScreenState
    extends ConsumerState<ManagerOrderDetailScreen> {
  bool _busy = false;

  Future<void> _advance(String toStatus) async {
    final storeId = ref.read(managerStoreIdProvider);
    if (storeId == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(managerRepositoryProvider).patchStatus(
            orderId: widget.orderId,
            toStatus: toStatus,
            storeId: storeId,
          );
      ref.invalidate(managerOrderDetailProvider(widget.orderId));
      ref.invalidate(managerOrdersProvider);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _assignRider(List<AppUser> riders) async {
    if (riders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active riders for this store')),
      );
      return;
    }

    final storeId = ref.read(managerStoreIdProvider);
    if (storeId == null) return;

    final selected = await showDialog<AppUser>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Assign rider'),
        children: [
          for (final rider in riders)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, rider),
              child: Text('${rider.name} (${rider.email})'),
            ),
        ],
      ),
    );
    if (selected == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(managerRepositoryProvider).assignRider(
            orderId: widget.orderId,
            storeId: storeId,
            riderId: selected.id,
          );
      ref.invalidate(managerOrderDetailProvider(widget.orderId));
      ref.invalidate(managerOrdersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned to ${selected.name}')),
      );
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
    final orderAsync = ref.watch(managerOrderDetailProvider(widget.orderId));
    final ridersAsync = ref.watch(managerRidersProvider);

    return RoleShellScaffold(
      role: AppRole.manager,
      title: 'Order',
      actions: [
        IconButton(
          tooltip: 'Queue',
          onPressed: () => context.go('/manager/orders'),
          icon: const Icon(Icons.arrow_back),
        ),
      ],
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(managerOrderDetailProvider(widget.orderId)),
        ),
        data: (order) {
          final next = OrderStatus.managerNextStatus(order.status);
          final canAssign = OrderStatus.canAssignRider(order.status);
          final riders = ridersAsync.valueOrNull ?? const <AppUser>[];

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
              const SizedBox(height: 16),
              Text(
                'Actions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (next != null)
                FilledButton(
                  onPressed: _busy ? null : () => _advance(next),
                  child: Text('Mark ${OrderStatus.label(next)}'),
                )
              else if (canAssign)
                FilledButton.icon(
                  onPressed: _busy ? null : () => _assignRider(riders),
                  icon: const Icon(Icons.delivery_dining_outlined),
                  label: const Text('Assign rider'),
                )
              else
                Text(
                  'No manager actions for ${OrderStatus.label(order.status)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 20),
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
              for (final item in order.items)
                Card(
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text('Qty ${item.quantity}'),
                    trailing: Text('₹${item.lineTotal.toStringAsFixed(0)}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
