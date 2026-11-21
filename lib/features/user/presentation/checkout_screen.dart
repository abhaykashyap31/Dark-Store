import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/address.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../../shared/widgets/shop_shell.dart';
import '../application/cart_repository.dart';
import '../application/order_repository.dart';
import '../application/selected_store_controller.dart';
import 'widgets/address_editor_dialog.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? _selectedAddressId;
  String _paymentMethod = 'COD';
  bool _submitting = false;
  String? _formError;

  Future<void> _placeOrder() async {
    final cart = await ref.read(cartProvider.future);
    if (cart.isEmpty) {
      setState(() => _formError = 'Cart is empty');
      return;
    }

    final addresses = await ref.read(addressesProvider.future);
    final addressId = _selectedAddressId ??
        (addresses.isEmpty
            ? null
            : addresses
                .firstWhere(
                  (a) => a.defaultAddress,
                  orElse: () => addresses.first,
                )
                .id);
    if (addressId == null || addressId.isEmpty) {
      setState(() => _formError = 'Select a delivery address');
      return;
    }

    setState(() {
      _submitting = true;
      _formError = null;
    });

    try {
      final order = await ref.read(orderRepositoryProvider).placeOrder(
            addressId: addressId,
            paymentMethod: _paymentMethod,
          );
      ref.invalidate(cartProvider);
      if (!mounted) return;
      context.go('/user/orders/${order.id}/confirmation');
    } catch (e) {
      setState(() {
        _formError = e is ApiException ? e.message : e.toString();
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showAddAddressSheet() async {
    final draft = await showAddressEditorDialog(context);
    if (draft == null || !mounted) return;

    try {
      final created = await ref.read(orderRepositoryProvider).addAddress(draft);
      ref.invalidate(addressesProvider);
      setState(() => _selectedAddressId = created.id);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final addressesAsync = ref.watch(addressesProvider);
    final store = ref.watch(selectedStoreProvider);

    return ShopShell(
      showSearch: false,
      cardPadding: const EdgeInsets.all(24),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(cartProvider),
        ),
        data: (cart) {
          if (cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppEmptyState(
                    title: 'Cart is empty',
                    subtitle: 'Add items before checkout.',
                    icon: Icons.remove_shopping_cart_outlined,
                  ),
                  FilledButton(
                    onPressed: () => context.go('/user/products'),
                    child: const Text('Browse products'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Checkout',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () =>
                                        context.go('/user/products'),
                                    icon: const Icon(Icons.arrow_back, size: 18),
                                    label: const Text('Continue shopping'),
                                  ),
                                ],
                              ),
                              if (store != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Delivering from ${store.name}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              Text(
                                'Order summary',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.softGrey,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: [
                                    for (final item in cart.items)
                                      ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(item.productName),
                                        subtitle:
                                            Text('Qty ${item.quantity}'),
                                        trailing: Text(item.priceLabel),
                                      ),
                                    const Divider(),
                                    Row(
                                      children: [
                                        Text(
                                          'Subtotal',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          cart.subtotalLabel,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.brandGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Delivery address',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _showAddAddressSheet,
                                    child: const Text('Add address'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              addressesAsync.when(
                                loading: () => const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (error, _) => AppErrorView(
                                  message: error.toString(),
                                  onRetry: () =>
                                      ref.invalidate(addressesProvider),
                                ),
                                data: (addresses) {
                                  if (addresses.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'No saved addresses. Add one to continue.',
                                          ),
                                          const SizedBox(height: 8),
                                          OutlinedButton(
                                            onPressed: _showAddAddressSheet,
                                            child: const Text('Add address'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final selectedId = _selectedAddressId ??
                                      addresses
                                          .firstWhere(
                                            (a) => a.defaultAddress,
                                            orElse: () => addresses.first,
                                          )
                                          .id;

                                  return RadioGroup<String>(
                                    groupValue: selectedId,
                                    onChanged: (value) {
                                      setState(
                                        () => _selectedAddressId = value,
                                      );
                                    },
                                    child: Column(
                                      children: [
                                        for (final address in addresses)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: AppColors.border,
                                              ),
                                            ),
                                            child: RadioListTile<String>(
                                              value: address.id,
                                              title: Text(address.label),
                                              subtitle: Text(address.summary),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Payment',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: RadioGroup<String>(
                                  groupValue: _paymentMethod,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _paymentMethod = value);
                                    }
                                  },
                                  child: const Column(
                                    children: [
                                      RadioListTile<String>(
                                        value: 'COD',
                                        title: Text('Cash on delivery'),
                                        subtitle: Text(
                                          'Pay when the order arrives',
                                        ),
                                      ),
                                      RadioListTile<String>(
                                        value: 'MOCK_PAY',
                                        title: Text('Mock pay'),
                                        subtitle: Text(
                                          'Simulated online payment',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_formError != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _formError!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _submitting ? null : _placeOrder,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Place order'),
              ),
            ],
          ),
          );
        },
      ),
    );
  }
}
