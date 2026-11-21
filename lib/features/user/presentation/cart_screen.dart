import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/catalog_item_card.dart';
import '../../../shared/widgets/shop_shell.dart';
import '../application/cart_repository.dart';
import '../application/selected_store_controller.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(cartProvider);
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
    final cartAsync = ref.watch(cartProvider);
    final store = ref.watch(selectedStoreProvider);

    return ShopShell(
      showSearch: false,
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(cartProvider),
        ),
        data: (cart) {
          if (cart.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppEmptyState(
                      title: 'Your cart is empty',
                      subtitle: 'Add products from the catalog to continue.',
                      icon: Icons.shopping_cart_outlined,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => context.go('/user/products'),
                      child: const Text('Browse products'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              if (store != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Store: ${store.name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.softGrey,
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.priceLabel,
                                    style: const TextStyle(
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
                                                  quantity: item.quantity - 1,
                                                );
                                          }),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text('${item.quantity}'),
                                IconButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _run(() async {
                                            await ref
                                                .read(cartRepositoryProvider)
                                                .updateItem(
                                                  itemId: item.id,
                                                  quantity: item.quantity + 1,
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
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Subtotal',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(
                            cart.subtotalLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : () => context.go('/user/checkout'),
                        child: const Text('Checkout'),
                      ),
                    ],
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
