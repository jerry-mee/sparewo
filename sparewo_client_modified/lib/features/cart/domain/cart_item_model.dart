// lib/features/cart/domain/cart_item_model.dart
// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sparewo_client/core/utils/timestamp_converter.dart';

part 'cart_item_model.freezed.dart';
part 'cart_item_model.g.dart';

@freezed
abstract class CartItemModel with _$CartItemModel {
  const factory CartItemModel({
    required String productId,
    required int quantity,
    @TimestampConverter() required DateTime addedAt,
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _CartItemModel;

  factory CartItemModel.fromJson(Map<String, dynamic> json) =>
      _$CartItemModelFromJson(json);
}
