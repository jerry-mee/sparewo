// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductImpl _$$ProductImplFromJson(Map<String, dynamic> json) =>
    _$ProductImpl(
      id: json['id'] as String,
      vendorId: json['vendorId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      stockQuantity: (json['stockQuantity'] as num).toInt(),
      category: json['category'] as String,
      images:
          (json['images'] as List<dynamic>).map((e) => e as String).toList(),
      carModel: json['carModel'] as String,
      yearOfManufacture: json['yearOfManufacture'] as String,
      compatibleModels: (json['compatibleModels'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      partNumber: json['partNumber'] as String?,
      status: $enumDecode(_$ProductStatusEnumMap, json['status']),
      views: (json['views'] as num?)?.toInt() ?? 0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorId': instance.vendorId,
      'title': instance.title,
      'description': instance.description,
      'price': instance.price,
      'stockQuantity': instance.stockQuantity,
      'category': instance.category,
      'images': instance.images,
      'carModel': instance.carModel,
      'yearOfManufacture': instance.yearOfManufacture,
      'compatibleModels': instance.compatibleModels,
      'partNumber': instance.partNumber,
      'status': _$ProductStatusEnumMap[instance.status]!,
      'views': instance.views,
      'orders': instance.orders,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$ProductStatusEnumMap = {
  ProductStatus.pending: 'pending',
  ProductStatus.approved: 'approved',
  ProductStatus.rejected: 'rejected',
  ProductStatus.suspended: 'suspended',
};
