// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CartItemModel _$CartItemModelFromJson(Map<String, dynamic> json) =>
    _CartItemModel(
      productId: json['productId'] as String,
      quantity: (json['quantity'] as num).toInt(),
      addedAt: const TimestampConverter().fromJson(json['addedAt'] as Object),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$CartItemModelToJson(
  _CartItemModel instance,
) => <String, dynamic>{
  'productId': instance.productId,
  'quantity': instance.quantity,
  'addedAt': const TimestampConverter().toJson(instance.addedAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};
