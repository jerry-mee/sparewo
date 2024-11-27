import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification.dart';
import '../constants/notification_types.dart';
import '../constants/enums.dart';
import '../exceptions/api_exceptions.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize(String vendorId) async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await _messaging.getToken();
        if (token != null) {
          await updateFCMToken(vendorId, token);
        }

        _messaging.onTokenRefresh.listen((newToken) {
          updateFCMToken(vendorId, newToken);
        });

        // Configure message handling
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
        FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      }
    } catch (e) {
      throw ApiException(
        message: 'Failed to initialize notifications: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<void> updateFCMToken(String vendorId, String token) async {
    try {
      await _firestore.collection('vendors').doc(vendorId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ApiException(
        message: 'Failed to update FCM token: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<List<VendorNotification>> getVendorNotifications(
      String vendorId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VendorNotification.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch notifications: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Stream<List<VendorNotification>> watchVendorNotifications(String vendorId) {
    return _firestore
        .collection('notifications')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VendorNotification.fromFirestore(doc))
            .toList());
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ApiException(
        message: 'Failed to mark notification as read: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<void> markAllAsRead(String vendorId) async {
    try {
      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('vendorId', isEqualTo: vendorId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw ApiException(
        message: 'Failed to mark all notifications as read: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete notification: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<void> sendOrderStatusNotification({
    required String orderId,
    required OrderStatus status,
  }) async {
    try {
      final order = await _firestore.collection('orders').doc(orderId).get();
      if (!order.exists) return;

      final orderData = order.data()!;
      final vendorId = orderData['vendorId'] as String;
      final customerName = orderData['customerName'] as String;
      final productName = orderData['productName'] as String;

      String title;
      String message;
      switch (status) {
        case OrderStatus.accepted:
          title = 'Order Accepted';
          message = 'Your order for $productName has been accepted';
          break;
        case OrderStatus.processing:
          title = 'Order Processing';
          message = 'Your order for $productName is being processed';
          break;
        case OrderStatus.readyForDelivery:
          title = 'Order Ready';
          message = 'Your order for $productName is ready for delivery';
          break;
        case OrderStatus.delivered:
          title = 'Order Delivered';
          message = 'Your order for $productName has been delivered';
          break;
        case OrderStatus.cancelled:
        case OrderStatus.rejected:
          title = 'Order Cancelled';
          message = 'Your order for $productName has been cancelled';
          break;
        default:
          title = 'Order Update';
          message = 'Your order status has been updated';
      }

      await createNotification(
        vendorId: vendorId,
        title: title,
        message: message,
        type: NotificationType.orderUpdate,
        data: {
          'orderId': orderId,
          'status': status.toString(),
        },
      );
    } catch (e) {
      throw ApiException(
        message: 'Failed to send order status notification: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<void> createNotification({
    required String vendorId,
    required String title,
    required String message,
    required NotificationType type,
    required Map<String, dynamic> data,
    String? imageUrl,
  }) async {
    try {
      final notification = VendorNotification(
        id: '',
        vendorId: vendorId,
        title: title,
        message: message,
        type: type,
        data: data,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _firestore
          .collection('notifications')
          .add(notification.toFirestore());
    } catch (e) {
      throw ApiException(
        message: 'Failed to create notification: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Handle foreground message
    print('Received foreground message: ${message.messageId}');
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    // Handle when app is opened from notification
    print('App opened from notification: ${message.messageId}');
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background message
    print('Handling background message: ${message.messageId}');
  }
}
