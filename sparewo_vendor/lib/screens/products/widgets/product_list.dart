import 'package:flutter/material.dart';
import '../../../models/vehicle_compatibility.dart';
import '../../../theme.dart';
import '../../../constants/enums.dart';

class ProductList extends StatelessWidget {
  final List<CarPart> products;
  final Function(CarPart)? onProductTap;
  final bool showStatus;
  final bool showActions;

  const ProductList({
    super.key,
    required this.products,
    this.onProductTap,
    this.showStatus = true,
    this.showActions = true,
  });

  Color _getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.pending:
        return VendorColors.pending;
      case ProductStatus.approved:
        return VendorColors.approved;
      case ProductStatus.rejected:
        return VendorColors.rejected;
      case ProductStatus.suspended:
        return VendorColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: onProductTap != null ? () => onProductTap!(product) : null,
            contentPadding: const EdgeInsets.all(16),
            leading: product.images.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.images.first,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image),
                  ),
            title: Text(
              product.name,
              style: VendorTextStyles.body1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'UGX ${product.price.toStringAsFixed(2)}',
                  style: VendorTextStyles.body2.copyWith(
                    color: VendorColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Stock: ${product.quantity}',
                      style: VendorTextStyles.body2,
                    ),
                    if (showStatus) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(product.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.status.name.toUpperCase(),
                          style: VendorTextStyles.caption.copyWith(
                            color: _getStatusColor(product.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (product.isOutOfStock) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: VendorColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'OUT OF STOCK',
                          style: VendorTextStyles.caption.copyWith(
                            color: VendorColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (product.compatibleVehicles.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Compatible with: ${_formatCompatibility(product.compatibleVehicles)}',
                    style: VendorTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            trailing: showActions
                ? IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: onProductTap != null
                        ? () => onProductTap!(product)
                        : null,
                  )
                : null,
          ),
        );
      },
    );
  }

  String _formatCompatibility(List<VehicleCompatibility> compatibilities) {
    if (compatibilities.isEmpty) return 'No compatibility info';

    // Take first 2 compatibilities for display
    final displayCompatibilities = compatibilities.take(2).map((c) {
      return '${c.brand} ${c.model} (${_formatYears(c.compatibleYears)})';
    }).join(', ');

    // Add ellipsis if there are more
    if (compatibilities.length > 2) {
      return '$displayCompatibilities, ...';
    }
    return displayCompatibilities;
  }

  String _formatYears(List<int> years) {
    if (years.isEmpty) return 'N/A';
    if (years.length == 1) return years.first.toString();

    // Sort years
    years.sort();

    // Find consecutive ranges
    List<String> ranges = [];
    int start = years.first;
    int prev = start;

    for (int i = 1; i < years.length; i++) {
      if (years[i] != prev + 1) {
        // End of a range
        if (start == prev) {
          ranges.add(start.toString());
        } else {
          ranges.add('$start-$prev');
        }
        start = years[i];
      }
      prev = years[i];
    }

    // Add the last range
    if (start == prev) {
      ranges.add(start.toString());
    } else {
      ranges.add('$start-$prev');
    }

    return ranges.join(', ');
  }
}
