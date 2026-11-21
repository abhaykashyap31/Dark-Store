import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/category.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/shop_shell.dart';
import '../application/catalog_repository.dart';
import '../application/selected_store_controller.dart';
import 'widgets/product_card.dart';

class UserHomeScreen extends ConsumerWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStore = ref.watch(selectedStoreProvider);
    final storesAsync = ref.watch(storesProvider);

    // Auto-pick first active store for a Blinkit-like first visit.
    ref.listen(storesProvider, (prev, next) {
      next.whenData((stores) {
        if (ref.read(selectedStoreProvider) == null && stores.isNotEmpty) {
          ref.read(selectedStoreProvider.notifier).select(stores.first);
        }
      });
    });

    if (selectedStore == null) {
      return ShopShell(
        showSearch: false,
        body: Center(
          child: storesAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => AppErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(storesProvider),
            ),
            data: (_) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppEmptyState(
                    title: 'Pick a store to start shopping',
                    subtitle: 'Catalog prices and stock are per darkstore.',
                    icon: Icons.storefront_outlined,
                  ),
                  FilledButton(
                    onPressed: () => context.go('/user/stores'),
                    child: const Text('Choose store'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final categoriesAsync = ref.watch(categoriesProvider);

    return ShopShell(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(productsProvider);
          await ref.read(categoriesProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            const _HeroBanner(),
            const SizedBox(height: 20),
            const _PromoRow(),
            const SizedBox(height: 28),
            categoriesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => AppErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(categoriesProvider),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return const AppEmptyState(
                    title: 'No categories',
                    icon: Icons.category_outlined,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shop by category',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CategoryStrip(categories: categories),
                    const SizedBox(height: 28),
                    for (final category in categories) ...[
                      _CategoryProductRow(
                        category: category,
                        storeId: selectedStore.id,
                      ),
                      const SizedBox(height: 28),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.heroGreen, Color(0xFF14944A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.eco,
              size: 200,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock up on daily essentials',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Text(
                      'Farm-fresh dairy, snacks, drinks & more — delivered from your nearest darkstore.',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: () => context.go('/user/products'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.ink,
                        minimumSize: const Size(120, 42),
                      ),
                      child: const Text('Shop now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoTile {
  const _PromoTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.categoryId,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final String categoryId;
}

class _PromoRow extends StatelessWidget {
  const _PromoRow();

  static const tiles = <_PromoTile>[
    _PromoTile(
      title: 'Snacks at your door',
      subtitle: 'Crispy munchies in minutes',
      color: AppColors.promoAmber,
      icon: Icons.cookie_outlined,
      categoryId: 'c_02', // Snacks & Munchies
    ),
    _PromoTile(
      title: 'Chilled drinks',
      subtitle: 'Colas, water & more',
      color: AppColors.promoTeal,
      icon: Icons.local_cafe_outlined,
      categoryId: 'c_03', // Cold Drinks & Juices
    ),
    _PromoTile(
      title: 'Fresh produce',
      subtitle: 'Fruits & veggies daily',
      color: AppColors.promoSky,
      icon: Icons.eco_outlined,
      categoryId: 'c_04', // Fruits & Vegetables
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 800;
        final children = [
          for (final tile in tiles)
            Expanded(
              child: _PromoCard(tile: tile),
            ),
        ];
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                children[i],
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              SizedBox(
                height: 110,
                child: _PromoCard(tile: tiles[i]),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.tile});

  final _PromoTile tile;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tile.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.go(
          '/user/products?categoryId=${tile.categoryId}',
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 88,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tile.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tile.subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.ink.withValues(alpha: 0.75),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Order now →',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.brandGreenDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  tile.icon,
                  size: 42,
                  color: AppColors.ink.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.categories});

  final List<Category> categories;

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('dairy') || n.contains('bread')) {
      return Icons.breakfast_dining_outlined;
    }
    if (n.contains('snack')) return Icons.cookie_outlined;
    if (n.contains('drink') || n.contains('juice')) {
      return Icons.local_drink_outlined;
    }
    if (n.contains('fruit') || n.contains('veg')) return Icons.eco_outlined;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          return SizedBox(
            width: 120,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.go(
                  '/user/products?categoryId=${category.id}',
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.softGrey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _iconFor(category.name),
                            size: 40,
                            color: AppColors.brandGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryProductRow extends ConsumerWidget {
  const _CategoryProductRow({
    required this.category,
    required this.storeId,
  });

  final Category category;
  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(
      productsProvider((
        storeId: storeId,
        categoryId: category.id,
        query: null,
      )),
    );

    return productsAsync.when(
      loading: () => const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(
                    '/user/products?categoryId=${category.id}',
                  ),
                  child: Text(
                    'see all',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 290,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    width: 180,
                    onTap: () => context.go('/user/products/${product.id}'),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
