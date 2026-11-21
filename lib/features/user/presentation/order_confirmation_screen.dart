import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/shop_shell.dart';
import '../application/order_repository.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return ShopShell(
      showSearch: false,
      cardPadding: const EdgeInsets.all(28),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
        data: (order) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 72,
                  color: AppColors.brandGreen,
                ),
                const SizedBox(height: 12),
                Text(
                  'Order confirmed',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Thanks! Your order is placed.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.muted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${order.orderNumber} · ${order.status}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.softGrey,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Total',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            order.totalLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.brandGreen,
                            ),
                          ),
                        ],
                      ),
                      if (order.paymentMethod != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Payment: ${order.paymentMethod}',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                      if (order.deliveryAddressText != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          order.deliveryAddressText!,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Items',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                for (final item in order.items)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Qty ${item.quantity}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${item.lineTotal.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Status',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final event in order.statusHistory)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.timeline,
                      color: AppColors.brandGreen,
                    ),
                    title: Text(event.toStatus),
                    subtitle: Text(
                      [
                        if (event.changedByRole != null) event.changedByRole!,
                        if (event.note != null) event.note!,
                      ].join(' · '),
                    ),
                  ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final actions = [
                      _ActionTile(
                        icon: Icons.receipt_long_outlined,
                        label: 'My Orders',
                        onTap: () => context.go('/user/orders'),
                      ),
                      _ActionTile(
                        icon: Icons.local_shipping_outlined,
                        label: 'Track Order',
                        emphasized: true,
                        onTap: () =>
                            context.go('/user/orders/${order.id}'),
                      ),
                      _ActionTile(
                        icon: Icons.storefront_outlined,
                        label: 'Back to Shop',
                        onTap: () => context.go('/user'),
                      ),
                    ];

                    if (constraints.maxWidth < 520) {
                      return Column(
                        children: [
                          for (var i = 0; i < actions.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            actions[i],
                          ],
                        ],
                      );
                    }

                    return Row(
                      children: [
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: actions[i]),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final emphasized = widget.emphasized;
    final bg = emphasized
        ? AppColors.brandGreen
        : (_hovered ? const Color(0xFFE8F5E9) : Colors.white);
    final fg = emphasized ? Colors.white : AppColors.brandGreen;
    final border = emphasized
        ? AppColors.brandGreen
        : AppColors.brandGreen.withValues(alpha: 0.35);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandGreen.withValues(
                    alpha: emphasized || _hovered ? 0.18 : 0.08,
                  ),
                  blurRadius: emphasized || _hovered ? 16 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: emphasized
                        ? Colors.white.withValues(alpha: 0.18)
                        : AppColors.brandGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: fg, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: emphasized ? Colors.white : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
