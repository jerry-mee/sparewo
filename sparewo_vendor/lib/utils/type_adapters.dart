import 'package:json_annotation/json_annotation.dart';
import '../models/vehicle_compatibility.dart';

class VehicleCompatibilityJsonConverter
    implements JsonConverter<VehicleCompatibility, Map<String, dynamic>> {
  const VehicleCompatibilityJsonConverter();

  @override
  VehicleCompatibility fromJson(Map<String, dynamic> json) =>
      VehicleCompatibility.fromJson(json);

  @override
  Map<String, dynamic> toJson(VehicleCompatibility object) => object.toJson();
}
