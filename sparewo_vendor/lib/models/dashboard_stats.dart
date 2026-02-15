// lib/models/dashboard_stats.dart

class DashboardStats {
  final int totalProducts;
  final int pendingProducts;
  final int activeProducts;
  final int outOfStockProducts;
  final int totalOrders;
  final int activeOrders;
  final int completedOrders;
  final int pendingOrders;
  final int cancelledOrders;
  final double totalSales;
  final double todaySales;
  final double weekSales;
  final double monthSales;
  final double averageOrderValue;
  final int totalReviews;
  final double averageRating;

  const DashboardStats({
    required this.totalProducts,
    required this.pendingProducts,
    required this.activeProducts,
    required this.outOfStockProducts,
    required this.totalOrders,
    required this.activeOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.cancelledOrders,
    required this.totalSales,
    required this.todaySales,
    required this.weekSales,
    required this.monthSales,
    required this.averageOrderValue,
    required this.totalReviews,
    required this.averageRating,
  });

  factory DashboardStats.empty() => const DashboardStats(
        totalProducts: 0,
        pendingProducts: 0,
        activeProducts: 0,
        outOfStockProducts: 0,
        totalOrders: 0,
        activeOrders: 0,
        completedOrders: 0,
        pendingOrders: 0,
        cancelledOrders: 0,
        totalSales: 0.0,
        todaySales: 0.0,
        weekSales: 0.0,
        monthSales: 0.0,
        averageOrderValue: 0.0,
        totalReviews: 0,
        averageRating: 0.0,
      );

  DashboardStats copyWith({
    int? totalProducts,
    int? pendingProducts,
    int? activeProducts,
    int? outOfStockProducts,
    int? totalOrders,
    int? activeOrders,
    int? completedOrders,
    int? pendingOrders,
    int? cancelledOrders,
    double? totalSales,
    double? todaySales,
    double? weekSales,
    double? monthSales,
    double? averageOrderValue,
    int? totalReviews,
    double? averageRating,
  }) {
    return DashboardStats(
      totalProducts: totalProducts ?? this.totalProducts,
      pendingProducts: pendingProducts ?? this.pendingProducts,
      activeProducts: activeProducts ?? this.activeProducts,
      outOfStockProducts: outOfStockProducts ?? this.outOfStockProducts,
      totalOrders: totalOrders ?? this.totalOrders,
      activeOrders: activeOrders ?? this.activeOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      cancelledOrders: cancelledOrders ?? this.cancelledOrders,
      totalSales: totalSales ?? this.totalSales,
      todaySales: todaySales ?? this.todaySales,
      weekSales: weekSales ?? this.weekSales,
      monthSales: monthSales ?? this.monthSales,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      totalReviews: totalReviews ?? this.totalReviews,
      averageRating: averageRating ?? this.averageRating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalProducts': totalProducts,
      'pendingProducts': pendingProducts,
      'activeProducts': activeProducts,
      'outOfStockProducts': outOfStockProducts,
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
      'totalReviews': totalReviews,
      'averageRating': averageRating,
    };
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalProducts: json['totalProducts'] ?? 0,
      pendingProducts: json['pendingProducts'] ?? 0,
      activeProducts: json['activeProducts'] ?? 0,
      outOfStockProducts: json['outOfStockProducts'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      activeOrders: json['activeOrders'] ?? 0,
      completedOrders: json['completedOrders'] ?? 0,
      pendingOrders: json['pendingOrders'] ?? 0,
      cancelledOrders: json['cancelledOrders'] ?? 0,
      totalSales: (json['totalSales'] ?? 0.0).toDouble(),
      todaySales: (json['todaySales'] ?? 0.0).toDouble(),
      weekSales: (json['weekSales'] ?? 0.0).toDouble(),
      monthSales: (json['monthSales'] ?? 0.0).toDouble(),
      averageOrderValue: (json['averageOrderValue'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
    );
  }
}
