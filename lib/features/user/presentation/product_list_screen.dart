import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/catalog_item_card.dart';
import '../../../shared/widgets/shop_shell.dart';
import '../application/catalog_repository.dart';
import '../application/selected_store_controller.dart';
import 'widgets/product_card.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key, this.categoryId, this.initialQuery});

  final String? categoryId;
  final String? initialQuery;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late String _query;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final selectedStore = ref.watch(selectedStoreProvider);

    if (selectedStore == null) {
      return ShopShell(
        showSearch: false,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppEmptyState(
                title: 'Select a store first',
                subtitle: 'Products are priced per darkstore.',
                icon: Icons.storefront_outlined,
              ),
              FilledButton(
                onPressed: () => context.go('/user/stores'),
                child: const Text('Choose store'),
              ),
            ],
          ),
        ),
      );
    }

    final productsAsync = ref.watch(
      productsProvider((
        storeId: selectedStore.id,
        categoryId: widget.categoryId,
        query: _query.isEmpty ? null : _query,
      )),
    );
    final categories = ref.watch(categoriesProvider).valueOrNull;
    final categoryName = widget.categoryId == null
        ? null
        : categories
            ?.where((c) => c.id == widget.categoryId)
            .map((c) => c.name)
            .firstOrNull;

    return ShopShell(
      initialQuery: _query,
      onSearch: (q) => setState(() => _query = q),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => context.go('/user'),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Home'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName ??
                        (widget.categoryId == null
                            ? 'All products'
                            : 'Category'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  selectedStore.name,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(productsProvider),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return const AppEmptyState(
                    title: 'No products found',
                    subtitle: 'Try another category or search',
                    icon: Icons.inventory_2_outlined,
                  );
                }

                return CatalogCardGrid(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  childAspectRatio: 0.68,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      onTap: () =>
                          context.go('/user/products/${product.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
