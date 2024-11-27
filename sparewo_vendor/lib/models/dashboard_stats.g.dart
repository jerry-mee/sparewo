// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DashboardStatsImpl _$$DashboardStatsImplFromJson(Map<String, dynamic> json) =>
    _$DashboardStatsImpl(
      totalProducts: (json['totalProducts'] as num).toInt(),
      pendingProducts: (json['pendingProducts'] as num).toInt(),
      activeProducts: (json['activeProducts'] as num).toInt(),
      outOfStockProducts: (json['outOfStockProducts'] as num).toInt(),
      totalOrders: (json['totalOrders'] as num).toInt(),
      pendingOrders: (json['pendingOrders'] as num).toInt(),
      activeOrders: (json['activeOrders'] as num).toInt(),
      completedOrders: (json['completedOrders'] as num).toInt(),
      cancelledOrders: (json['cancelledOrders'] as num).toInt(),
      totalSales: (json['totalSales'] as num).toDouble(),
      todaySales: (json['todaySales'] as num).toDouble(),
      weekSales: (json['weekSales'] as num).toDouble(),
      monthSales: (json['monthSales'] as num).toDouble(),
      averageOrderValue: (json['averageOrderValue'] as num).toDouble(),
      averageRating: (json['averageRating'] as num).toDouble(),
      totalReviews: (json['totalReviews'] as num).toInt(),
    );

Map<String, dynamic> _$$DashboardStatsImplToJson(
        _$DashboardStatsImpl instance) =>
    <String, dynamic>{
      'totalProducts': instance.totalProducts,
      'pendingProducts': instance.pendingProducts,
      'activeProducts': instance.activeProducts,
      'outOfStockProducts': instance.outOfStockProducts,
      'totalOrders': instance.totalOrders,
      'pendingOrders': instance.pendingOrders,
      'activeOrders': instance.activeOrders,
      'completedOrders': instance.completedOrders,
      'cancelledOrders': instance.cancelledOrders,
      'totalSales': instance.totalSales,
      'todaySales': instance.todaySales,
      'weekSales': instance.weekSales,
      'monthSales': instance.monthSales,
      'averageOrderValue': instance.averageOrderValue,
      'averageRating': instance.averageRating,
      'totalReviews': instance.totalReviews,
    };
