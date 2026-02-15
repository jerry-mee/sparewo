// lib/models/product_draft.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_compatibility.dart';
import '../constants/enums.dart';

class ProductDraft {
  final String id;
  final String vendorId;
  final String partName;
  final String description;
  final double unitPrice;
  final int stockQuantity;
  final List<String> images;
  final List<VehicleCompatibility> compatibility;
  final PartCondition condition;
  final String qualityGrade;
  final String brand;
  final String? partNumber;
  final ProductCategory category;
  final bool isComplete;
  final DateTime lastModified;
  final DateTime createdAt;

  ProductDraft({
    required this.id,
    required this.vendorId,
    required this.partName,
    required this.description,
    required this.unitPrice,
    required this.stockQuantity,
    required this.images,
    required this.compatibility,
    required this.condition,
    required this.qualityGrade,
    required this.brand,
    this.partNumber,
    required this.category,
    this.isComplete = false,
    required this.lastModified,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'vendorId': vendorId,
      'partName': partName,
      'description': description,
      'unitPrice': unitPrice,
      'stockQuantity': stockQuantity,
      'images': images,
      'compatibility': compatibility.map((e) => e.toJson()).toList(),
      'condition': condition.name,
      'qualityGrade': qualityGrade,
      'brand': brand,
      'partNumber': partNumber,
      'category': category.name,
      'isComplete': isComplete,
      'lastModified': Timestamp.fromDate(lastModified),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ProductDraft.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Helper function to parse PartCondition safely
    PartCondition parseCondition(dynamic value) {
      if (value == null) return PartCondition.new_;

      final conditionStr = value.toString();

      // Handle legacy "new" value
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

    return ProductDraft(
      id: doc.id,
      vendorId: data['vendorId'] ?? '',
      partName: data['partName'] ?? '',
      description: data['description'] ?? '',
      unitPrice: (data['unitPrice'] ?? 0).toDouble(),
      stockQuantity: (data['stockQuantity'] ?? 0).toInt(),
      images: List<String>.from(data['images'] ?? []),
      compatibility: (data['compatibility'] as List? ?? [])
          .map((e) => VehicleCompatibility.fromJson(e as Map<String, dynamic>))
          .toList(),
      condition: parseCondition(data['condition']),
      qualityGrade: data['qualityGrade'] ?? 'A',
      brand: data['brand'] ?? '',
      partNumber: data['partNumber'],
      category: parseCategory(data['category']),
      isComplete: data['isComplete'] ?? false,
      lastModified:
          (data['lastModified'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ProductDraft copyWith({
    String? id,
    String? vendorId,
    String? partName,
    String? description,
    double? unitPrice,
    int? stockQuantity,
    List<String>? images,
    List<VehicleCompatibility>? compatibility,
    PartCondition? condition,
    String? qualityGrade,
    String? brand,
    String? partNumber,
    ProductCategory? category,
    bool? isComplete,
    DateTime? lastModified,
    DateTime? createdAt,
  }) {
    return ProductDraft(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      partName: partName ?? this.partName,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      images: images ?? this.images,
      compatibility: compatibility ?? this.compatibility,
      condition: condition ?? this.condition,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      brand: brand ?? this.brand,
      partNumber: partNumber ?? this.partNumber,
      category: category ?? this.category,
      isComplete: isComplete ?? this.isComplete,
      lastModified: lastModified ?? this.lastModified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
