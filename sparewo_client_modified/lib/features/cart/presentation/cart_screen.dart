import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/auth/presentation/widgets/auth_guard_modal.dart';
import 'package:sparewo_client/features/cart/application/cart_provider.dart';
import 'package:sparewo_client/features/cart/domain/cart_item_model.dart';
import 'package:sparewo_client/features/cart/domain/cart_model.dart';
import 'package:sparewo_client/features/catalog/application/product_provider.dart';
import 'package:sparewo_client/features/catalog/domain/product_model.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartNotifierProvider);
    final userAsync = ref.watch(currentUserProvider);
    final isLoggedIn = userAsync.asData?.value != null;

    return ResponsiveScreen(
      mobile: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Shopping Cart'),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: cartAsync.when(
          data: (cart) {
            if (cart.items.isEmpty) {
              return _buildEmptyCart(context, isDesktop: false);
            }
            return _buildMobileLayout(context, cart);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
        bottomNavigationBar: cartAsync.maybeWhen(
          data: (cart) => cart.items.isEmpty
              ? null
              : _buildCheckoutPanel(
                  context,
                  ref,
                  cart: cart,
                  isLoggedIn: isLoggedIn,
                  isDesktop: false,
                ),
          orElse: () => null,
        ),
      ),
      desktop: _buildDesktop(context, ref, isLoggedIn),
    );
  }

  Widget _buildDesktop(BuildContext context, WidgetRef ref, bool isLoggedIn) {
    final cartAsync = ref.watch(cartNotifierProvider);

    return DesktopScaffold(
      widthTier: DesktopWidthTier.wide,
      child: cartAsync.when(
        data: (cart) {
          if (cart.items.isEmpty) {
            return Column(
              children: [
                const SizedBox(height: 48),
                _buildEmptyCart(context, isDesktop: true),
                const SiteFooter(),
                const SizedBox(height: 120),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DesktopSection(
                title: 'Cart',
                subtitle: 'Review your selected parts before checkout',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) => _CartItemCard(
                          item: cart.items[index],
                          index: index,
                          isDesktop: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 36),
                    Expanded(
                      flex: 4,
                      child: _buildCheckoutPanel(
                        context,
                        ref,
                        cart: cart,
                        isLoggedIn: isLoggedIn,
                        isDesktop: true,
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
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, {required bool isDesktop}) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isDesktop ? 620 : 420),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.35),
            ),
            boxShadow: AppShadows.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 34,
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Your Cart is Empty',
                style: (isDesktop ? AppTextStyles.desktopH2 : AppTextStyles.h3)
                    .copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Add parts to your cart and continue to checkout.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/catalog'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Continue Shopping'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, CartModel cart) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 130),
      itemCount: cart.items.length,
      itemBuilder: (context, index) => _CartItemCard(
        item: cart.items[index],
        index: index,
        isDesktop: false,
      ),
    );
  }

  Widget _buildCheckoutPanel(
    BuildContext context,
    WidgetRef ref, {
    required CartModel cart,
    required bool isLoggedIn,
    required bool isDesktop,
  }) {
    final subtotalAsync = ref.watch(cartSubtotalProvider);

    return subtotalAsync.when(
      data: (subtotal) {
        const shipping = 0.0;
        final total = subtotal + shipping;

        final summaryContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDesktop)
              Text(
                'Order Summary',
                style: AppTextStyles.desktopH3.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (isDesktop) const SizedBox(height: 16),
            _summaryRow(
              context,
              label: 'Items (${cart.totalItems})',
              value: 'UGX ${_formatCurrency(subtotal)}',
            ),
            const SizedBox(height: 8),
            _summaryRow(
              context,
              label: 'Delivery',
              value: shipping == 0
                  ? 'Free'
                  : 'UGX ${_formatCurrency(shipping)}',
            ),
            const SizedBox(height: 14),
            Divider(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            _summaryRow(
              context,
              label: 'Total',
              value: 'UGX ${_formatCurrency(total)}',
              strong: true,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _handleCheckoutTap(context, ref, isLoggedIn),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  isLoggedIn ? 'Proceed to Checkout' : 'Login to Checkout',
                ),
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/catalog'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Continue Shopping'),
                ),
              ),
            ],
          ],
        );

        if (isDesktop) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              ),
              boxShadow: AppShadows.cardShadow,
            ),
            child: summaryContent,
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
              ),
            ),
          ),
          child: SafeArea(child: summaryContent),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(child: Text('Error calculating total: $e')),
    );
  }

  Widget _summaryRow(
    BuildContext context, {
    required String label,
    required String value,
    bool strong = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            color: strong ? Theme.of(context).textTheme.bodyLarge?.color : null,
          ),
        ),
        Text(
          value,
          style: (strong ? AppTextStyles.h4 : AppTextStyles.bodyMedium)
              .copyWith(
                fontWeight: FontWeight.w800,
                color: strong ? AppColors.primary : null,
              ),
        ),
      ],
    );
  }

  void _handleCheckoutTap(
    BuildContext context,
    WidgetRef ref,
    bool isLoggedIn,
  ) {
    if (isLoggedIn) {
      context.push('/checkout');
      return;
    }

    AuthGuardModal.check(
      context: context,
      ref: ref,
      title: 'Sign in to checkout',
      message: 'Please sign in to complete your purchase and track your order.',
      onAuthenticated: () => context.push('/checkout'),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = amount.toStringAsFixed(0);
    return formatted.replaceAllMapped(formatter, (Match m) => '${m[1]},');
  }
}

