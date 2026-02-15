// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductModel _$ProductModelFromJson(
  Map<String, dynamic> json,
) => _ProductModel(
  id: json['id'] as String,
  partName: json['partName'] as String,
  description: json['description'] as String,
  brand: json['brand'] as String,
  unitPrice: (json['unitPrice'] as num).toDouble(),
  originalPrice: (json['originalPrice'] as num?)?.toDouble(),
  stockQuantity: (json['stockQuantity'] as num).toInt(),
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  category: json['category'] as String?,
  imageUrls: (json['imageUrls'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  compatibility:
      (json['compatibility'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  partNumber: json['partNumber'] as String?,
  condition: json['condition'] as String? ?? 'New',
  specifications: json['specifications'] as Map<String, dynamic>? ?? const {},
  isActive: json['isActive'] as bool? ?? true,
  isFeatured: json['isFeatured'] as bool? ?? false,
  createdAt: const TimestampConverter().fromJson(json['createdAt'] as Object),
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$ProductModelToJson(
  _ProductModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'partName': instance.partName,
  'description': instance.description,
  'brand': instance.brand,
  'unitPrice': instance.unitPrice,
  'originalPrice': instance.originalPrice,
  'stockQuantity': instance.stockQuantity,
  'categories': instance.categories,
  'category': instance.category,
  'imageUrls': instance.imageUrls,
  'compatibility': instance.compatibility,
  'partNumber': instance.partNumber,
  'condition': instance.condition,
  'specifications': instance.specifications,
  'isActive': instance.isActive,
  'isFeatured': instance.isFeatured,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};
