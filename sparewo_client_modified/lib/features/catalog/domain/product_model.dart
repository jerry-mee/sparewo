// lib/features/catalog/domain/product_model.dart
// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sparewo_client/core/utils/timestamp_converter.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
abstract class ProductModel with _$ProductModel {
  const ProductModel._();

  const factory ProductModel({
    required String id,
    required String partName,
    required String description,
    required String brand,
    required double unitPrice,
    double? originalPrice,
    required int stockQuantity,
    @Default([]) List<String> categories,
    String? category,
    required List<String> imageUrls,
    @Default([]) List<String> compatibility,
    String? partNumber,
    @Default('New') String condition,
    @Default({}) Map<String, dynamic> specifications,
    @Default(true) bool isActive,
    @Default(false) bool isFeatured,
    @TimestampConverter() required DateTime createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  factory ProductModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ProductModel.fromJson({...data, 'id': id});
  }

  String get formattedPrice => 'UGX ${_formatCurrency(unitPrice)}';

  bool get isInStock => stockQuantity > 0;

  String get primaryCategory =>
      category ?? (categories.isNotEmpty ? categories.first : 'General');

  String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatted = amount.toStringAsFixed(0);
    return formatted.replaceAllMapped(formatter, (Match m) => '${m[1]},');
  }
}

enum ProductCategory {
  bodyKits('Body Kits'),
  tyres('Tyres'),
  electricals('Electricals'),
  accessories('Accessories'),
  chassis('Chassis'),
  engine('Engine');

  final String displayName;
  const ProductCategory(this.displayName);
}
