import 'package:flutter/material.dart';
import '../../../models/vehicle_compatibility.dart';
import '../../../theme.dart';
import '../../../constants/enums.dart';

class ProductItem extends StatelessWidget {
  final CarPart product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductItem({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
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
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.images.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.images.first,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: VendorTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(product.status)
                                    .withOpacity(0.1),
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
                            const SizedBox(width: 8),
                            Text(
                              'Stock: ${product.quantity}',
                              style: VendorTextStyles.body2,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (product.compatibleVehicles.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Compatible Vehicles:',
                  style: VendorTextStyles.body2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: product.compatibleVehicles
                      .map((compatibility) => Chip(
                            label: Text(
                              '${compatibility.brand} ${compatibility.model}',
                              style: VendorTextStyles.caption,
                            ),
                            backgroundColor:
                                VendorColors.primary.withOpacity(0.1),
                          ))
                      .toList(),
                ),
              ],
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete,
                          color: VendorColors.error,
                        ),
                        label: Text(
                          'Delete',
                          style: TextStyle(
                            color: VendorColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
