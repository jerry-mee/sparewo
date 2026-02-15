// lib/features/catalog/presentation/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/catalog/application/product_provider.dart';
import 'package:sparewo_client/features/cart/application/cart_provider.dart';
import 'package:sparewo_client/features/catalog/domain/product_model.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.productId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: _buildCartIcon(context),
          ),
        ],
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) return const Center(child: Text('Not found'));
          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Stack(
                        children: [
                          _buildImageGallery(product, context),
                          // VERIFIED BADGE OVERLAY
                          Positioned(
                            top: 100, // Below Navbar
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/Verified Icon.png',
                                    width: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Verified Part',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        transform: Matrix4.translationValues(0, -24, 0),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppSpacing.screenPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: theme.dividerColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    product.brand.toUpperCase(),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  _buildStockBadge(product.isInStock),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(product.partName, style: AppTextStyles.h2),
                              const SizedBox(height: 12),
                              Text(
                                product.formattedPrice,
                                style: AppTextStyles.price.copyWith(
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Divider(color: theme.dividerColor),
                              const SizedBox(height: 24),
                              Text('Description', style: AppTextStyles.h4),
                              const SizedBox(height: 8),
                              Text(
                                product.description,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: productAsync.asData?.value != null
          ? _buildBottomAction(context, productAsync.asData!.value!)
          : null,
    );
  }

  Widget _buildImageGallery(ProductModel product, BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.45;
    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: product.imageUrls.length,
        itemBuilder: (context, index) {
          return Container(
            color: Colors.white, // White background for clean product view
            child: CachedNetworkImage(
              imageUrl: product.imageUrls[index],
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStockBadge(bool inStock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: inStock
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        inStock ? 'In Stock' : 'Out of Stock',
        style: AppTextStyles.labelSmall.copyWith(
          color: inStock ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, ProductModel product) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  Text(
                    '$_quantity',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: _quantity < product.stockQuantity
                        ? () => setState(() => _quantity++)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: product.isInStock
                      ? () async {
                          EasyLoading.show(status: 'Adding...');
                          await ref
                              .read(cartNotifierProvider.notifier)
                              .addItem(
                                productId: product.id,
                                quantity: _quantity,
                              );
                          EasyLoading.showSuccess('Added to cart');
                          setState(() => _quantity = 1);
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    product.isInStock ? 'Add to Cart' : 'Unavailable',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartIcon(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final count = ref
            .watch(cartNotifierProvider)
            .maybeWhen(data: (c) => c.totalItems, orElse: () => 0);
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              onPressed: () => context.push('/cart'),
            ),
            if (count > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
