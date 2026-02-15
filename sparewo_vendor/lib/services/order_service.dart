// lib/services/order_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparewo_vendor/models/vendor_product.dart';
import '../models/order.dart';
import '../constants/enums.dart';
import '../exceptions/api_exceptions.dart';
import '../services/logger_service.dart';

class OrderService {
  final FirebaseFirestore _firestore;
  final LoggerService _logger = LoggerService.instance;

  OrderService({required FirebaseFirestore firestore}) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _fulfillmentsRef =>
      _firestore.collection('order_fulfillments');

  Future<List<VendorOrder>> getVendorOrders(String vendorId) async {
    try {
      // Vendors access orders through order_fulfillments collection
      final fulfillmentSnapshot = await _fulfillmentsRef
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('createdAt', descending: true)
          .get();

      final List<VendorOrder> orders = [];

      // For each fulfillment, get the corresponding order
      for (final fulfillmentDoc in fulfillmentSnapshot.docs) {
        final fulfillmentData = fulfillmentDoc.data();
        final orderId = fulfillmentData['orderId'] as String?;

        if (orderId != null) {
          try {
            final orderDoc = await _ordersRef.doc(orderId).get();
            if (orderDoc.exists) {
              // Merge fulfillment data with order data
              final orderData = orderDoc.data()!;
              orderData['fulfillmentId'] = fulfillmentDoc.id;
              orderData['fulfillmentStatus'] = fulfillmentData['status'];

              orders.add(VendorOrder.fromFirestore(orderDoc));
            }
          } catch (e) {
            _logger.error('Failed to fetch order $orderId', error: e);
          }
        }
      }

      return orders;
    } catch (e) {
      _logger.error('Failed to fetch vendor orders', error: e);
      throw ApiException(
        message: 'Failed to fetch orders: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Stream<List<VendorOrder>> watchVendorOrders(String vendorId) {
    // Watch fulfillments for this vendor
    return _fulfillmentsRef
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((fulfillmentSnapshot) async {
      final List<VendorOrder> orders = [];

      for (final fulfillmentDoc in fulfillmentSnapshot.docs) {
        final fulfillmentData = fulfillmentDoc.data();
        final orderId = fulfillmentData['orderId'] as String?;

        if (orderId != null) {
          try {
            final orderDoc = await _ordersRef.doc(orderId).get();
            if (orderDoc.exists) {
              // Merge fulfillment data with order data
              final orderData = orderDoc.data()!;
              orderData['fulfillmentId'] = fulfillmentDoc.id;
              orderData['fulfillmentStatus'] = fulfillmentData['status'];

              orders.add(VendorOrder.fromFirestore(orderDoc));
            }
          } catch (e) {
            _logger.error('Failed to fetch order $orderId in stream', error: e);
          }
        }
      }

      return orders;
    });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final batch = _firestore.batch();

      // Get the fulfillment document for this order
      final fulfillmentQuery = await _fulfillmentsRef
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (fulfillmentQuery.docs.isEmpty) {
        throw Exception("No fulfillment found for order $orderId");
      }

      final fulfillmentRef = fulfillmentQuery.docs.first.reference;

      final statusUpdate = {
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add timestamps for specific statuses
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

      // Update the fulfillment status
      batch.update(fulfillmentRef, statusUpdate);

      // Get order data for stock management
      final orderSnap = await _ordersRef.doc(orderId).get();
      if (!orderSnap.exists) {
        throw Exception("Order not found during status update.");
      }
      final orderData = VendorOrder.fromFirestore(orderSnap);

      // Adjust stock based on the new status
      if (newStatus == OrderStatus.accepted) {
        // Decrement stock when order is accepted
        final productRef =
            _firestore.collection('vendor_products').doc(orderData.productId);
        batch.update(productRef, {
          'stockQuantity': FieldValue.increment(-orderData.quantity),
        });
      } else if (newStatus == OrderStatus.delivered) {
        // Increment completed orders for the vendor on delivery
        final vendorRef =
            _firestore.collection('vendors').doc(orderData.vendorId);
        batch.update(vendorRef, {
          'completedOrders': FieldValue.increment(1),
        });
      } else if (newStatus == OrderStatus.cancelled ||
          newStatus == OrderStatus.rejected) {
        // If an accepted order is cancelled, restore the stock
        if (orderData.status == OrderStatus.accepted ||
            orderData.status == OrderStatus.processing) {
          final productRef =
              _firestore.collection('vendor_products').doc(orderData.productId);
          batch.update(productRef, {
            'stockQuantity': FieldValue.increment(orderData.quantity),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      _logger.error('Failed to update order status', error: e);
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
      // First check if this vendor has access to this order through fulfillments
      final fulfillmentQuery = await _fulfillmentsRef
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (fulfillmentQuery.docs.isEmpty) {
        throw const ApiException(
          message: 'Order not found or access denied',
          statusCode: 404,
        );
      }

      final doc = await _ordersRef.doc(orderId).get();
      if (!doc.exists) {
        throw const ApiException(
          message: 'Order not found',
          statusCode: 404,
        );
      }

      // Add fulfillment data
      final orderData = doc.data()!;
      orderData['fulfillmentId'] = fulfillmentQuery.docs.first.id;
      orderData['fulfillmentStatus'] =
          fulfillmentQuery.docs.first.data()['status'];

      return VendorOrder.fromFirestore(doc);
    } catch (e) {
      if (e is ApiException) rethrow;
      _logger.error('Failed to fetch order', error: e);
      throw ApiException(
        message: 'Failed to fetch order: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Stream<VendorOrder> watchOrder(String orderId) {
    return _fulfillmentsRef
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .snapshots()
        .asyncMap((fulfillmentSnapshot) async {
      if (fulfillmentSnapshot.docs.isEmpty) {
        throw const ApiException(
          message: 'Order not found or access denied',
          statusCode: 404,
        );
      }

      final orderDoc = await _ordersRef.doc(orderId).get();
      if (!orderDoc.exists) {
        throw const ApiException(
          message: 'Order not found',
          statusCode: 404,
        );
      }

      // Add fulfillment data
      final orderData = orderDoc.data()!;
      orderData['fulfillmentId'] = fulfillmentSnapshot.docs.first.id;
      orderData['fulfillmentStatus'] =
          fulfillmentSnapshot.docs.first.data()['status'];

      return VendorOrder.fromFirestore(orderDoc);
    });
  }

  Future<List<VendorOrder>> searchOrders(String vendorId, String query) async {
    try {
      // Get all fulfillments for this vendor
      final fulfillmentSnapshot =
          await _fulfillmentsRef.where('vendorId', isEqualTo: vendorId).get();

      final List<VendorOrder> allOrders = [];

      for (final fulfillmentDoc in fulfillmentSnapshot.docs) {
        final fulfillmentData = fulfillmentDoc.data();
        final orderId = fulfillmentData['orderId'] as String?;

        if (orderId != null) {
          try {
            final orderDoc = await _ordersRef.doc(orderId).get();
            if (orderDoc.exists) {
              final orderData = orderDoc.data()!;

              // Check if this order matches the search query
              final customerName =
                  (orderData['customerName'] ?? '').toString().toLowerCase();
              final orderIdLower = orderId.toLowerCase();
              final queryLower = query.toLowerCase();

              if (customerName.contains(queryLower) ||
                  orderIdLower.contains(queryLower)) {
                orderData['fulfillmentId'] = fulfillmentDoc.id;
                orderData['fulfillmentStatus'] = fulfillmentData['status'];

                allOrders.add(VendorOrder.fromFirestore(orderDoc));
              }
            }
          } catch (e) {
            _logger.error('Failed to fetch order $orderId during search',
                error: e);
          }
        }
      }

      return allOrders;
    } catch (e) {
      _logger.error('Failed to search orders', error: e);
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
      // Start with fulfillments for this vendor
      Query<Map<String, dynamic>> query =
          _fulfillmentsRef.where('vendorId', isEqualTo: vendorId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final fulfillmentSnapshot = await query.get();
      final List<VendorOrder> filteredOrders = [];

      for (final fulfillmentDoc in fulfillmentSnapshot.docs) {
        final fulfillmentData = fulfillmentDoc.data();
        final orderId = fulfillmentData['orderId'] as String?;

        if (orderId != null) {
          try {
            final orderDoc = await _ordersRef.doc(orderId).get();
            if (orderDoc.exists) {
              final orderData = orderDoc.data()!;
              final order = VendorOrder.fromFirestore(orderDoc);

              // Apply additional filters
              bool includeOrder = true;

              if (isPaid != null && order.isPaid != isPaid) {
                includeOrder = false;
              }

              if (startDate != null && order.createdAt.isBefore(startDate)) {
                includeOrder = false;
              }

              if (endDate != null && order.createdAt.isAfter(endDate)) {
                includeOrder = false;
              }

              if (includeOrder) {
                orderData['fulfillmentId'] = fulfillmentDoc.id;
                orderData['fulfillmentStatus'] = fulfillmentData['status'];

                filteredOrders.add(VendorOrder.fromFirestore(orderDoc));
              }
            }
          } catch (e) {
            _logger.error('Failed to fetch order $orderId during filter',
                error: e);
          }
        }
      }

      // Sort by createdAt descending
      filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return filteredOrders;
    } catch (e) {
      _logger.error('Failed to filter orders', error: e);
      throw ApiException(
        message: 'Failed to filter orders: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<void> updateOrderNotes(String orderId, String notes) async {
    try {
      // Get the fulfillment document for this order
      final fulfillmentQuery = await _fulfillmentsRef
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (fulfillmentQuery.docs.isEmpty) {
        throw Exception("No fulfillment found for order $orderId");
      }

      await fulfillmentQuery.docs.first.reference.update({
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.error('Failed to update order notes', error: e);
      throw ApiException(
        message: 'Failed to update order notes: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<Map<String, dynamic>> getOrderStats(String vendorId) async {
    try {
      // Get all fulfillments for this vendor
      final fulfillmentSnapshot =
          await _fulfillmentsRef.where('vendorId', isEqualTo: vendorId).get();

      int totalOrders = 0;
      int pendingOrders = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;
      double totalRevenue = 0;

      for (var fulfillmentDoc in fulfillmentSnapshot.docs) {
        final data = fulfillmentDoc.data();
        totalOrders++;

        final status = OrderStatus.values.byName(data['status'] ?? 'pending');

        switch (status) {
          case OrderStatus.pending:
            pendingOrders++;
            break;
          case OrderStatus.delivered:
            completedOrders++;
            // Get order details for revenue
            final orderId = data['orderId'] as String?;
            if (orderId != null) {
              try {
                final orderDoc = await _ordersRef.doc(orderId).get();
                if (orderDoc.exists) {
                  final orderData = orderDoc.data()!;
                  totalRevenue +=
                      (orderData['totalAmount'] as num?)?.toDouble() ?? 0;
                }
              } catch (e) {
                _logger.error('Failed to fetch order $orderId for stats',
                    error: e);
              }
            }
            break;
          case OrderStatus.cancelled:
          case OrderStatus.rejected:
            cancelledOrders++;
            break;
          default:
            // Handle other active statuses if needed
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
      _logger.error('Failed to get order stats', error: e);
      throw ApiException(
        message: 'Failed to get order stats: ${e.toString()}',
        statusCode: 500,
      );
    }
  }
}
