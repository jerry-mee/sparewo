// lib/models/catalog_product.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CatalogProduct {
  final String id;
  final String partName;
  final String description;
  final String brand;
  final String? partNumber;
  final String condition;
  final double retailPrice;
  final Map<String, dynamic> compatibility;
  final List<String> images;
  final Map<String, dynamic> specifications;
  final bool available;
  final String estimatedDelivery;
  final String? warrantyInfo;
  final bool installationService;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? sourceVendorId;

  const CatalogProduct({
    required this.id,
    required this.partName,
    required this.description,
    required this.brand,
    this.partNumber,
    required this.condition,
    required this.retailPrice,
    required this.compatibility,
    required this.images,
    required this.specifications,
    required this.available,
    required this.estimatedDelivery,
    this.warrantyInfo,
    required this.installationService,
    required this.createdAt,
    required this.updatedAt,
    this.sourceVendorId,
  });

  CatalogProduct copyWith({
    String? id,
    String? partName,
    String? description,
    String? brand,
    String? partNumber,
    String? condition,
    double? retailPrice,
    Map<String, dynamic>? compatibility,
    List<String>? images,
    Map<String, dynamic>? specifications,
    bool? available,
    String? estimatedDelivery,
    String? warrantyInfo,
    bool? installationService,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sourceVendorId,
  }) {
    return CatalogProduct(
      id: id ?? this.id,
      partName: partName ?? this.partName,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      partNumber: partNumber ?? this.partNumber,
      condition: condition ?? this.condition,
      retailPrice: retailPrice ?? this.retailPrice,
      compatibility: compatibility ?? this.compatibility,
      images: images ?? this.images,
      specifications: specifications ?? this.specifications,
      available: available ?? this.available,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      warrantyInfo: warrantyInfo ?? this.warrantyInfo,
      installationService: installationService ?? this.installationService,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceVendorId: sourceVendorId ?? this.sourceVendorId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partName': partName,
      'description': description,
      'brand': brand,
      'partNumber': partNumber,
      'condition': condition,
      'retailPrice': retailPrice,
      'compatibility': compatibility,
      'images': images,
      'specifications': specifications,
      'available': available,
      'estimatedDelivery': estimatedDelivery,
      'warrantyInfo': warrantyInfo,
      'installationService': installationService,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sourceVendorId': sourceVendorId,
    };
  }

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    return CatalogProduct(
      id: json['id'],
      partName: json['partName'],
      description: json['description'],
      brand: json['brand'],
      partNumber: json['partNumber'],
      condition: json['condition'],
      retailPrice: (json['retailPrice'] as num).toDouble(),
      compatibility: json['compatibility'],
      images: List<String>.from(json['images']),
      specifications: json['specifications'],
      available: json['available'],
      estimatedDelivery: json['estimatedDelivery'],
      warrantyInfo: json['warrantyInfo'],
      installationService: json['installationService'],
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : json['createdAt'],
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : json['updatedAt'],
      sourceVendorId: json['sourceVendorId'],
    );
  }

  factory CatalogProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CatalogProduct.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': (data['createdAt'] as Timestamp).toDate(),
      'updatedAt': (data['updatedAt'] as Timestamp).toDate(),
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return {
      ...json,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
