import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/user/application/cart_repository.dart';
import '../../features/user/application/selected_store_controller.dart';
import '../../features/user/presentation/widgets/cart_preview_card.dart';
import '../../shared/models/store.dart';
import 'brand_logo.dart';

class ShopWebHeader extends ConsumerStatefulWidget {
  const ShopWebHeader({
    super.key,
    this.initialQuery,
    this.onSearch,
    this.showSearch = true,
  });

  final String? initialQuery;
  final ValueChanged<String>? onSearch;
  final bool showSearch;

  @override
  ConsumerState<ShopWebHeader> createState() => _ShopWebHeaderState();
}

class _ShopWebHeaderState extends ConsumerState<ShopWebHeader> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery ?? '');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openProfile() {
    // Use go (not push) so we never keep a broken prior overlay/route frame.
    GoRouter.of(context).go('/user/profile');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final store = ref.watch(selectedStoreProvider);
    final cartCount = ref.watch(cartProvider).maybeWhen(
          data: (cart) => cart.itemsCount,
          orElse: () => 0,
        );
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 900;
    final firstName = (user?.name ?? '').trim().split(' ').first;

    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      elevation: 1.5,
      shadowColor: Colors.black12,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 28,
            vertical: 12,
          ),
          child: compact
              ? Column(
                  children: [
                    Row(
                      children: [
                        BrandLogo(
                          fontSize: 24,
                          onTap: () => context.go('/user'),
                        ),
                        const Spacer(),
                        _HeaderLink(
                          icon: Icons.person_outline,
                          label: firstName.isEmpty ? 'Profile' : firstName,
                          onTap: _openProfile,
                        ),
                        const SizedBox(width: 8),
                        _CartButton(count: cartCount),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _LocationChip(store: store),
                    if (widget.showSearch) ...[
                      const SizedBox(height: 10),
                      _SearchField(
                        controller: _search,
                        onSubmitted: (q) {
                          if (widget.onSearch != null) {
                            widget.onSearch!(q);
                          } else {
                            context.go(
                              '/user/products${q.isEmpty ? '' : '?q=${Uri.encodeQueryComponent(q)}'}',
                            );
                          }
                        },
                      ),
                    ],
                  ],
                )
              : Row(
                  children: [
                    BrandLogo(
                      fontSize: 26,
                      onTap: () => context.go('/user'),
                    ),
                    const SizedBox(width: 20),
                    _LocationChip(store: store),
                    const SizedBox(width: 20),
                    if (widget.showSearch)
                      Expanded(
                        child: _SearchField(
                          controller: _search,
                          onSubmitted: (q) {
                            if (widget.onSearch != null) {
                              widget.onSearch!(q);
                            } else {
                              context.go(
                                '/user/products${q.isEmpty ? '' : '?q=${Uri.encodeQueryComponent(q)}'}',
                              );
                            }
                          },
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 12),
                    _HeaderLink(
                      icon: Icons.receipt_long_outlined,
                      label: 'Orders',
                      onTap: () => context.go('/user/orders'),
                    ),
                    const SizedBox(width: 8),
                    _HeaderLink(
                      icon: Icons.person_outline,
                      label: firstName.isEmpty ? 'Profile' : firstName,
                      onTap: _openProfile,
                    ),
                    const SizedBox(width: 8),
                    _CartButton(count: cartCount),
                    const SizedBox(width: 10),
                    _HeaderLink(
                      icon: Icons.logout,
                      label: 'Logout',
                      onTap: () =>
                          ref.read(authControllerProvider.notifier).logout(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeaderLink extends StatelessWidget {
  const _HeaderLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppColors.brandGreen),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.store});

  final Store? store;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/user/stores'),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delivery in 10 minutes',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 18),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                store == null
                    ? 'Select a darkstore'
                    : '${store!.name}, ${store!.city}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (value) => onSubmitted(value.trim()),
      decoration: InputDecoration(
        hintText: 'Search "milk"',
        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.muted),
        prefixIcon: const Icon(Icons.search, color: AppColors.muted),
        filled: true,
        fillColor: AppColors.softGrey,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: count > 0 ? AppColors.brandGreen : AppColors.softGrey,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => showCartPreviewCard(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 18,
                color: count > 0 ? Colors.white : AppColors.ink,
              ),
              const SizedBox(width: 8),
              Text(
                count > 0 ? 'My Cart ($count)' : 'My Cart',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: count > 0 ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
