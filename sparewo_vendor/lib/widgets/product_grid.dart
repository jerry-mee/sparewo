// lib/widgets/product_grid.dart
import 'package:flutter/material.dart';
import 'package:sparewo_vendor/theme.dart';
import '../models/vendor_product.dart';
import '../constants/enums.dart';

class ProductGrid extends StatelessWidget {
  final List<VendorProduct> products;
  final String? vendorId;
  final bool isAdmin;
  final ScrollController? scrollController;
  final void Function(VendorProduct)? onProductSelected;
  final void Function(VendorProduct)? onEditProduct;
  final void Function(VendorProduct)? onDeleteProduct;
  final void Function(VendorProduct)? onUpdateStock;
  final void Function(VendorProduct) onTap;
  final int lowStockThreshold;

  const ProductGrid({
    Key? key,
    required this.products,
    this.vendorId,
    this.isAdmin = false,
    this.scrollController,
    this.onProductSelected,
    this.onEditProduct,
    this.onDeleteProduct,
    this.onUpdateStock,
    required this.onTap,
    this.lowStockThreshold = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(context, product);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, VendorProduct product) {
    final isOutOfStock = product.stockQuantity <= 0;
    final isLowStock =
        product.stockQuantity > 0 && product.stockQuantity <= lowStockThreshold;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          if (onProductSelected != null) {
            onProductSelected!(product);
          } else {
            onTap(product);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.3,
                  child: product.images.isNotEmpty
                      ? Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey.shade400,
                                size: 40,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade400,
                              size: 40,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(context, product.status),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(context, product.status)
                              .withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(product.status),
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.status.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isOutOfStock || isLowStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context)
                                .extension<AppColorsExtension>()!
                                .pending,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isOutOfStock
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context)
                                        .extension<AppColorsExtension>()!
                                        .pending)
                                .withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        isOutOfStock ? 'OUT OF STOCK' : 'LOW STOCK',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.partName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brand,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UGX ${product.unitPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock: ${product.stockQuantity}',
                      style: TextStyle(
                        color: isOutOfStock
                            ? Colors.red
                            : isLowStock
                                ? Colors.orange
                                : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight:
                            isOutOfStock || isLowStock ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onEditProduct != null ||
                onDeleteProduct != null ||
                onUpdateStock != null)
              ButtonBar(
                alignment: MainAxisAlignment.end,
                buttonPadding: EdgeInsets.zero,
                children: [
                  if (onEditProduct != null)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => onEditProduct!(product),
                      tooltip: 'Edit',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  if (onUpdateStock != null)
                    IconButton(
                      icon: const Icon(Icons.inventory, size: 20),
                      onPressed: () => onUpdateStock!(product),
                      tooltip: 'Update Stock',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  if (onDeleteProduct != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () => onDeleteProduct!(product),
                      tooltip: 'Delete',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, ProductStatus status) {
    switch (status) {
      case ProductStatus.pending:
        return Theme.of(context).extension<AppColorsExtension>()!.pending;
      case ProductStatus.approved:
        return Theme.of(context).extension<AppColorsExtension>()!.approved;
      case ProductStatus.rejected:
        return Theme.of(context).extension<AppColorsExtension>()!.rejected;
      case ProductStatus.suspended:
        return Theme.of(context).colorScheme.error;
    }
  }

  IconData _getStatusIcon(ProductStatus status) {
    switch (status) {
      case ProductStatus.pending:
        return Icons.schedule;
      case ProductStatus.approved:
        return Icons.check_circle;
      case ProductStatus.rejected:
        return Icons.cancel;
      case ProductStatus.suspended:
        return Icons.pause_circle;
    }
  }
}
