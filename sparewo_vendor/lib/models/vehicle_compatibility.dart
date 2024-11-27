import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'vehicle_compatibility.freezed.dart';
part 'vehicle_compatibility.g.dart';

@freezed
class VehicleCompatibility with _$VehicleCompatibility {
  const factory VehicleCompatibility({
    required String brand,
    required String model,
    required List<int> compatibleYears,
  }) = _VehicleCompatibility;

  factory VehicleCompatibility.fromJson(Map<String, dynamic> json) =>
      _$VehicleCompatibilityFromJson(json);
}

@freezed
class CarPart with _$CarPart {
  const factory CarPart({
    required String id,
    required String vendorId,
    required String name,
    required String description,
    required double price,
    required int quantity,
    required String condition,
    required List<String> images,
    required List<VehicleCompatibility> compatibleVehicles,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(ProductStatus.pending) ProductStatus status,
    @Default(0) int views,
    @Default(0) int orders,
  }) = _CarPart;

  const CarPart._();

  factory CarPart.fromJson(Map<String, dynamic> json) =>
      _$CarPartFromJson(json);

  factory CarPart.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CarPart.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp).toDate().toIso8601String(),
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

  bool get isOutOfStock => quantity <= 0;
  bool get isNew => condition.toLowerCase() == 'new';
  bool get isActive => status == ProductStatus.approved && !isOutOfStock;
  bool get isPending => status == ProductStatus.pending;
}

enum ProductStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
  @JsonValue('suspended')
  suspended,
}

enum PartCondition {
  @JsonValue('new')
  new_,
  @JsonValue('used')
  used
}

extension PartConditionExt on PartCondition {
  String get displayName {
    switch (this) {
      case PartCondition.new_:
        return 'New';
      case PartCondition.used:
        return 'Used';
    }
  }
}
