import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import '../constants/enums.dart';
import '../exceptions/api_exceptions.dart';

class OrderService {
  final FirebaseFirestore _firestore;

  OrderService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  Future<List<VendorOrder>> getVendorOrders(String vendorId) async {
    try {
      final querySnapshot = await _ordersRef
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VendorOrder.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch orders: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Stream<List<VendorOrder>> watchVendorOrders(String vendorId) {
    return _ordersRef
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VendorOrder.fromFirestore(doc))
            .toList());
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final batch = _firestore.batch();
      final orderRef = _ordersRef.doc(orderId);

      final statusUpdate = {
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      switch (newStatus) {
        case OrderStatus.accepted:
          statusUpdate['acceptedAt'] = FieldValue.serverTimestamp();
          break;
        case OrderStatus.processing:
          statusUpdate['processedAt'] = FieldValue.serverTimestamp();
          break;
        case OrderStatus.readyForDelivery:
          statusUpdate['readyAt'] = FieldValue.serverTimestamp();
          break;
        case OrderStatus.delivered:
          statusUpdate['deliveredAt'] = FieldValue.serverTimestamp();
          statusUpdate['completedAt'] = FieldValue.serverTimestamp();
          break;
        case OrderStatus.cancelled:
        case OrderStatus.rejected:
          statusUpdate['cancelledAt'] = FieldValue.serverTimestamp();
          break;
        default:
          break;
      }

      batch.update(orderRef, statusUpdate);

      if (newStatus == OrderStatus.accepted) {
        final order = await orderRef.get();
        final data = order.data()!;

        // Update product stock
        final productRef =
            _firestore.collection('products').doc(data['productId'] as String);
        batch.update(productRef, {
          'stockQuantity': FieldValue.increment(-(data['quantity'] as int)),
          'orders': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update vendor stats
        final vendorRef =
            _firestore.collection('vendors').doc(data['vendorId'] as String);
        if (newStatus == OrderStatus.delivered) {
          batch.update(vendorRef, {
            'completedOrders': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      throw ApiException(
        message: 'Failed to update order status: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<void> acceptOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.accepted);
  }

  Future<void> rejectOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.rejected);
  }

  Future<VendorOrder> getOrder(String orderId) async {
    try {
      final doc = await _ordersRef.doc(orderId).get();
      if (!doc.exists) {
        throw const ApiException(
          message: 'Order not found',
          statusCode: 404,
        );
      }
      return VendorOrder.fromFirestore(doc);
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch order: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Stream<VendorOrder> watchOrder(String orderId) {
    return _ordersRef.doc(orderId).snapshots().map(VendorOrder.fromFirestore);
  }

  Future<List<VendorOrder>> searchOrders(String vendorId, String query) async {
    try {
      // Search by customer name or order ID
      final querySnapshot = await _ordersRef
          .where('vendorId', isEqualTo: vendorId)
          .where('customerName', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('customerName',
              isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .get();

      return querySnapshot.docs
          .map((doc) => VendorOrder.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ApiException(
        message: 'Failed to search orders: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<List<VendorOrder>> filterOrders(
    String vendorId, {
    OrderStatus? status,
    bool? isPaid,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _ordersRef.where('vendorId', isEqualTo: vendorId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (isPaid != null) {
        query = query.where('isPaid', isEqualTo: isPaid);
      }

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }

      final querySnapshot =
          await query.orderBy('createdAt', descending: true).get();

      return querySnapshot.docs
          .map((doc) => VendorOrder.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ApiException(
        message: 'Failed to filter orders: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<void> updateOrderNotes(String orderId, String notes) async {
    try {
      await _ordersRef.doc(orderId).update({
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ApiException(
        message: 'Failed to update order notes: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<Map<String, dynamic>> getOrderStats(String vendorId) async {
    try {
      final querySnapshot =
          await _ordersRef.where('vendorId', isEqualTo: vendorId).get();

      int totalOrders = 0;
      int pendingOrders = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;
      double totalRevenue = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        totalOrders++;

        switch (data['status']) {
          case 'pending':
            pendingOrders++;
            break;
          case 'delivered':
            completedOrders++;
            totalRevenue += (data['totalAmount'] as num).toDouble();
            break;
          case 'cancelled':
          case 'rejected':
            cancelledOrders++;
            break;
        }
      }

      return {
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      throw ApiException(
        message: 'Failed to get order stats: ${e.toString()}',
        statusCode: 500,
      );
    }
  }
}
