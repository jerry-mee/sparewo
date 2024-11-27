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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return VendorColors.pending;
      case OrderStatus.accepted:
        return VendorColors.primary;
      case OrderStatus.processing:
        return VendorColors.primary;
      case OrderStatus.readyForDelivery:
        return VendorColors.approved;
      case OrderStatus.delivered:
        return VendorColors.success;
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return VendorColors.error;
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
              style: VendorTextStyles.body1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                order.status.name.toUpperCase(),
                style: VendorTextStyles.caption.copyWith(
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
              style: VendorTextStyles.body2,
            ),
            const SizedBox(height: 4),
            Text(
              order.productName,
              style: VendorTextStyles.body2,
            ),
            const SizedBox(height: 4),
            Text(
              'UGX ${order.totalAmount.toStringAsFixed(2)}',
              style: VendorTextStyles.body2.copyWith(
                color: VendorColors.primary,
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
