import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_role.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/user/application/cart_repository.dart';
import '../../features/user/presentation/widgets/cart_preview_card.dart';
import '../../shared/models/app_user.dart';
import 'brand_backdrop.dart';
import 'brand_logo.dart';
import 'page_surface_card.dart';

class RoleShellScaffold extends ConsumerWidget {
  const RoleShellScaffold({
    super.key,
    required this.role,
    required this.title,
    required this.body,
    this.actions,
    this.wrapInCard = true,
    this.maxContentWidth = 1480,
  });

  final AppRole role;
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool wrapInCard;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final cartCount = role == AppRole.user
        ? ref.watch(cartProvider).maybeWhen(
              data: (cart) => cart.itemsCount,
              orElse: () => 0,
            )
        : 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.86),
        title: Row(
          children: [
            BrandLogo(
              fontSize: 20,
              onTap: () => context.go(role.homePath),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (actions != null) ...[
            for (final action in actions!) ...[
              action,
              const SizedBox(width: 8),
            ],
          ],
          if (role == AppRole.user) ...[
            HeaderActionButton(
              icon: Icons.receipt_long_outlined,
              label: 'My Orders',
              onPressed: () => context.go('/user/orders'),
            ),
            const SizedBox(width: 8),
            HeaderActionButton(
              icon: Icons.shopping_cart_outlined,
              label: cartCount > 0 ? 'Cart ($cartCount)' : 'Cart',
              onPressed: () => showCartPreviewCard(context),
            ),
            const SizedBox(width: 8),
          ],
          HeaderActionButton(
            icon: Icons.person_outline,
            label: 'Profile',
            onPressed: () => context.go('${role.homePath}/profile'),
          ),
          const SizedBox(width: 8),
          HeaderActionButton(
            icon: Icons.logout,
            label: 'Logout',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: BrandBackdrop(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SessionBanner(role: role, user: user),
            Expanded(
              child: wrapInCard
                  ? PageSurfaceCard(
                      maxWidth: maxContentWidth,
                      padding: EdgeInsets.zero,
                      child: body,
                    )
                  : body,
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon + label action used in role shell headers.
class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(0, 40),
        ),
        icon: Icon(icon, size: 20, color: AppColors.brandGreen),
        label: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SessionBanner extends StatelessWidget {
  const _SessionBanner({required this.role, required this.user});

  final AppRole role;
  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.7),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.badge_outlined, color: AppColors.brandGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                [
                  user?.name ?? role.label,
                  role.apiValue,
                  if (user?.storeId != null) 'store ${user!.storeId}',
                  if (AppConfig.useMockApis) 'MOCK',
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
