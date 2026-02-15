// lib/features/catalog/presentation/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/catalog/application/product_provider.dart';
import 'package:sparewo_client/features/cart/application/cart_provider.dart';
import 'package:sparewo_client/features/cart/domain/checkout_buy_now_args.dart';
import 'package:sparewo_client/features/catalog/domain/product_model.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/auth/presentation/widgets/auth_guard_modal.dart';
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';

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
  int _currentImageIndex = 0;

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _quantity = 1;
      _currentImageIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScreen(
      mobile: _buildMobile(context),
      desktop: _buildDesktop(context),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.productId));
    final user = ref.watch(currentUserProvider).asData?.value;
    final theme = Theme.of(context);

    return DesktopScaffold(
      widthTier: DesktopWidthTier.wide,
      child: productAsync.when(
        data: (product) {
          if (product == null) return const Center(child: Text('Not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesktopSection(
                  title: product.partName,
                  subtitle: product.brand.toUpperCase(),
                  padding: const EdgeInsets.only(top: 26, bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(
                              DesktopWebScale.panelRadius,
                            ),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.35),
                            ),
                            boxShadow: AppShadows.cardShadow,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              DesktopWebScale.panelRadius,
                            ),
                            child: _buildImageGallery(product, context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 36),
                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(
                              DesktopWebScale.cardRadius,
                            ),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.35),
                            ),
                            boxShadow: AppShadows.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStockBadge(product.isInStock),
                              const SizedBox(height: 18),
                              Text(
                                product.formattedPrice,
                                style: AppTextStyles.desktopH1.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 42,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'Description',
                                style: AppTextStyles.desktopH3,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                product.description,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.8),
                                  height: 1.55,
                                ),
                              ),
                              const SizedBox(height: 32),
                              _buildBottomAction(
                                context,
                                product,
                                user != null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SiteFooter(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.productId));
    final user = ref.watch(currentUserProvider).asData?.value;
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
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
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
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: _buildCartIcon(context),
          ),
        ],
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) return const Center(child: Text('Not found'));
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildImageGallery(product, context),
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
                                  color: Colors.black.withValues(alpha: 0.05),
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
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              color: AppColors.primary,
                                              letterSpacing: 1.2,
                                            ),
                                      ),
                                      _buildStockBadge(product.isInStock),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    product.partName,
                                    style: AppTextStyles.h2,
                                  ),
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
                                          ?.withValues(alpha: 0.8),
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
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: productAsync.asData?.value != null
          ? _buildBottomAction(
              context,
              productAsync.asData!.value!,
              user != null,
            )
          : null,
    );
  }

  List<String> _resolvedImageUrls(ProductModel product) {
    return product.imageUrls
        .where((url) => url.trim().isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> _showImageLightbox(
    BuildContext context,
    List<String> images, {
    required int initialIndex,
  }) async {
    if (images.isEmpty) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) =>
          _ProductLightboxDialog(images: images, initialIndex: initialIndex),
    );
  }

  Widget _buildImageGallery(ProductModel product, BuildContext context) {
    final images = _resolvedImageUrls(product);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1000;
    final height = isDesktop ? 520.0 : size.height * 0.45;

    if (images.isEmpty) {
      return Container(
        height: height,
        color: Theme.of(context).cardColor,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 44,
          color: Theme.of(context).hintColor,
        ),
      );
    }

    final safeIndex = _currentImageIndex.clamp(0, images.length - 1);

    return SizedBox(
      child: Column(
        children: [
          SizedBox(
            height: height,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  itemCount: images.length,
                  onPageChanged: (index) {
                    if (!mounted) return;
                    setState(() => _currentImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _showImageLightbox(
                        context,
                        images,
                        initialIndex: index,
                      ),
                      child: Container(
                        color: Colors.white,
                        child: CachedNetworkImage(
                          imageUrl: images[index],
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${safeIndex + 1}/${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 14,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _showImageLightbox(
                      context,
                      images,
                      initialIndex: safeIndex,
                    ),
                    icon: const Icon(Icons.zoom_out_map_rounded, size: 18),
                    label: const Text('View all photos'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.55),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (images.length > 1)
            SizedBox(
              height: 82,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final isActive = index == safeIndex;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      );
                      if (!mounted) return;
                      setState(() => _currentImageIndex = index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 66,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : Theme.of(context).dividerColor,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: images[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(bool inStock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: inStock
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
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

  Widget _buildBottomAction(
    BuildContext context,
    ProductModel product,
    bool isAuthenticated,
  ) {
    final theme = Theme.of(context);
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactActions = constraints.maxWidth < 390;

                final quantityControl = Container(
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(999),
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
                );

                final actionsRow = Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: product.isInStock
                              ? () => _handleBuyNow(product, isAuthenticated)
                              : null,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text(
                            'Buy Now',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: product.isInStock
                              ? () => _handleAddToCart(product)
                              : null,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            product.isInStock ? 'Add to Cart' : 'Unavailable',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ),
                    ),
                  ],
                );

                if (compactActions) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      quantityControl,
                      const SizedBox(height: 10),
                      actionsRow,
                    ],
                  );
                }

                return Row(
                  children: [
                    quantityControl,
                    const SizedBox(width: 16),
                    Expanded(child: actionsRow),
                  ],
                );
              },
            ),
          ),
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

  Future<void> _handleAddToCart(ProductModel product) async {
    EasyLoading.show(status: 'Adding...');
    try {
      await ref
          .read(cartNotifierProvider.notifier)
          .addItem(productId: product.id, quantity: _quantity);
      EasyLoading.showSuccess('Added to cart');
      if (!mounted) return;
      setState(() => _quantity = 1);
    } catch (_) {
      EasyLoading.showError('Failed to add item');
    }
  }

  Future<void> _handleBuyNow(ProductModel product, bool isAuthenticated) async {
    Future<void> proceed() async {
      final cart = ref.read(cartNotifierProvider).asData?.value;
      final hasOtherCartItems =
          cart != null &&
          cart.items.any((item) => item.productId != product.id);

      if (hasOtherCartItems) {
        final otherItemsCount = cart.items
            .where((item) => item.productId != product.id)
            .fold<int>(0, (sum, item) => sum + item.quantity);

        final decision = await _promptBuyNowDecision(
          context,
          otherItemsCount: otherItemsCount,
        );

        if (!mounted || decision == null) {
          return;
        }

        if (decision == _BuyNowDecision.includeCartItems) {
          EasyLoading.show(status: 'Adding item...');
          try {
            await ref
                .read(cartNotifierProvider.notifier)
                .addItem(productId: product.id, quantity: _quantity);
            if (!mounted) return;
            setState(() => _quantity = 1);
            EasyLoading.dismiss();
            context.push('/checkout');
            return;
          } catch (_) {
            EasyLoading.showError('Failed to start checkout');
            return;
          }
        }
      }

      final checkoutArgs = CheckoutBuyNowArgs(
        productId: product.id,
        quantity: _quantity,
      );
      if (!mounted) return;
      setState(() => _quantity = 1);
      context.push('/checkout', extra: checkoutArgs);
    }

    if (isAuthenticated) {
      proceed();
      return;
    }

    AuthGuardModal.check(
      context: context,
      ref: ref,
      title: 'Sign in to buy now',
      message: 'Sign in to continue with Buy Now and track your SpareWo order.',
      onAuthenticated: () {
        proceed();
      },
    );
  }

  Future<_BuyNowDecision?> _promptBuyNowDecision(
    BuildContext context, {
    required int otherItemsCount,
  }) {
    final theme = Theme.of(context);

    return showDialog<_BuyNowDecision>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: const Text('Buy this item only?'),
          content: Text(
            'You already have $otherItemsCount item(s) in your cart. '
            'Do you want to checkout this item only, or include your existing cart items too?',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(_BuyNowDecision.includeCartItems),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text('Include Cart'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_BuyNowDecision.buyThisOnly),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('This Item Only'),
            ),
          ],
        );
      },
    );
  }
}

enum _BuyNowDecision { buyThisOnly, includeCartItems }

class _ProductLightboxDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ProductLightboxDialog({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ProductLightboxDialog> createState() => _ProductLightboxDialogState();
}

class _ProductLightboxDialogState extends State<_ProductLightboxDialog> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black.withValues(alpha: 0.96),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_index + 1}/${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: widget.images.length > 1
                        ? () {
                            final next =
                                (_index - 1 + widget.images.length) %
                                widget.images.length;
                            _controller.animateToPage(
                              next,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: widget.images.length > 1
                        ? () {
                            final next = (_index + 1) % widget.images.length;
                            _controller.animateToPage(
                              next,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.images.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: widget.images[index],
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white70,
                          size: 42,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.images.length > 1)
              SizedBox(
                height: 86,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, thumbIndex) {
                    final isActive = thumbIndex == _index;
                    return GestureDetector(
                      onTap: () {
                        _controller.animateToPage(
                          thumbIndex,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 66,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? AppColors.primary
                                : Colors.white24,
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: widget.images[thumbIndex],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
