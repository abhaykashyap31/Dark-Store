import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/catalog_item_card.dart';
import '../../application/cart_repository.dart';
import '../../application/selected_store_controller.dart';

Future<void> showCartPreviewCard(BuildContext context) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (dialogContext) => const Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: CartPreviewCard(),
    ),
  );
}

class CartPreviewCard extends ConsumerStatefulWidget {
  const CartPreviewCard({super.key});

  @override
  ConsumerState<CartPreviewCard> createState() => _CartPreviewCardState();
}

class _CartPreviewCardState extends ConsumerState<CartPreviewCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(cartProvider);
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

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final store = ref.watch(selectedStoreProvider);
    final screen = MediaQuery.sizeOf(context);
    final cardWidth = screen.width > 960 ? 920.0 : screen.width - 48;
    final cardHeight = screen.height * 0.78;

    return Material(
      color: Colors.white,
      elevation: 12,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: cartAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(error.toString()),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(cartProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (cart) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Cart',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              store == null
                                  ? '${cart.itemsCount} items'
                                  : '${cart.itemsCount} items · ${store.name}',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (cart.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shopping_cart_outlined,
                              size: 48,
                              color: AppColors.muted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your cart is empty',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add products from the catalog to continue.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.go('/user/products');
                              },
                              child: const Text('Browse products'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.softGrey,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  catalogIconForName(item.productName),
                                  color: AppColors.brandGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.priceLabel,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.brandGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _run(() async {
                                              await ref
                                                  .read(cartRepositoryProvider)
                                                  .updateItem(
                                                    itemId: item.id,
                                                    quantity:
                                                        item.quantity - 1,
                                                  );
                                            }),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _run(() async {
                                              await ref
                                                  .read(cartRepositoryProvider)
                                                  .updateItem(
                                                    itemId: item.id,
                                                    quantity:
                                                        item.quantity + 1,
                                                  );
                                            }),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                  IconButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _run(() async {
                                              await ref
                                                  .read(cartRepositoryProvider)
                                                  .removeItem(itemId: item.id);
                                            }),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Subtotal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              cart.subtotalLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                  context.go('/user/checkout');
                                },
                          child: const Text('Checkout'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
