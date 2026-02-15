// lib/features/catalog/presentation/catalog_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/widgets/desktop_layout.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/features/catalog/application/product_provider.dart';
import 'package:sparewo_client/features/catalog/domain/product_model.dart';
import 'package:sparewo_client/features/cart/application/cart_provider.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  final String? category;
  final String? search;

  const CatalogScreen({super.key, this.category, this.search});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchController = TextEditingController();
  final _gridScrollController = ScrollController();

  String? _selectedCategory;
  String _searchQuery = '';
  String _sortOption = 'Relevance';
  bool _headerCondensed = false;

  static const List<String> _categories = [
    'All',
    'Tyres',
    'Engine',
    'Body',
    'Electrical',
    'Chassis',
    'More',
  ];

  static const List<String> _sortOptions = [
    'Relevance',
    'Newest',
    'Price: Low to High',
    'Price: High to Low',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
    if (widget.search != null) {
      _searchController.text = widget.search!;
      _searchQuery = widget.search!;
    }
    _gridScrollController.addListener(_handleGridScroll);
  }

  @override
  void didUpdateWidget(covariant CatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.category != oldWidget.category) {
      setState(() => _selectedCategory = widget.category);
    }

    if (widget.search != oldWidget.search) {
      setState(() {
        _searchController.text = widget.search ?? '';
        _searchQuery = widget.search ?? '';
      });
    }
  }

  void _handleGridScroll() {
    if (!_gridScrollController.hasClients) return;
    final shouldCondense = _gridScrollController.offset > 28;
    if (shouldCondense == _headerCondensed) return;
    if (!mounted) return;
    setState(() => _headerCondensed = shouldCondense);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gridScrollController
      ..removeListener(_handleGridScroll)
      ..dispose();
    super.dispose();
  }

  List<ProductModel> _sortProducts(List<ProductModel> products) {
    final sorted = List<ProductModel>.from(products);

    switch (_sortOption) {
      case 'Price: Low to High':
        sorted.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
        break;
      case 'Price: High to Low':
        sorted.sort((a, b) => b.unitPrice.compareTo(a.unitPrice));
        break;
      case 'Newest':
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default:
        break;
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScreen(
      mobile: _buildScaffold(context, isDesktop: false),
      desktop: _buildScaffold(context, isDesktop: true),
    );
  }

  Widget _buildScaffold(BuildContext context, {required bool isDesktop}) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(
      catalogProductsProvider((
        category: _selectedCategory,
        searchQuery: _searchQuery,
      )),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final horizontalPadding = isDesktop
                ? DesktopWebScale.horizontalPadding(width).horizontal / 2
                : 16.0;
            final maxContentWidth = isDesktop ? 1760.0 : width;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildCollapsibleHeader(context, isDesktop: isDesktop),
                      const SizedBox(height: 10),
                      Expanded(
                        child: productsAsync.when(
                          data: (products) {
                            if (products.isEmpty) {
                              return _buildEmptyState(context);
                            }

                            final sortedProducts = _sortProducts(products);
                            return GridView.builder(
                              controller: _gridScrollController,
                              physics: const ClampingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                0,
                                6,
                                0,
                                isDesktop ? 52 : 24,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: _gridCrossAxisCount(
                                      width,
                                      isDesktop,
                                    ),
                                    mainAxisSpacing: isDesktop ? 18 : 14,
                                    crossAxisSpacing: isDesktop ? 18 : 14,
                                    childAspectRatio: _gridAspectRatio(
                                      width,
                                      isDesktop,
                                    ),
                                  ),
                              itemCount: sortedProducts.length,
                              itemBuilder: (context, index) =>
                                  _StoreProductCard(
                                    product: sortedProducts[index],
                                    isDesktop: isDesktop,
                                  ),
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) => _buildErrorState(context, error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  int _gridCrossAxisCount(double width, bool isDesktop) {
    if (!isDesktop) return 2;
    if (width >= 1680) return 5;
    if (width >= 1320) return 4;
    if (width >= 1040) return 3;
    return 2;
  }

  double _gridAspectRatio(double width, bool isDesktop) {
    if (!isDesktop) {
      return width < 380 ? 0.68 : 0.72;
    }
    if (width >= 1680) return 0.86;
    if (width >= 1360) return 0.83;
    return 0.8;
  }

  Widget _buildCollapsibleHeader(
    BuildContext context, {
    required bool isDesktop,
  }) {
    final theme = Theme.of(context);
    final condensed = _headerCondensed;
    final isDark = theme.brightness == Brightness.dark;
    final cartItems = ref
        .watch(cartNotifierProvider)
        .maybeWhen(data: (cart) => cart.totalItems, orElse: () => 0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(
        condensed ? 16 : (isDesktop ? 28 : 16),
        condensed ? 12 : (isDesktop ? 20 : 14),
        condensed ? 16 : (isDesktop ? 28 : 16),
        condensed ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(condensed ? 22 : 34),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style:
                      (isDesktop ? AppTextStyles.desktopH2 : AppTextStyles.h2)
                          .copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: condensed
                                ? (isDesktop ? 28 : 20)
                                : (isDesktop ? 42 : 24),
                            color: theme.textTheme.titleLarge?.color,
                            height: 1.02,
                          ),
                  child: const Text('Catalogue'),
                ),
              ),
              if (!condensed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _selectedCategory ?? 'All Parts',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Cart',
                    onPressed: () => context.push('/cart'),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.scaffoldBackgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                  ),
                  if (cartItems > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        constraints: const BoxConstraints(minWidth: 20),
                        child: Text(
                          '$cartItems',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: condensed
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Find parts fast by name, brand, and category.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                            : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
          ),
          SizedBox(height: condensed ? 8 : 14),
          _buildSearchAndSort(context, condensed: condensed),
          SizedBox(height: condensed ? 8 : 14),
          SizedBox(
            height: condensed ? 38 : 46,
            child: _buildCategoryRail(context, condensed: condensed),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSort(BuildContext context, {required bool condensed}) {
    final theme = Theme.of(context);
    final fieldHeight = condensed ? 46.0 : 56.0;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: fieldHeight,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              textInputAction: TextInputAction.search,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                filled: false,
                hintText: 'Search',
                hintStyle: TextStyle(color: theme.hintColor),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: condensed ? 11 : 13,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: fieldHeight,
          padding: EdgeInsets.symmetric(horizontal: condensed ? 10 : 12),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.35),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortOption,
              icon: Icon(
                Icons.swap_vert_rounded,
                color: theme.iconTheme.color,
                size: 20,
              ),
              borderRadius: BorderRadius.circular(16),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _sortOption = value);
              },
              items: _sortOptions
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry,
                      child: Text(
                        condensed ? _toCompactSortLabel(entry) : entry,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: condensed ? 12 : 13,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _toCompactSortLabel(String value) {
    switch (value) {
      case 'Price: Low to High':
        return 'Price ↑';
      case 'Price: High to Low':
        return 'Price ↓';
      default:
        return value;
    }
  }

  Widget _buildCategoryRail(BuildContext context, {required bool condensed}) {
    final theme = Theme.of(context);

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final label = _categories[index];
        final isSelected =
            (_selectedCategory == null && label == 'All') ||
            _selectedCategory == label;

        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () =>
              setState(() => _selectedCategory = label == 'All' ? null : label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: condensed ? 14 : 16,
              vertical: condensed ? 8 : 11,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: isSelected
                  ? AppColors.primary
                  : theme.scaffoldBackgroundColor,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : theme.dividerColor.withValues(alpha: 0.45),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected
                      ? Colors.white
                      : theme.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w700,
                  fontSize: condensed ? 12 : 13,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 54, color: theme.hintColor),
            const SizedBox(height: 14),
            Text('No parts found', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Try a different keyword or category filter.',
              style: AppTextStyles.bodyMedium.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Failed to load catalogue: $error',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _StoreProductCard extends StatefulWidget {
  final ProductModel product;
  final bool isDesktop;

  const _StoreProductCard({required this.product, required this.isDesktop});

  @override
  State<_StoreProductCard> createState() => _StoreProductCardState();
}

class _StoreProductCardState extends State<_StoreProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = widget.product.imageUrls.isNotEmpty
        ? widget.product.imageUrls.first
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/product/${widget.product.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : theme.dividerColor.withValues(alpha: 0.35),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? AppShadows.floatingShadow
                : AppShadows.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: imageUrl == null
                        ? Icon(
                            Icons.image_not_supported_outlined,
                            color: theme.hintColor,
                            size: 28,
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            width: widget.isDesktop ? 120 : 105,
                            placeholder: (_, __) =>
                                Icon(Icons.image, color: theme.hintColor),
                            errorWidget: (_, __, ___) => Icon(
                              Icons.broken_image_outlined,
                              color: theme.hintColor,
                            ),
                          ),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.brand.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: theme.hintColor,
                          letterSpacing: 0.6,
                          fontSize: widget.isDesktop ? 11 : 10,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Expanded(
                        child: Text(
                          widget.product.partName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: widget.isDesktop ? 16 : 13,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.product.formattedPrice,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: widget.isDesktop ? 15 : 12,
                                  height: 1.05,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: widget.isDesktop ? 34 : 32,
                            height: widget.isDesktop ? 34 : 32,
                            decoration: BoxDecoration(
                              color: _hovered
                                  ? AppColors.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                widget.isDesktop ? 12 : 10,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_outward_rounded,
                              size: widget.isDesktop ? 18 : 16,
                              color: _hovered
                                  ? Colors.white
                                  : theme.iconTheme.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.03, end: 0);
  }
}
