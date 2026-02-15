// lib/features/catalog/presentation/catalog_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/catalog/application/product_provider.dart';
import 'package:sparewo_client/features/catalog/domain/product_model.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  final String? category;
  final String? search;
  const CatalogScreen({super.key, this.category, this.search});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String _searchQuery = '';
  String _sortOption = 'Relevance';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
    if (widget.search != null) {
      _searchController.text = widget.search!;
      _searchQuery = widget.search!;
    }
  }

  List<ProductModel> _sortProducts(List<ProductModel> products) {
    List<ProductModel> sorted = List.from(products);
    if (_sortOption == 'Price: Low to High') {
      sorted.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
    } else if (_sortOption == 'Price: High to Low') {
      sorted.sort((a, b) => b.unitPrice.compareTo(a.unitPrice));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(
      catalogProductsProvider((
        category: _selectedCategory,
        searchQuery: _searchQuery,
      )),
    );
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.05),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. Modern Header
                _buildHeader(context),

                // 2. Filter Tags
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('Tyres'),
                      _buildFilterChip('Engine'),
                      _buildFilterChip('Body'),
                      _buildFilterChip('Electrical'),
                      _buildFilterChip('Suspension'),
                    ],
                  ),
                ),

                // 3. Product List
                Expanded(
                  child: productsAsync.when(
                    data: (products) {
                      if (products.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: theme.disabledColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No parts found',
                                style: AppTextStyles.h3.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final sortedProducts = _sortProducts(products);

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: sortedProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) =>
                            _ModernProductCard(product: sortedProducts[index]),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: theme.cardColor,
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadows.cardShadow,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search for parts...',
                  hintStyle: TextStyle(color: theme.hintColor),
                  prefixIcon: Icon(Icons.search, color: AppColors.primary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.cardShadow,
            ),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.sort, color: theme.iconTheme.color),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.zero,
              onSelected: (val) => setState(() => _sortOption = val),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'Relevance',
                  child: Text('Relevance'),
                ),
                const PopupMenuItem(
                  value: 'Price: Low to High',
                  child: Text('Price: Low to High'),
                ),
                const PopupMenuItem(
                  value: 'Price: High to Low',
                  child: Text('Price: High to Low'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected =
        (_selectedCategory == null && label == 'All') ||
        _selectedCategory == label;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (v) =>
            setState(() => _selectedCategory = label == 'All' ? null : label),
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        backgroundColor: theme.cardColor,
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : theme.dividerColor.withOpacity(0.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: isSelected ? 4 : 0,
        shadowColor: AppColors.primary.withOpacity(0.4),
      ),
    );
  }
}

class _ModernProductCard extends StatelessWidget {
  final ProductModel product;
  const _ModernProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.cardShadow,
          border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Left: Image
            Container(
              width: 130,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(24),
                ),
              ),
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: product.imageUrls.first,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => Container(
                    color: theme.dividerColor.withOpacity(0.1),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              ),
            ),

            // Right: Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.partName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.brand,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          product.formattedPrice,
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
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
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }
}
