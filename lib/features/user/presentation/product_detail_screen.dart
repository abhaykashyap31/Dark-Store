import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/cart.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/catalog_item_card.dart';
import '../../../shared/widgets/shop_shell.dart';
import '../application/cart_repository.dart';
import '../application/catalog_repository.dart';
import '../application/selected_store_controller.dart';
import 'widgets/cart_preview_card.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? successMessage}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(cartProvider);
      if (!mounted || successMessage == null) return;
      final messenger = ScaffoldMessenger.of(context);
      final pageContext = context;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(successMessage),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View cart',
            onPressed: () {
              // Wait for snackbar dismiss so the cart dialog can present.
              Future<void>.delayed(const Duration(milliseconds: 50), () {
                if (!pageContext.mounted) return;
                showCartPreviewCard(pageContext);
              });
            },
          ),
        ),
      );
      // Force dismiss after 4s (a11y / action snackbars can otherwise linger).
      Future<void>.delayed(const Duration(seconds: 4), () {
        if (!mounted) return;
        messenger.hideCurrentSnackBar();
      });
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addOne(Cart? cart) async {
    final store = ref.read(selectedStoreProvider);
    if (store == null) return;

    final existing = cart?.itemForProduct(widget.productId);
    if (existing != null) {
      await _run(() async {
        await ref.read(cartRepositoryProvider).updateItem(
              itemId: existing.id,
              quantity: existing.quantity + 1,
            );
      });
      return;
    }

    await _run(
      () async {
        await ref.read(cartRepositoryProvider).addItem(
              productId: widget.productId,
              storeId: store.id,
            );
      },
      successMessage: 'Added to Cart',
    );
  }

  Future<void> _setQuantity(CartItem item, int quantity) async {
    await _run(() async {
      if (quantity <= 0) {
        await ref.read(cartRepositoryProvider).removeItem(itemId: item.id);
      } else {
        await ref.read(cartRepositoryProvider).updateItem(
              itemId: item.id,
              quantity: quantity,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedStore = ref.watch(selectedStoreProvider);

    if (selectedStore == null) {
      return ShopShell(
        showSearch: false,
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/user/stores'),
            child: const Text('Choose a store'),
          ),
        ),
      );
    }

    final productAsync = ref.watch(
      productDetailProvider((
        productId: widget.productId,
        storeId: selectedStore.id,
      )),
    );
    final cart = ref.watch(cartProvider).valueOrNull;
    final cartItem = cart?.itemForProduct(widget.productId);
    final quantity = cartItem?.quantity ?? 0;

    return ShopShell(
      showSearch: false,
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(productDetailProvider),
        ),
        data: (product) {
          final outOfStock = !product.inStock;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go('/user/products'),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back to catalog'),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 720;
                      final image = Container(
                        height: wide ? 280 : 200,
                        width: wide ? 280 : double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.softGrey,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          catalogIconForName(product.name),
                          size: 88,
                          color: AppColors.brandGreen,
                        ),
                      );

                      final details = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.priceLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandGreen,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            [
                              if (product.unit != null) product.unit!,
                              'SKU ${product.sku}',
                              selectedStore.name,
                            ].join(' · '),
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (outOfStock)
                            Card(
                              color: const Color(0xFFFFEBEE),
                              child: const ListTile(
                                leading: Icon(
                                  Icons.error_outline,
                                  color: Colors.redAccent,
                                ),
                                title: Text('Out of stock at this store'),
                              ),
                            )
                          else
                            Text(
                              '${product.stockQty} available',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            product.description?.isNotEmpty == true
                                ? product.description!
                                : 'No description available.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (outOfStock)
                            FilledButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.block),
                              label: const Text('Unavailable'),
                            )
                          else if (quantity == 0)
                            FilledButton.icon(
                              onPressed: _busy ? null : () => _addOne(cart),
                              icon: _busy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.add_shopping_cart_outlined),
                              label: const Text('Add to cart'),
                            )
                          else
                            _DetailQtyStepper(
                              quantity: quantity,
                              busy: _busy,
                              maxQty: product.stockQty,
                              onDecrement: cartItem == null
                                  ? null
                                  : () => _setQuantity(
                                        cartItem,
                                        quantity - 1,
                                      ),
                              onIncrement: cartItem == null ||
                                      quantity >= product.stockQty
                                  ? null
                                  : () => _setQuantity(
                                        cartItem,
                                        quantity + 1,
                                      ),
                            ),
                        ],
                      );

                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            image,
                            const SizedBox(width: 28),
                            Expanded(child: details),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          image,
                          const SizedBox(height: 20),
                          details,
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailQtyStepper extends StatelessWidget {
  const _DetailQtyStepper({
    required this.quantity,
    required this.busy,
    required this.maxQty,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final bool busy;
  final int maxQty;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.brandGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brandGreen, width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepButton(
                icon: Icons.remove,
                onPressed: busy ? null : onDecrement,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48),
                child: Center(
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          '$quantity',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.brandGreen,
                          ),
                        ),
                ),
              ),
              _StepButton(
                icon: Icons.add,
                onPressed: busy ? null : onIncrement,
              ),
            ],
          ),
        ),
        if (quantity >= maxQty) ...[
          const SizedBox(height: 8),
          Text(
            'Max stock reached',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: onPressed,
        iconSize: 22,
        color: AppColors.brandGreen,
        icon: Icon(icon),
      ),
    );
  }
}
