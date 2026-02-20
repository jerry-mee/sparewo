import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/dashboard_stats.dart';
import '../exceptions/api_exceptions.dart';
import '../constants/enums.dart';

class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ProductStatus _parseProductStatus(dynamic raw) {
    final value = raw?.toString().toLowerCase().trim();
    if (value == null || value.isEmpty) return ProductStatus.pending;
    for (final status in ProductStatus.values) {
      if (status.name.toLowerCase() == value) return status;
    }
    return ProductStatus.pending;
  }

  OrderStatus _parseOrderStatus(dynamic raw) {
    final value = raw?.toString().toLowerCase().trim();
    if (value == null || value.isEmpty) return OrderStatus.pending;
    for (final status in OrderStatus.values) {
      if (status.name.toLowerCase() == value) return status;
    }
    return OrderStatus.pending;
  }

  Future<DashboardStats> getDashboardStats(String vendorId) async {
    try {
      final results = await Future.wait([
        _getProductStats(vendorId),
        _getOrderStats(vendorId),
        _getReviewStats(vendorId),
      ]);

      final productStats = results[0];
      final orderStats = results[1];
      final reviewStats = results[2];

      return DashboardStats(
        totalProducts: productStats['totalProducts'],
        pendingProducts: productStats['pendingProducts'],
        activeProducts: productStats['activeProducts'],
        outOfStockProducts: productStats['outOfStockProducts'],
        totalOrders: orderStats['totalOrders'],
        activeOrders: orderStats['activeOrders'],
        completedOrders: orderStats['completedOrders'],
        pendingOrders: orderStats['pendingOrders'],
        cancelledOrders: orderStats['cancelledOrders'],
        totalSales: orderStats['totalSales'],
        todaySales: orderStats['todaySales'],
        weekSales: orderStats['weekSales'],
        monthSales: orderStats['monthSales'],
        averageOrderValue: orderStats['averageOrderValue'],
        totalReviews: reviewStats['totalReviews'],
        averageRating: reviewStats['averageRating'],
      );
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch dashboard stats: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Stream<DashboardStats> watchDashboardStats(String vendorId) {
    final productsStream = _firestore
        .collection('vendor_products')
        .where('vendorId', isEqualTo: vendorId)
        .snapshots();

    final ordersStream = _firestore
        .collection('order_fulfillments')
        .where('vendorId', isEqualTo: vendorId)
        .snapshots();

    final reviewsStream = _firestore
        .collection('reviews')
        .where('vendorId', isEqualTo: vendorId)
        .snapshots();

    return Rx.combineLatest3(
      productsStream,
      ordersStream,
      reviewsStream,
      (QuerySnapshot productsSnapshot, QuerySnapshot ordersSnapshot,
          QuerySnapshot reviewsSnapshot) {
        final productStats = _calculateProductStats(productsSnapshot);
        final orderStats = _calculateOrderStats(ordersSnapshot);
        final reviewStats = _calculateReviewStats(reviewsSnapshot);

        return DashboardStats(
          totalProducts: productStats['totalProducts'],
          pendingProducts: productStats['pendingProducts'],
          activeProducts: productStats['activeProducts'],
          outOfStockProducts: productStats['outOfStockProducts'],
          totalOrders: orderStats['totalOrders'],
          activeOrders: orderStats['activeOrders'],
          completedOrders: orderStats['completedOrders'],
          pendingOrders: orderStats['pendingOrders'],
          cancelledOrders: orderStats['cancelledOrders'],
          totalSales: orderStats['totalSales'],
          todaySales: orderStats['todaySales'],
          weekSales: orderStats['weekSales'],
          monthSales: orderStats['monthSales'],
          averageOrderValue: orderStats['averageOrderValue'],
          totalReviews: reviewStats['totalReviews'],
          averageRating: reviewStats['averageRating'],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getProductStats(String vendorId) async {
    final snapshot = await _firestore
        .collection('vendor_products')
        .where('vendorId', isEqualTo: vendorId)
        .get();

    return _calculateProductStats(snapshot);
  }

  Map<String, dynamic> _calculateProductStats(QuerySnapshot snapshot) {
    int totalProducts = snapshot.docs.length;
    int pendingProducts = 0;
    int activeProducts = 0;
    int outOfStockProducts = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = _parseProductStatus(data['status']);
      final stockQuantity = (data['stockQuantity'] as num?)?.toInt() ?? 0;

      switch (status) {
        case ProductStatus.pending:
          pendingProducts++;
          break;
        case ProductStatus.approved:
          activeProducts++;
          break;
        case ProductStatus.rejected:
        case ProductStatus.suspended:
          break;
      }

      if (stockQuantity <= 0) {
        outOfStockProducts++;
      }
    }

    return {
      'totalProducts': totalProducts,
      'pendingProducts': pendingProducts,
      'activeProducts': activeProducts,
      'outOfStockProducts': outOfStockProducts,
    };
  }

  Future<Map<String, dynamic>> _getOrderStats(String vendorId) async {
    final snapshot = await _firestore
        .collection('order_fulfillments')
        .where('vendorId', isEqualTo: vendorId)
        .get();

    return _calculateOrderStats(snapshot);
  }

  Map<String, dynamic> _calculateOrderStats(QuerySnapshot snapshot) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    int totalOrders = snapshot.docs.length;
    int activeOrders = 0;
    int completedOrders = 0;
    int pendingOrders = 0;
    int cancelledOrders = 0;
    double totalSales = 0;
    double todaySales = 0;
    double weekSales = 0;
    double monthSales = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = _parseOrderStatus(data['status']);
      final amount = (data['totalVendorAmount'] as num?)?.toDouble() ?? 0.0;
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? now;

      switch (status) {
        case OrderStatus.pending:
          pendingOrders++;
          break;
        case OrderStatus.accepted:
        case OrderStatus.processing:
        case OrderStatus.readyForDelivery:
          activeOrders++;
          break;
        case OrderStatus.delivered:
          completedOrders++;
          totalSales += amount;
          if (createdAt.isAfter(today)) {
            todaySales += amount;
          }
          if (createdAt.isAfter(weekAgo)) {
            weekSales += amount;
          }
          if (createdAt.isAfter(monthAgo)) {
            monthSales += amount;
          }
          break;
        case OrderStatus.cancelled:
        case OrderStatus.rejected:
          cancelledOrders++;
          break;
      }
    }

    double averageOrderValue =
        completedOrders > 0 ? totalSales / completedOrders : 0;

    return {
      'totalOrders': totalOrders,
      'activeOrders': activeOrders,
      'completedOrders': completedOrders,
      'pendingOrders': pendingOrders,
      'cancelledOrders': cancelledOrders,
      'totalSales': totalSales,
      'todaySales': todaySales,
      'weekSales': weekSales,
      'monthSales': monthSales,
      'averageOrderValue': averageOrderValue,
    };
  }

  Future<Map<String, dynamic>> _getReviewStats(String vendorId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('vendorId', isEqualTo: vendorId)
        .get();

    return _calculateReviewStats(snapshot);
  }

  Map<String, dynamic> _calculateReviewStats(QuerySnapshot snapshot) {
    int totalReviews = snapshot.docs.length;
    double totalRating = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalRating += (data['rating'] as num).toDouble();
    }

    double averageRating = totalReviews > 0 ? totalRating / totalReviews : 0;

    return {
      'totalReviews': totalReviews,
      'averageRating': averageRating,
    };
  }
}
