// lib/features/cart/presentation/checkout_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/cart/application/cart_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _paymentMethod = 'Cash on Delivery';
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider).asData?.value;
    final cartState = ref.read(cartNotifierProvider);

    if (user == null) return;

    final cart = cartState.asData?.value;
    if (cart == null || cart.items.isEmpty) return;

    setState(() => _isPlacingOrder = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final items = <Map<String, dynamic>>[];
      double subtotal = 0;

      for (final item in cart.items) {
        final productSnap = await firestore
            .collection('catalog_products')
            .doc(item.productId)
            .get();

        if (!productSnap.exists) continue;

        final data = productSnap.data()!;
        final price = (data['price'] ?? 0).toDouble();
        final name = (data['partName'] as String?) ?? 'Unknown product';
        final lineTotal = price * item.quantity;

        subtotal += lineTotal;

        items.add({
          'productId': item.productId,
          'name': name,
          'quantity': item.quantity,
          'unitPrice': price,
          'lineTotal': lineTotal,
        });
      }

      const deliveryFee = 5000.0;
      final totalAmount = subtotal + deliveryFee;

      await firestore.collection('orders').add({
        'userId': user.id,
        'userName': user.name,
        'userEmail': user.email,
        'deliveryAddress': _addressController.text.trim(),
        'contactPhone': _phoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'paymentMethod': _paymentMethod == 'Cash on Delivery'
            ? 'cash_on_delivery'
            : 'mobile_money',
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'totalAmount': totalAmount,
        'items': items,
      });

      await ref.read(cartNotifierProvider.notifier).clearCart();

      if (!mounted) return;
      context.go('/orders');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartNotifierProvider);
    final user = ref.watch(currentUserProvider).asData?.value;
    final theme = Theme.of(context);

    // Prefill
    if (user?.phone != null && _phoneController.text.isEmpty) {
      _phoneController.text = user!.phone!;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: cartAsync.when(
        data: (cart) {
          if (cart.items.isEmpty)
            return const Center(child: Text('Empty Cart'));

          const deliveryFee = 5000.0; // Placeholder

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Delivery
                  Text('Delivery Details', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  _buildSection(
                    context,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Address',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          validator: (v) =>
                              v?.isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              v?.isEmpty == true ? 'Required' : null,
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideX(),

                  const SizedBox(height: 24),

                  // 2. Payment
                  Text('Payment Method', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    context,
                    'Cash on Delivery',
                    Icons.money,
                    true,
                    'Pay when you receive items',
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    context,
                    'Mobile Money',
                    Icons.phone_android,
                    false, // Disabled
                    'Coming soon',
                  ),

                  const SizedBox(height: 24),

                  // 3. Summary
                  Text('Order Summary', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  _buildSection(
                    context,
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          context,
                          'Items (${cart.totalItems})',
                          'Calculated',
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(context, 'Delivery Fee', 'UGX 5,000'),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: AppTextStyles.h3),
                            Text('Calculated', style: AppTextStyles.price),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Final total confirmed on placement',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideX(),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _isPlacingOrder ? null : _placeOrder,
                      child: _isPlacingOrder
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Confirm Order'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      child: child,
    );
  }

  Widget _buildPaymentOption(
    BuildContext context,
    String title,
    IconData icon,
    bool enabled,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final isSelected = _paymentMethod == title;

    return GestureDetector(
      onTap: enabled ? () => setState(() => _paymentMethod = title) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.05)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : theme.dividerColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : theme.iconTheme.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
