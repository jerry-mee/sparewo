import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/enums.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String vendorId,
    required String title,
    required String description,
    required double price,
    required int stockQuantity,
    required String category,
    required List<String> images,
    required String carModel,
    required String yearOfManufacture,
    required List<String> compatibleModels,
    String? partNumber,
    required ProductStatus status,
    @Default(0) int views,
    @Default(0) int orders,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Product;

  const Product._();

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product.fromJson({
      'id': doc.id,
      ...data,
      'status':
          ProductStatus.values.byName(data['status'].toString().toLowerCase()),
      'createdAt': (data['createdAt'] as Timestamp).toDate(),
      'updatedAt': (data['updatedAt'] as Timestamp).toDate(),
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson()..remove('id');
    return {
      ...json,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isOutOfStock => stockQuantity <= 0;
  bool get isActive => status == ProductStatus.approved && !isOutOfStock;
  bool get isPending => status == ProductStatus.pending;
  double get discountedPrice => price; // Add discount logic if needed
}
