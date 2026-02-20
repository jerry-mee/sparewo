// lib/features/cart/presentation/checkout_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/cart/application/cart_provider.dart';
import 'package:sparewo_client/features/cart/domain/checkout_buy_now_args.dart';
import 'package:sparewo_client/features/catalog/application/product_provider.dart';
import 'package:sparewo_client/features/catalog/domain/product_model.dart';
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';
import 'package:sparewo_client/features/auth/presentation/widgets/auth_guard_modal.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final CheckoutBuyNowArgs? buyNowArgs;

  const CheckoutScreen({super.key, this.buyNowArgs});

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

  double _toAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _placeOrder({CheckoutBuyNowArgs? buyNowArgs}) async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider).asData?.value;
    final cartState = ref.read(cartNotifierProvider);

    if (user == null) {
      await showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (context) => AuthGuardModal(
          title: 'Sign in to checkout',
          message:
              'Please sign in to complete your purchase and track your order.',
          returnTo: GoRouterState.of(context).uri.toString(),
        ),
      );
      return;
    }

    final cart = cartState.asData?.value;
    if (buyNowArgs == null && (cart == null || cart.items.isEmpty)) return;

    setState(() => _isPlacingOrder = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final items = <Map<String, dynamic>>[];
      double subtotal = 0;

      if (buyNowArgs != null) {
        final productSnap = await firestore
            .collection('catalog_products')
            .doc(buyNowArgs.productId)
            .get();

        if (!productSnap.exists) {
          throw Exception('Selected product is no longer available');
        }

        final data = productSnap.data()!;

        // Stock Validation
        final stockQuantity = (data['stockQuantity'] ?? 0) as int;
        if (stockQuantity < buyNowArgs.quantity) {
          throw Exception(
            'Product is out of stock (Requested: ${buyNowArgs.quantity}, Available: $stockQuantity)',
          );
        }

        final legacyPrice = _toAmount(data['price']);
        final catalogPrice = _toAmount(data['unitPrice']);
        final price = legacyPrice > 0 ? legacyPrice : catalogPrice;
        final name = (data['partName'] as String?) ?? 'Unknown product';
        final quantity = buyNowArgs.quantity <= 0 ? 1 : buyNowArgs.quantity;
        final lineTotal = price * quantity;

        subtotal += lineTotal;
        items.add({
          'productId': buyNowArgs.productId,
          'name': name,
          'quantity': quantity,
          'unitPrice': price,
          'lineTotal': lineTotal,
        });
      } else {
        for (final item in cart!.items) {
          final productSnap = await firestore
              .collection('catalog_products')
              .doc(item.productId)
              .get();

          if (!productSnap.exists) continue;

          final data = productSnap.data()!;

          // Stock Validation
          final stockQuantity = (data['stockQuantity'] ?? 0) as int;
          if (stockQuantity < item.quantity) {
            final partName = (data['partName'] as String?) ?? 'Item';
            throw Exception(
              '$partName is out of stock (Requested: ${item.quantity}, Available: $stockQuantity)',
            );
          }

          final legacyPrice = _toAmount(data['price']);
          final catalogPrice = _toAmount(data['unitPrice']);
          final price = legacyPrice > 0 ? legacyPrice : catalogPrice;
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
      }

      if (items.isEmpty) {
        throw Exception('No valid items available for checkout');
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
        'checkoutMode': buyNowArgs != null ? 'buy_now' : 'cart',
      });

      if (buyNowArgs == null) {
        await ref.read(cartNotifierProvider.notifier).clearCart();
      }

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
    final buyNowArgs = widget.buyNowArgs;
    final buyNowProductAsync = buyNowArgs != null
        ? ref.watch(productByIdProvider(buyNowArgs.productId))
        : null;
    final theme = Theme.of(context);

    // Prefill
    if (user?.phone != null && _phoneController.text.isEmpty) {
      _phoneController.text = user!.phone!;
    }

    if (user == null) {
      return ResponsiveScreen(
        mobile: Scaffold(
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
          body: _buildGuestCheckoutState(),
        ),
        desktop: DesktopScaffold(
          widthTier: DesktopWidthTier.wide,
          child: Column(
            children: [
              const SizedBox(height: 80),
              _buildGuestCheckoutState(),
              const SiteFooter(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      );
    }

    return ResponsiveScreen(
      mobile: Scaffold(
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
        body: buyNowArgs != null && buyNowProductAsync != null
            ? _buildBuyNowMobile(buyNowProductAsync, buyNowArgs)
            : _buildMobile(cartAsync),
      ),
      desktop: buyNowArgs != null && buyNowProductAsync != null
          ? _buildBuyNowDesktop(buyNowProductAsync, buyNowArgs)
          : _buildDesktop(cartAsync),
    );
  }

  Widget _buildMobile(AsyncValue cartAsync) {
    return cartAsync.when(
      data: (cart) {
        if (cart.items.isEmpty) return const Center(child: Text('Empty Cart'));
        const deliveryFee = 5000.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: _buildCheckoutForm(
            totalItems: cart.totalItems,
            deliveryFee: deliveryFee,
            onConfirm: () => _placeOrder(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildBuyNowMobile(
    AsyncValue<ProductModel?> productAsync,
    CheckoutBuyNowArgs buyNowArgs,
  ) {
    return productAsync.when(
      data: (product) {
        if (product == null) {
          return const Center(child: Text('Product unavailable'));
        }
        const deliveryFee = 5000.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              _buildBuyNowBanner(product, buyNowArgs.quantity),
              const SizedBox(height: 16),
              _buildCheckoutForm(
                totalItems: buyNowArgs.quantity,
                deliveryFee: deliveryFee,
                onConfirm: () => _placeOrder(buyNowArgs: buyNowArgs),
                confirmLabel: 'Buy Now',
                estimatedSubtotal: product.unitPrice * buyNowArgs.quantity,
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildDesktop(AsyncValue cartAsync) {
    return DesktopScaffold(
      widthTier: DesktopWidthTier.wide,
      child: cartAsync.when(
        data: (cart) {
          if (cart.items.isEmpty) {
            return const Column(
              children: [
                SizedBox(height: 60),
                Center(child: Text('Empty Cart')),
                SiteFooter(),
                SizedBox(height: 120),
              ],
            );
          }
          const deliveryFee = 5000.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DesktopSection(
                title: 'Checkout',
                subtitle: 'Confirm delivery and payment details',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildCheckoutForm(
                        totalItems: cart.totalItems,
                        deliveryFee: deliveryFee,
                        onConfirm: () => _placeOrder(),
                        includeSummarySection: false,
                      ),
                    ),
                    const SizedBox(width: 36),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildSummaryCard(
                            null,
                            totalItems: cart.totalItems,
                            deliveryFee: deliveryFee,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isPlacingOrder
                                  ? null
                                  : () => _placeOrder(),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: _isPlacingOrder
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text('Confirm Order'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SiteFooter(),
              const SizedBox(height: 120),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBuyNowDesktop(
    AsyncValue<ProductModel?> productAsync,
    CheckoutBuyNowArgs buyNowArgs,
  ) {
    return DesktopScaffold(
      widthTier: DesktopWidthTier.wide,
      child: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Column(
              children: [
                SizedBox(height: 60),
                Center(child: Text('Product unavailable')),
                SiteFooter(),
                SizedBox(height: 120),
              ],
            );
          }
          const deliveryFee = 5000.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DesktopSection(
                title: 'Buy Now Checkout',
                subtitle: 'Complete this order instantly',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          _buildBuyNowBanner(product, buyNowArgs.quantity),
                          const SizedBox(height: 16),
                          _buildCheckoutForm(
                            totalItems: buyNowArgs.quantity,
                            deliveryFee: deliveryFee,
                            onConfirm: () =>
                                _placeOrder(buyNowArgs: buyNowArgs),
                            confirmLabel: 'Buy Now',
                            estimatedSubtotal:
                                product.unitPrice * buyNowArgs.quantity,
                            includeSummarySection: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 36),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildSummaryCard(
                            null,
                            totalItems: buyNowArgs.quantity,
                            deliveryFee: deliveryFee,
                            estimatedSubtotal:
                                product.unitPrice * buyNowArgs.quantity,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isPlacingOrder
                                  ? null
                                  : () => _placeOrder(buyNowArgs: buyNowArgs),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: _isPlacingOrder
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text('Buy Now'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SiteFooter(),
              const SizedBox(height: 120),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildGuestCheckoutState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to checkout',
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please sign in to place your order and track deliveries.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                AuthGuardModal.check(
                  context: context,
                  ref: ref,
                  title: 'Sign in to checkout',
                  message:
                      'Please sign in to complete your purchase and track your order.',
                  onAuthenticated: () {},
                );
              },
              child: const Text('Sign In / Register'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyNowBanner(ProductModel product, int quantity) {
    final theme = Theme.of(context);
    return _buildSection(
      null,
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: product.imageUrls.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_not_supported_outlined),
                    ),
                  )
                : const Icon(Icons.image_not_supported_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buy Now',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.partName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: $quantity',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'UGX ${_formatCurrency(product.unitPrice * quantity)}',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutForm({
    required int totalItems,
    required double deliveryFee,
    required VoidCallback onConfirm,
    String confirmLabel = 'Confirm Order',
    double? estimatedSubtotal,
    bool includeSummarySection = true,
  }) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delivery Details', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          _buildSection(
            null,
            child: Column(
              children: [
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
              ],
            ),
          ).animate().fadeIn().slideX(),
          const SizedBox(height: 24),
          Text('Payment Method', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          _buildPaymentOption(
            null,
            'Cash on Delivery',
            Icons.money,
            true,
            'Pay when you receive items',
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            null,
            'Mobile Money',
            Icons.phone_android,
            false,
            'Coming soon',
          ),
          const SizedBox(height: 24),
          if (includeSummarySection) ...[
            Text('Order Summary', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            _buildSummaryCard(
              null,
              totalItems: totalItems,
              deliveryFee: deliveryFee,
              estimatedSubtotal: estimatedSubtotal,
            ),
            const SizedBox(height: 32),
          ],
          if (includeSummarySection)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isPlacingOrder ? null : onConfirm,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _isPlacingOrder
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(confirmLabel),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext? _, {required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
        boxShadow: AppShadows.cardShadow,
      ),
      child: child,
    );
  }

  Widget _buildPaymentOption(
    BuildContext? _,
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
                ? AppColors.primary.withValues(alpha: 0.05)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(24),
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

  Widget _buildSummaryRow(BuildContext? _, String label, String value) {
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

  Widget _buildSummaryCard(
    BuildContext? _, {
    required int totalItems,
    required double deliveryFee,
    double? estimatedSubtotal,
  }) {
    final estimated = estimatedSubtotal ?? 0;
    final feeText = 'UGX ${_formatCurrency(deliveryFee)}';
    final hasEstimate = estimatedSubtotal != null;
    final totalText = hasEstimate
        ? 'UGX ${_formatCurrency(estimated + deliveryFee)}'
        : 'Calculated';
    return _buildSection(
      null,
      child: Column(
        children: [
          _buildSummaryRow(
            null,
            'Items ($totalItems)',
            hasEstimate ? 'UGX ${_formatCurrency(estimated)}' : 'Calculated',
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(null, 'Delivery Fee', feeText),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.h3),
              Text(totalText, style: AppTextStyles.price),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Final total confirmed on placement',
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))');
    final formatted = amount.toStringAsFixed(0);
    return formatted.replaceAllMapped(formatter, (Match m) => '${m[1]},');
  }
}
