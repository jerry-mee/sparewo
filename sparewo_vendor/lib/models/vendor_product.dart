// lib/models/vendor_product.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_compatibility.dart';
import '../constants/enums.dart';

class VendorProduct {
  final String id;
  final String vendorId;
  final String partName;
  final String description;
  final String brand;
  final String? partNumber;
  final PartCondition condition;
  final String qualityGrade;
  final int stockQuantity;
  final double unitPrice;
  final double? wholesalePrice;
  final List<VehicleCompatibility> compatibility;
  final List<String> images;
  final ProductStatus status;
  final ProductCategory category;
  final String? reviewNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VendorProduct({
    required this.id,
    required this.vendorId,
    required this.partName,
    required this.description,
    required this.brand,
    this.partNumber,
    required this.condition,
    required this.qualityGrade,
    required this.stockQuantity,
    required this.unitPrice,
    this.wholesalePrice,
    required this.compatibility,
    required this.images,
    this.status = ProductStatus.pending,
    required this.category,
    this.reviewNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  VendorProduct copyWith({
    String? id,
    String? vendorId,
    String? partName,
    String? description,
    String? brand,
    String? partNumber,
    PartCondition? condition,
    String? qualityGrade,
    int? stockQuantity,
    double? unitPrice,
    double? wholesalePrice,
    List<VehicleCompatibility>? compatibility,
    List<String>? images,
    ProductStatus? status,
    ProductCategory? category,
    String? reviewNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorProduct(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      partName: partName ?? this.partName,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      partNumber: partNumber ?? this.partNumber,
      condition: condition ?? this.condition,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      compatibility: compatibility ?? this.compatibility,
      images: images ?? this.images,
      status: status ?? this.status,
      category: category ?? this.category,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'partName': partName,
      'description': description,
      'brand': brand,
      'partNumber': partNumber,
      'condition': condition.name,
      'qualityGrade': qualityGrade,
      'stockQuantity': stockQuantity,
      'unitPrice': unitPrice,
      'wholesalePrice': wholesalePrice,
      'compatibility': compatibility.map((e) => e.toJson()).toList(),
      'images': images,
      'status': status.name,
      'category': category.name,
      'reviewNotes': reviewNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory VendorProduct.fromJson(Map<String, dynamic> json) {
    // Helper function to parse PartCondition safely
    PartCondition parseCondition(dynamic value) {
      if (value == null) return PartCondition.new_;

      final conditionStr = value.toString();

      // Handle legacy "new" value - this is the key fix
      if (conditionStr == 'new') {
        return PartCondition.new_;
      }

      // Try to find matching enum value
      try {
        return PartCondition.values.byName(conditionStr);
      } catch (e) {
        // Default to new_ if parsing fails
        return PartCondition.new_;
      }
    }

    // Helper function to parse ProductStatus safely
    ProductStatus parseStatus(dynamic value) {
      if (value == null) return ProductStatus.pending;

      try {
        return ProductStatus.values.byName(value.toString());
      } catch (e) {
        return ProductStatus.pending;
      }
    }

    // Helper function to parse ProductCategory safely
    ProductCategory parseCategory(dynamic value) {
      if (value == null) return ProductCategory.accessories;

      try {
        return ProductCategory.values.byName(value.toString());
      } catch (e) {
        // Default to accessories if parsing fails
        return ProductCategory.accessories;
      }
    }

    return VendorProduct(
      id: json['id'] ?? '',
      vendorId: json['vendorId'] ?? '',
      partName: json['partName'] ?? '',
      description: json['description'] ?? '',
      brand: json['brand'] ?? '',
      partNumber: json['partNumber'],
      condition: parseCondition(json['condition']),
      qualityGrade: json['qualityGrade'] ?? 'A',
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: json['wholesalePrice'] != null
          ? (json['wholesalePrice'] as num).toDouble()
          : null,
      compatibility: (json['compatibility'] as List?)
              ?.map((e) =>
                  VehicleCompatibility.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      images: List<String>.from(json['images'] ?? []),
      status: parseStatus(json['status']),
      category: parseCategory(json['category']),
      reviewNotes: json['reviewNotes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  factory VendorProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VendorProduct.fromJson({
      'id': doc.id,
      ...data,
      'createdAt':
          (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
              DateTime.now().toIso8601String(),
      'updatedAt':
          (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String() ??
              DateTime.now().toIso8601String(),
    });
  }

  factory VendorProduct.empty() => VendorProduct(
        id: '',
        vendorId: '',
        partName: '',
        description: '',
        brand: '',
        condition: PartCondition.new_,
        qualityGrade: 'A',
        stockQuantity: 0,
        unitPrice: 0.0,
        compatibility: [],
        images: [],
        status: ProductStatus.pending,
        category: ProductCategory.accessories,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');

    // Ensure condition is stored correctly for legacy compatibility
    // Always store new_ as "new_" in Firestore
    if (condition == PartCondition.new_) {
      json['condition'] = 'new_';
    }

    return {
      ...json,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'searchKeywords': _generateSearchKeywords(),
    };
  }

  List<String> _generateSearchKeywords() {
    final keywords = <String>{};
    keywords.addAll(partName.toLowerCase().split(' '));
    keywords.addAll(brand.toLowerCase().split(' '));
    if (partNumber != null) {
      keywords.add(partNumber!.toLowerCase());
    }
    keywords.addAll(description.toLowerCase().split(' '));
    keywords.add(category.name.toLowerCase());
    keywords.add(category.displayName.toLowerCase());
    return keywords.where((k) => k.isNotEmpty).toList();
  }

  bool get isOutOfStock => stockQuantity <= 0;

  double get profit => unitPrice - (wholesalePrice ?? unitPrice * 0.7);

  bool get hasDiscount => wholesalePrice != null && wholesalePrice! < unitPrice;

  double get discountPercentage => hasDiscount
      ? ((unitPrice - wholesalePrice!) / unitPrice * 100).roundToDouble()
      : 0.0;

  bool isCompatibleWith({
    required String brand,
    required String model,
    required int year,
  }) {
    return compatibility.any((vehicle) =>
        vehicle.brand.toLowerCase() == brand.toLowerCase() &&
        vehicle.model.toLowerCase() == model.toLowerCase() &&
        vehicle.compatibleYears.contains(year));
  }

  VendorProduct copyWithStock(int newQuantity) {
    return copyWith(
      stockQuantity: newQuantity,
      updatedAt: DateTime.now(),
    );
  }

  VendorProduct copyWithStatus(ProductStatus newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }
}
