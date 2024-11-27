import 'package:flutter/material.dart';
import '../../../models/notification.dart';
import '../../../constants/notification_types.dart';
import '../../../theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationItem extends StatelessWidget {
  final VendorNotification notification;
  final VoidCallback onTap;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.newOrder:
        return Icons.shopping_cart;
      case NotificationType.orderUpdate:
        return Icons.local_shipping;
      case NotificationType.stockAlert:
        return Icons.inventory;
      case NotificationType.accountUpdate:
        return Icons.account_circle;
      case NotificationType.promotion:
        return Icons.campaign;
      case NotificationType.system:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case NotificationType.newOrder:
        return VendorColors.primary;
      case NotificationType.orderUpdate:
        return VendorColors.secondary;
      case NotificationType.stockAlert:
        return VendorColors.error;
      case NotificationType.accountUpdate:
        return VendorColors.approved;
      case NotificationType.promotion:
        return VendorColors.success;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: notification.isRead ? 0 : 2,
      color:
          notification.isRead ? null : VendorColors.primary.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getNotificationColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(),
                  color: _getNotificationColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: VendorTextStyles.body1.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          timeago.format(notification.createdAt),
                          style: VendorTextStyles.caption.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: VendorTextStyles.body2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.imageUrl != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          notification.imageUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
