// lib/screens/orders/widgets/order_list_item.dart
import 'package:flutter/material.dart';
import '../../../models/order.dart';
import '../../../theme.dart';
import '../../../constants/enums.dart';

class OrderListItem extends StatelessWidget {
  final VendorOrder order;
  final VoidCallback onTap;

  const OrderListItem({
    super.key,
    required this.order,
    required this.onTap,
  });

  // FIXED: Pass context to helper method
  Color _getStatusColor(BuildContext context, OrderStatus status) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    switch (status) {
      case OrderStatus.pending:
        return colors.pending;
      case OrderStatus.accepted:
      case OrderStatus.processing:
        return Theme.of(context).colorScheme.primary;
      case OrderStatus.readyForDelivery:
        return colors.approved;
      case OrderStatus.delivered:
        return colors.success;
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return Theme.of(context).colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Text(
              'Order #${order.id}',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(context, order.status), // Pass context
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                order.status.name.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              order.customerName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              order.productName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'UGX ${order.totalAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onTap,
        ),
      ),
    );
  }
}
