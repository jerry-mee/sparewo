// lib/features/cart/domain/cart_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sparewo_client/features/cart/domain/cart_item_model.dart';

part 'cart_model.freezed.dart';
part 'cart_model.g.dart';

@freezed
abstract class CartModel with _$CartModel {
  const CartModel._();

  const factory CartModel({@Default([]) List<CartItemModel> items}) =
      _CartModel;

  factory CartModel.fromJson(Map<String, dynamic> json) =>
      _$CartModelFromJson(json);

  // Custom getter requires the class to be abstract
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}
