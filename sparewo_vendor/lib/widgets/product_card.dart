// lib/widgets/product_card.dart
import 'package:flutter/material.dart';
import '../models/vendor_product.dart';
import '../theme.dart';
import '../constants/enums.dart';

class ProductCard extends StatelessWidget {
  final VendorProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onUpdateStock;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onUpdateStock,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior:
          Clip.antiAlias, // Ensures the image stays within rounded corners
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap ??
            () => Navigator.pushNamed(
                  context,
                  '/products/detail',
                  arguments: product,
                ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(context),
            _buildProductInfo(context),
            if (onEdit != null || onDelete != null || onUpdateStock != null)
              _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          color: Colors.grey[200],
          child: product.images.isNotEmpty
              ? Image.network(
                  product.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(context),
                )
              : _buildPlaceholder(context),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(context, product.status).withOpacity(0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              product.status.name.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        if (product.stockQuantity <= 10)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'LOW STOCK',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.partName,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'UGX ${_formatNumber(product.unitPrice)}',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.inventory,
                size: 14,
                color: product.stockQuantity <= 10
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'Stock: ${product.stockQuantity}',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: product.stockQuantity <= 10
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                      fontWeight: product.stockQuantity <= 10
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
              tooltip: 'Edit',
              color: Theme.of(context).colorScheme.primary,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
          if (onUpdateStock != null)
            IconButton(
              icon: const Icon(Icons.inventory, size: 18),
              onPressed: onUpdateStock,
              tooltip: 'Update Stock',
              color: Theme.of(context).colorScheme.secondary,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, size: 18),
              onPressed: onDelete,
              tooltip: 'Delete',
              color: Theme.of(context).colorScheme.error,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    // Format with commas
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatted = number.toStringAsFixed(0);
    return formatted.replaceAllMapped(formatter, (Match m) => '${m[1]},');
  }
}
