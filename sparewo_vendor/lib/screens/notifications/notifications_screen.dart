// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import '../../providers/providers.dart';
import '../../models/notification.dart';
import '../../routes/app_router.dart';
import '../../constants/enums.dart';
import 'notification_list_item.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all as read after viewing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _markAllAsRead();
        }
      });
    });
  }

  Future<void> _markAllAsRead() async {
    final notificationService = ref.read(notificationServiceProvider);
    final vendorId = ref.read(currentVendorIdProvider);
    if (vendorId != null) {
      final notifications = await ref.read(notificationsStreamProvider.future);
      for (final notification in notifications) {
        if (!notification.isRead) {
          await notificationService.markAsRead(notification.id);
        }
      }
    }
  }

  void _handleNotificationTap(VendorNotification notification) {
    // Mark as read
    if (!notification.isRead) {
      ref.read(notificationServiceProvider).markAsRead(notification.id);
    }

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.productUpdate:
        // Navigate to products list - product detail would need productId in data
        Navigator.pushReplacementNamed(context, AppRouter.products);
        break;
      case NotificationType.order:
      case NotificationType.orderUpdate:
        // Navigate to orders
        Navigator.pushReplacementNamed(context, AppRouter.orders);
        break;
      case NotificationType.stockAlert:
        // Navigate to products
        Navigator.pushReplacementNamed(context, AppRouter.products);
        break;
      default:
        // Just mark as read
        break;
    }
  }

  List<Map<String, dynamic>> _groupNotificationsByDate(
      List<VendorNotification> notifications) {
    final Map<String, List<VendorNotification>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final notification in notifications) {
      final date = notification.createdAt;
      final dateOnly = DateTime(date.year, date.month, date.day);

      String dateKey;
      if (dateOnly == today) {
        dateKey = 'Today';
      } else if (dateOnly == yesterday) {
        dateKey = 'Yesterday';
      } else {
        dateKey = DateFormat('MMMM d, y').format(date);
      }

      grouped[dateKey] ??= [];
      grouped[dateKey]!.add(notification);
    }

    return grouped.entries
        .map((e) => {'date': e.key, 'notifications': e.value})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'mark_all_read') {
                _markAllAsRead();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Text('Mark all as read'),
              ),
            ],
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Product updates and order notifications will appear here',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            );
          }

          // Group notifications by date
          final groupedNotifications = _groupNotificationsByDate(notifications);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: groupedNotifications.length,
            itemBuilder: (context, index) {
              final group = groupedNotifications[index];
              final dateNotifications =
                  group['notifications'] as List<VendorNotification>;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      group['date'] as String,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  ...dateNotifications
                      .map((notification) => NotificationListItem(
                            notification: notification,
                            onTap: () => _handleNotificationTap(notification),
                          )),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Error loading notifications',
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(notificationsStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