class _CartItemCard extends ConsumerWidget {
  final CartItemModel item;
  final int index;
  final bool isDesktop;

  const _CartItemCard({
    required this.item,
    required this.index,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(item.productId));

    return productAsync.when(
      data: (product) {
        if (product == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.only(bottom: isDesktop ? 16 : 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            ),
            boxShadow: AppShadows.cardShadow,
          ),
          child: InkWell(
            onTap: () => context.push('/product/${product.id}'),
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(context, product),
                  const SizedBox(width: 14),
                  Expanded(child: _buildDetails(context, product)),
                  const SizedBox(width: 10),
                  _buildControls(context, ref, product),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (index * 45).ms).slideY(begin: 0.05, end: 0);
      },
      loading: () => Container(
        margin: EdgeInsets.only(bottom: isDesktop ? 16 : 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
        ),
        child: const SizedBox(
          height: 84,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildImage(BuildContext context, ProductModel product) {
    return Container(
      width: isDesktop ? 96 : 88,
      height: isDesktop ? 96 : 88,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: product.imageUrls.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CachedNetworkImage(
                imageUrl: product.imageUrls.first,
                fit: BoxFit.cover,
              ),
            )
          : const Icon(Icons.image_not_supported_outlined),
    );
  }

  Widget _buildDetails(BuildContext context, ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.brand.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).hintColor,
            letterSpacing: 0.6,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          product.partName,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: isDesktop ? 17 : 15,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Text(
          product.formattedPrice,
          style: AppTextStyles.h4.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) {
    final qtyTextStyle = AppTextStyles.bodyMedium.copyWith(
      fontWeight: FontWeight.w700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        InkWell(
          onTap: () => _showRemoveDialog(context, ref),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.error,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _qtyButton(
                context,
                icon: Icons.remove,
                enabled: item.quantity > 1,
                onTap: () {
                  if (item.quantity > 1) {
                    ref
                        .read(cartNotifierProvider.notifier)
                        .updateQuantity(item.productId, item.quantity - 1);
                  }
                },
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '${item.quantity}',
                  textAlign: TextAlign.center,
                  style: qtyTextStyle,
                ),
              ),
              _qtyButton(
                context,
                icon: Icons.add,
                enabled: item.quantity < product.stockQuantity,
                onTap: () => ref
                    .read(cartNotifierProvider.notifier)
                    .updateQuantity(item.productId, item.quantity + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qtyButton(
    BuildContext context, {
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? Theme.of(context).cardColor : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? Theme.of(context).dividerColor.withValues(alpha: 0.8)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled
              ? Theme.of(context).iconTheme.color
              : Theme.of(context).disabledColor,
        ),
      ),
    );
  }

  Future<void> _showRemoveDialog(BuildContext context, WidgetRef ref) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove item?'),
        content: const Text('This part will be removed from your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldRemove == true) {
      await ref.read(cartNotifierProvider.notifier).removeItem(item.productId);
    }
  }
}
