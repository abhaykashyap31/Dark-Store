import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_role.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/role_shell_scaffold.dart';
import '../../auth/application/auth_controller.dart';
import '../application/rider_repository.dart';

class RiderHomeScreen extends ConsumerWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final storeId = ref.watch(riderStoreIdProvider);
    final deliveriesAsync = ref.watch(riderDeliveriesProvider);

    return RoleShellScaffold(
      role: AppRole.rider,
      title: 'Deliveries',
      maxContentWidth: 720,
      body: storeId == null || storeId.isEmpty
          ? const AppEmptyState(
              title: 'Missing storeId',
              subtitle:
                  'Your rider account has no store mapping. Contact an admin.',
              icon: Icons.store_mall_directory_outlined,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Text(
                    'Welcome${user != null ? ', ${user.name}' : ''}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Store $storeId · Assigned → Out for delivery → Delivered',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: deliveriesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => AppErrorView(
                      message: error.toString(),
                      onRetry: () =>
                          ref.invalidate(riderDeliveriesProvider),
                    ),
                    data: (orders) {
                      if (orders.isEmpty) {
                        return const AppEmptyState(
                          title: 'No active deliveries',
                          subtitle:
                              'Packed orders assigned to you appear here',
                          icon: Icons.delivery_dining_outlined,
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(riderDeliveriesProvider);
                          await ref.read(riderDeliveriesProvider.future);
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                          itemCount: orders.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return _DeliveryCard(order: orders[index]);
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

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final cod = order.codLabel;

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/rider/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delivery_dining_outlined,
                  size: 20,
                  color: AppColors.brandGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.orderNumber,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softGrey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            OrderStatus.label(order.status),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.customerName ?? 'Customer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (order.deliveryAddressText != null &&
                        order.deliveryAddressText!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        order.deliveryAddressText!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.muted,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${order.itemsCount} items · ${order.totalLabel}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        Text(
                          cod ?? 'Paid',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: cod != null
                                ? AppColors.brandGreen
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                children: [
                  Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: AppColors.brandGreen.withValues(alpha: 0.85),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Open',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
