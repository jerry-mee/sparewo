// lib/features/my_car/domain/car_model.dart
// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparewo_client/core/utils/timestamp_converter.dart';

part 'car_model.freezed.dart';
part 'car_model.g.dart';

@freezed
abstract class CarModel with _$CarModel {
  const CarModel._();

  const factory CarModel({
    required String id,
    required String userId,
    required String make,
    required String model,
    required int year,
    String? plateNumber,
    String? vin,
    String? color,
    String? engineType,
    String? transmission,
    int? mileage,

    // Image Fields (Ensuring they are present for build_runner)
    String? frontImageUrl,
    String? sideImageUrl,

    @NullableTimestampConverter() DateTime? lastServiceDate,
    @NullableTimestampConverter() DateTime? insuranceExpiryDate,
    @Default(false) bool isDefault,
    @TimestampConverter() required DateTime createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _CarModel;

  factory CarModel.empty() => CarModel(
    id: '',
    userId: '',
    make: '',
    model: '',
    year: 0,
    createdAt: DateTime.now(),
  );

  factory CarModel.fromJson(Map<String, dynamic> json) =>
      _$CarModelFromJson(json);

  String get displayName => '$year $make $model';
}
