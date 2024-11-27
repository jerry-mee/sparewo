import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_stats.freezed.dart';
part 'dashboard_stats.g.dart';

@freezed
class DashboardStats with _$DashboardStats {
  const factory DashboardStats({
    required int totalProducts,
    required int pendingProducts,
    required int activeProducts,
    required int outOfStockProducts,
    required int totalOrders,
    required int pendingOrders,
    required int activeOrders,
    required int completedOrders,
    required int cancelledOrders,
    required double totalSales,
    required double todaySales,
    required double weekSales,
    required double monthSales,
    required double averageOrderValue,
    required double averageRating,
    required int totalReviews,
  }) = _DashboardStats;

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);

  factory DashboardStats.empty() => const DashboardStats(
        totalProducts: 0,
        pendingProducts: 0,
        activeProducts: 0,
        outOfStockProducts: 0,
        totalOrders: 0,
        pendingOrders: 0,
        activeOrders: 0,
        completedOrders: 0,
        cancelledOrders: 0,
        totalSales: 0.0,
        todaySales: 0.0,
        weekSales: 0.0,
        monthSales: 0.0,
        averageOrderValue: 0.0,
        averageRating: 0.0,
        totalReviews: 0,
      );
}
