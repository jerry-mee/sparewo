// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_compatibility.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VehicleCompatibilityImpl _$$VehicleCompatibilityImplFromJson(
        Map<String, dynamic> json) =>
    _$VehicleCompatibilityImpl(
      brand: json['brand'] as String,
      model: json['model'] as String,
      compatibleYears: (json['compatibleYears'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$$VehicleCompatibilityImplToJson(
        _$VehicleCompatibilityImpl instance) =>
    <String, dynamic>{
      'brand': instance.brand,
      'model': instance.model,
      'compatibleYears': instance.compatibleYears,
    };

_$CarPartImpl _$$CarPartImplFromJson(Map<String, dynamic> json) =>
    _$CarPartImpl(
      id: json['id'] as String,
      vendorId: json['vendorId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      condition: json['condition'] as String,
      images:
          (json['images'] as List<dynamic>).map((e) => e as String).toList(),
      compatibleVehicles: (json['compatibleVehicles'] as List<dynamic>)
          .map((e) => VehicleCompatibility.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      status: $enumDecodeNullable(_$ProductStatusEnumMap, json['status']) ??
          ProductStatus.pending,
      views: (json['views'] as num?)?.toInt() ?? 0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$CarPartImplToJson(_$CarPartImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorId': instance.vendorId,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'quantity': instance.quantity,
      'condition': instance.condition,
      'images': instance.images,
      'compatibleVehicles': instance.compatibleVehicles,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'status': _$ProductStatusEnumMap[instance.status]!,
      'views': instance.views,
      'orders': instance.orders,
    };

const _$ProductStatusEnumMap = {
  ProductStatus.pending: 'pending',
  ProductStatus.approved: 'approved',
  ProductStatus.rejected: 'rejected',
  ProductStatus.suspended: 'suspended',
};
