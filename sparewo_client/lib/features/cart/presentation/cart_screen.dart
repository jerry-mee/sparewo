// lib/features/cart/presentation/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/widgets/responsive_layout.dart';
import 'package:sparewo_client/features/cart/application/cart_provider.dart';
import 'package:sparewo_client/features/catalog/application/product_provider.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartNotifierProvider);
    final userAsync = ref.watch(currentUserProvider);
    final isLoggedIn = userAsync.asData?.value != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: cartAsync.when(
        data: (cart) {
          if (cart.items.isEmpty) {
            return _buildEmptyCart(context);
          }
          return ResponsiveLayout(
            mobileBody: _buildMobileLayout(context, ref, cart),
            desktopBody: _buildDesktopLayout(context, ref, cart),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: cartAsync.maybeWhen(
        data: (cart) => cart.items.isEmpty
            ? null
            : _buildCheckoutSection(context, ref, cart, isLoggedIn),
        orElse: () => null,
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 24),
          Text('Your cart is empty', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/catalog'),
            child: const Text('Browse Parts'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref, cart) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cart.items.length,
      itemBuilder: (context, index) {
        return _CartItemCard(item: cart.items[index], index: index);
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref, cart) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: cart.items.length,
          itemBuilder: (context, index) {
            return _CartItemCard(item: cart.items[index], index: index);
          },
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(
    BuildContext context,
    WidgetRef ref,
    cart,
    bool isLoggedIn,
  ) {
    return FutureBuilder<double>(
      future: _calculateTotal(ref, cart),
      builder: (context, snapshot) {
        final totalAmount = snapshot.data ?? 0.0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: AppTextStyles.bodyMedium),
                    Text(
                      'UGX ${_formatCurrency(totalAmount)}',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (isLoggedIn) {
                      context.push('/checkout');
                    } else {
                      context.push('/login');
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(isLoggedIn ? 'Checkout' : 'Login to Checkout'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<double> _calculateTotal(WidgetRef ref, cart) async {
    double total = 0.0;
    for (final item in cart.items) {
      final product = await ref.read(
        productByIdProvider(item.productId).future,
      );
      if (product != null) {
        total += product.unitPrice * item.quantity;
      }
    }
    return total;
  }

  String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatted = amount.toStringAsFixed(0);
    return formatted.replaceAllMapped(formatter, (Match m) => '${m[1]},');
  }
}

class _CartItemCard extends ConsumerWidget {
  final dynamic item;
  final int index;

  const _CartItemCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(item.productId));

    return productAsync.when(
      data: (product) {
        if (product == null) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.divider),
          ),
          child: InkWell(
            onTap: () => context.push('/product/${product.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: product.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: product.imageUrls.first,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.image_not_supported),
                  ),
                  const SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.partName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(product.brand, style: AppTextStyles.labelSmall),
                        const SizedBox(height: 8),
                        Text(
                          product.formattedPrice,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Controls (Prevent tap event propagation)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 20,
                            ),
                            onPressed: () {
                              if (item.quantity > 1) {
                                ref
                                    .read(cartNotifierProvider.notifier)
                                    .updateQuantity(
                                      item.productId,
                                      item.quantity - 1,
                                    );
                              }
                            },
                          ),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 20,
                            ),
                            onPressed: item.quantity < product.stockQuantity
                                ? () {
                                    ref
                                        .read(cartNotifierProvider.notifier)
                                        .updateQuantity(
                                          item.productId,
                                          item.quantity + 1,
                                        );
                                  }
                                : null,
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          // Separate tap for remove action
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Remove item?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    ref
                                        .read(cartNotifierProvider.notifier)
                                        .removeItem(item.productId);
                                  },
                                  child: const Text(
                                    'Remove',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Remove',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1, end: 0);
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
