// lib/screens/products/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../models/vendor_product.dart';
import '../../models/vehicle_compatibility.dart';
import '../../routes/app_router.dart';
import '../../theme.dart';
import '../../constants/enums.dart';

class ProductDetailScreen extends StatelessWidget {
  final VendorProduct product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.addEditProduct,
                  arguments: product);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImages(context),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductInfo(textTheme, colorScheme),
                  const SizedBox(height: 16),
                  _buildStockDetails(textTheme),
                  const SizedBox(height: 24),
                  _buildDescription(textTheme),
                  const SizedBox(height: 24),
                  _buildNestedCompatibleModels(context, textTheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImages(BuildContext context) {
    if (product.images.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[200],
        child: const Center(
            child: Icon(Icons.photo_size_select_actual_outlined,
                size: 60, color: Colors.grey)),
      );
    }

    return GestureDetector(
      onTap: () => _openImageGallery(context, 0),
      child: CarouselSlider.builder(
        itemCount: product.images.length,
        itemBuilder: (context, index, realIndex) {
          return GestureDetector(
            onTap: () => _openImageGallery(context, index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.images[index],
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, color: Colors.red),
                    );
                  },
                ),
              ),
            ),
          );
        },
        options: CarouselOptions(
          height: 250,
          viewportFraction: product.images.length > 1 ? 0.9 : 1.0,
          enlargeCenterPage: true,
          autoPlay: product.images.length > 1,
          autoPlayInterval: const Duration(seconds: 5),
          enableInfiniteScroll: product.images.length > 1,
        ),
      ),
    );
  }

  void _openImageGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageGalleryView(
          images: product.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildProductInfo(TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.partName, style: textTheme.headlineLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                product.category.displayName,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: product.status == ProductStatus.approved
                    ? Colors.green.withOpacity(0.1)
                    : product.status == ProductStatus.pending
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                product.status.displayName,
                style: textTheme.bodyMedium?.copyWith(
                  color: product.status == ProductStatus.approved
                      ? Colors.green
                      : product.status == ProductStatus.pending
                          ? Colors.orange
                          : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'UGX ${product.unitPrice.toStringAsFixed(0)}',
          style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary),
        ),
      ],
    );
  }

  Widget _buildStockDetails(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _DetailRow(
              label: 'Stock Quantity',
              value: '${product.stockQuantity} units',
              textTheme: textTheme),
          const SizedBox(height: 8),
          _DetailRow(
              label: 'Condition',
              value: product.condition.displayName,
              textTheme: textTheme),
          const SizedBox(height: 8),
          _DetailRow(
              label: 'Quality Grade',
              value: product.qualityGrade,
              textTheme: textTheme),
          const SizedBox(height: 8),
          _DetailRow(
              label: 'Brand', value: product.brand, textTheme: textTheme),
          if (product.partNumber != null && product.partNumber!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DetailRow(
                label: 'Part Number',
                value: product.partNumber!,
                textTheme: textTheme),
          ],
        ],
      ),
    );
  }

  Widget _buildDescription(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description', style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(product.description, style: textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildNestedCompatibleModels(
      BuildContext context, TextTheme textTheme) {
    final compatibility = product.compatibility;
    if (compatibility.isEmpty) return const SizedBox.shrink();

    // Group by brand, then by model
    final Map<String, Map<String, List<int>>> groupedCompatibility = {};

    for (final vehicle in compatibility) {
      if (!groupedCompatibility.containsKey(vehicle.brand)) {
        groupedCompatibility[vehicle.brand] = {};
      }

      if (!groupedCompatibility[vehicle.brand]!.containsKey(vehicle.model)) {
        groupedCompatibility[vehicle.brand]![vehicle.model] = [];
      }

      groupedCompatibility[vehicle.brand]![vehicle.model]!
          .addAll(vehicle.compatibleYears);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Compatible Vehicles', style: textTheme.headlineSmall),
        const SizedBox(height: 12),
        ...groupedCompatibility.entries.map((brandEntry) {
          return _BrandExpansionTile(
            brand: brandEntry.key,
            models: brandEntry.value,
            textTheme: textTheme,
          );
        }).toList(),
      ],
    );
  }
}

class _BrandExpansionTile extends StatefulWidget {
  final String brand;
  final Map<String, List<int>> models;
  final TextTheme textTheme;

  const _BrandExpansionTile({
    required this.brand,
    required this.models,
    required this.textTheme,
  });

  @override
  State<_BrandExpansionTile> createState() => _BrandExpansionTileState();
}

class _BrandExpansionTileState extends State<_BrandExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              Icon(
                Icons.directions_car,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.brand.toUpperCase(),
                style: widget.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.models.length} models',
                  style: widget.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          children: widget.models.entries.map((modelEntry) {
            return _ModelExpansionTile(
              model: modelEntry.key,
              years: modelEntry.value,
              textTheme: widget.textTheme,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ModelExpansionTile extends StatefulWidget {
  final String model;
  final List<int> years;
  final TextTheme textTheme;

  const _ModelExpansionTile({
    required this.model,
    required this.years,
    required this.textTheme,
  });

  @override
  State<_ModelExpansionTile> createState() => _ModelExpansionTileState();
}

class _ModelExpansionTileState extends State<_ModelExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sortedYears = List<int>.from(widget.years)..sort();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          title: Row(
            children: [
              Icon(
                Icons.settings,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.model,
                  style: widget.textTheme.bodyLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${sortedYears.length} years',
                  style: widget.textTheme.bodySmall?.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: sortedYears.map((year) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      year.toString(),
                      style: widget.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextTheme textTheme;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium),
          Text(value,
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Image Gallery View for full-screen image viewing
class _ImageGalleryView extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageGalleryView({
    required this.images,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(images[index]),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(tag: images[index]),
              );
            },
            itemCount: images.length,
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? null
                    : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              ),
            ),
            pageController: PageController(initialPage: initialIndex),
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
