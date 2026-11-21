import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/cart.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/widgets/catalog_item_card.dart';
import '../../application/cart_repository.dart';
import '../../application/selected_store_controller.dart';

class ProductCard extends ConsumerStatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.width,
  });

  final Product product;
  final VoidCallback onTap;
  final double? width;

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(cartProvider);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addOne(Cart? cart) async {
    final store = ref.read(selectedStoreProvider);
    if (store == null || !widget.product.inStock) return;

    final existing = cart?.itemForProduct(widget.product.id);
    if (existing != null) {
      await _run(() async {
        await ref.read(cartRepositoryProvider).updateItem(
              itemId: existing.id,
              quantity: existing.quantity + 1,
            );
      });
      return;
    }

    await _run(() async {
      await ref.read(cartRepositoryProvider).addItem(
            productId: widget.product.id,
            storeId: store.id,
          );
    });
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
    final product = widget.product;
    final outOfStock = !product.inStock;
    final cart = ref.watch(cartProvider).valueOrNull;
    final cartItem = cart?.itemForProduct(product.id);
    final quantity = cartItem?.quantity ?? 0;

    return CatalogItemCard(
      width: widget.width,
      title: product.name,
      priceLabel: product.priceLabel,
      subtitle: product.unit ?? product.sku,
      badge: outOfStock ? 'Sold out' : '10 MINS',
      badgeColor: outOfStock ? const Color(0xFFFFCDD2) : AppColors.softGrey,
      onTap: widget.onTap,
      footer: outOfStock
          ? Text(
              'Unavailable',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            )
          : GestureDetector(
              onTap: () {}, // keep card navigation from stealing control taps
              child: Row(
                children: [
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _addOne(cart),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                      ),
                      child: _busy && quantity == 0
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('ADD'),
                    ),
                  ),
                  if (quantity > 0) ...[
                    const SizedBox(width: 8),
                    _QtyStepper(
                      quantity: quantity,
                      busy: _busy,
                      onDecrement: cartItem == null
                          ? null
                          : () => _setQuantity(cartItem, quantity - 1),
                      onIncrement: cartItem == null
                          ? null
                          : () => _setQuantity(cartItem, quantity + 1),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.quantity,
    required this.busy,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final bool busy;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.brandGreen, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove,
            onPressed: busy ? null : onDecrement,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$quantity',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.brandGreen,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            onPressed: busy ? null : onIncrement,
          ),
        ],
      ),
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
      width: 28,
      height: 32,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        iconSize: 16,
        color: AppColors.brandGreen,
        icon: Icon(icon),
      ),
    );
  }
}
