// lib/models/vehicle_compatibility.dart

class VehicleCompatibility {
  final String brand;
  final String model;
  final List<int> compatibleYears;

  const VehicleCompatibility({
    required this.brand,
    required this.model,
    required this.compatibleYears,
  });

  VehicleCompatibility copyWith({
    String? brand,
    String? model,
    List<int>? compatibleYears,
  }) {
    return VehicleCompatibility(
      brand: brand ?? this.brand,
      model: model ?? this.model,
      compatibleYears: compatibleYears ?? this.compatibleYears,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'model': model,
      'compatibleYears': compatibleYears,
    };
  }

  factory VehicleCompatibility.fromJson(Map<String, dynamic> json) {
    return VehicleCompatibility(
      brand: json['brand'],
      model: json['model'],
      compatibleYears: List<int>.from(json['compatibleYears']),
    );
  }

  bool isYearCompatible(int year) {
    return compatibleYears.contains(year);
  }

  String get yearDisplay {
    if (compatibleYears.isEmpty) return 'No years specified';

    final sorted = List<int>.from(compatibleYears)..sort();

    if (sorted.length > 5) {
      return '${sorted.take(3).join(', ')}... (+${sorted.length - 3} more)';
    }

    return sorted.join(', ');
  }

  String get yearRangeDisplay {
    if (compatibleYears.isEmpty) return 'No years specified';

    final sorted = List<int>.from(compatibleYears)..sort();
    return '${sorted.first}-${sorted.last}';
  }

  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return brand.toLowerCase().contains(lowerQuery) ||
        model.toLowerCase().contains(lowerQuery) ||
        compatibleYears.any((year) => year.toString().contains(query));
  }
}
