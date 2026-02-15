// lib/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';
// FIX: Unused import removed 'package:sparewo/models/order.dart';
import '../constants/enums.dart';
import 'logger_service.dart';

class NotificationService {
  // FIX: Accept firestore instance via constructor
  final FirebaseFirestore _firestore;
  final LoggerService _logger = LoggerService.instance;

  NotificationService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  static const String collection = 'notifications';

  // Create a new notification
  Future<void> createNotification(VendorNotification notification) async {
    try {
      await _firestore
          .collection(collection)
          .doc(notification.id)
          // FIX: Use toFirestore() to be consistent with other models
          .set(notification.toFirestore());

      _logger.info('Created notification', error: {'id': notification.id});
    } catch (e) {
      _logger.error('Failed to create notification', error: e);
      throw Exception('Failed to create notification');
    }
  }

  // Alias for createNotification for backward compatibility
  Future<void> addNotification(VendorNotification notification) async {
    return createNotification(notification);
  }

  // Get vendor notifications
  Future<List<VendorNotification>> getVendorNotifications(
      String vendorId) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => VendorNotification.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.error('Failed to get notifications', error: e);
      return [];
    }
  }

  // Get unread notifications count
  Future<int> getUnreadCount(String vendorId) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('vendorId', isEqualTo: vendorId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      _logger.error('Failed to get unread count', error: e);
      return 0;
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(collection).doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
    } catch (e) {
      _logger.error('Failed to mark as read', error: e);
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String vendorId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(collection)
          .where('vendorId', isEqualTo: vendorId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();
      _logger.info('Marked all notifications as read for vendor: $vendorId');
    } catch (e) {
      _logger.error('Failed to mark all as read', error: e);
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(collection).doc(notificationId).delete();
    } catch (e) {
      _logger.error('Failed to delete notification', error: e);
    }
  }

  // Send order status notification
  Future<void> sendOrderStatusNotification({
    required String orderId,
    required OrderStatus status,
    String? vendorId,
  }) async {
    try {
      if (vendorId == null) return;

      String title = 'Order Update';
      String message = '';

      switch (status) {
        case OrderStatus.pending:
          title = 'New Order Received';
          message = 'You have received a new order #$orderId';
          break;
        case OrderStatus.accepted:
          title = 'Order Accepted';
          message = 'Order #$orderId has been accepted';
          break;
        case OrderStatus.processing:
          title = 'Order Processing';
          message = 'Order #$orderId is now being processed';
          break;
        case OrderStatus.readyForDelivery:
          title = 'Order Ready';
          message = 'Order #$orderId is ready for delivery';
          break;
        case OrderStatus.delivered:
          title = 'Order Delivered';
          message = 'Order #$orderId has been delivered successfully';
          break;
        case OrderStatus.cancelled:
          title = 'Order Cancelled';
          message = 'Order #$orderId has been cancelled';
          break;
        case OrderStatus.rejected:
          title = 'Order Rejected';
          message = 'Order #$orderId has been rejected';
          break;
      }

      final notification = VendorNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        vendorId: vendorId,
        title: title,
        message: message,
        // FIX: Replaced 'notif_types.NotificationType' with the correct 'NotificationType'
        type: NotificationType.orderUpdate,
        data: {
          'orderId': orderId,
          'status': status.toString(),
        },
        isRead: false,
        createdAt: DateTime.now(),
      );

      await createNotification(notification);
    } catch (e) {
      _logger.error('Failed to send order status notification', error: e);
    }
  }

  // Send stock alert notification
  Future<void> sendStockAlert({
    required String vendorId,
    required String productId,
    required String productName,
    required int currentStock,
  }) async {
    try {
      final notification = VendorNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        vendorId: vendorId,
        title: 'Low Stock Alert',
        message: '$productName is running low ($currentStock units remaining)',
        // FIX: Replaced 'notif_types.NotificationType' with the correct 'NotificationType'
        type: NotificationType.stockAlert,
        data: {
          'productId': productId,
          'currentStock': currentStock,
        },
        isRead: false,
        createdAt: DateTime.now(),
      );

      await createNotification(notification);
    } catch (e) {
      _logger.error('Failed to send stock alert', error: e);
    }
  }

  // Send product update notification
  Future<void> sendProductUpdateNotification({
    required String vendorId,
    required String productId,
    required String productName,
    required ProductStatus status,
  }) async {
    try {
      String message = '';
      switch (status) {
        case ProductStatus.approved:
          message = '$productName has been approved';
          break;
        case ProductStatus.rejected:
          message = '$productName has been rejected';
          break;
        case ProductStatus.suspended:
          message = '$productName has been suspended';
          break;
        case ProductStatus.pending:
          message = '$productName is pending review';
          break;
      }

      final notification = VendorNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        vendorId: vendorId,
        title: 'Product Status Update',
        message: message,
        // FIX: Replaced 'notif_types.NotificationType' with the correct 'NotificationType'
        type: NotificationType.productUpdate,
        data: {
          'productId': productId,
          'status': status.toString(),
        },
        isRead: false,
        createdAt: DateTime.now(),
      );

      await createNotification(notification);
    } catch (e) {
      _logger.error('Failed to send product update notification', error: e);
    }
  }

  // Stream operations
  Stream<List<VendorNotification>> watchVendorNotifications(String vendorId) {
    return _firestore
        .collection(collection)
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VendorNotification.fromFirestore(doc))
            .toList());
  }

  Stream<int> watchUnreadCount(String vendorId) {
    return _firestore
        .collection(collection)
        .where('vendorId', isEqualTo: vendorId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Clean old notifications (older than 30 days)
  Future<void> cleanOldNotifications(String vendorId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _firestore
          .collection(collection)
          .where('vendorId', isEqualTo: vendorId)
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _logger.info('Cleaned ${snapshot.size} old notifications');
    } catch (e) {
      _logger.error('Failed to clean old notifications', error: e);
    }
  }
}
