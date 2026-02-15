// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CarModel _$CarModelFromJson(Map<String, dynamic> json) => _CarModel(
  id: json['id'] as String,
  userId: json['userId'] as String,
  make: json['make'] as String,
  model: json['model'] as String,
  year: (json['year'] as num).toInt(),
  plateNumber: json['plateNumber'] as String?,
  vin: json['vin'] as String?,
  color: json['color'] as String?,
  engineType: json['engineType'] as String?,
  transmission: json['transmission'] as String?,
  mileage: (json['mileage'] as num?)?.toInt(),
  frontImageUrl: json['frontImageUrl'] as String?,
  sideImageUrl: json['sideImageUrl'] as String?,
  lastServiceDate: const NullableTimestampConverter().fromJson(
    json['lastServiceDate'],
  ),
  insuranceExpiryDate: const NullableTimestampConverter().fromJson(
    json['insuranceExpiryDate'],
  ),
  isDefault: json['isDefault'] as bool? ?? false,
  createdAt: const TimestampConverter().fromJson(json['createdAt'] as Object),
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$CarModelToJson(_CarModel instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'make': instance.make,
  'model': instance.model,
  'year': instance.year,
  'plateNumber': instance.plateNumber,
  'vin': instance.vin,
  'color': instance.color,
  'engineType': instance.engineType,
  'transmission': instance.transmission,
  'mileage': instance.mileage,
  'frontImageUrl': instance.frontImageUrl,
  'sideImageUrl': instance.sideImageUrl,
  'lastServiceDate': const NullableTimestampConverter().toJson(
    instance.lastServiceDate,
  ),
  'insuranceExpiryDate': const NullableTimestampConverter().toJson(
    instance.insuranceExpiryDate,
  ),
  'isDefault': instance.isDefault,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};
