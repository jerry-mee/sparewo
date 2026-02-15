// lib/features/my_car/data/car_data_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';

/// Result object for global car search.
class CarSearchResult {
  final String brand;
  final String model;

  const CarSearchResult({required this.brand, required this.model});

  String get displayName => '$brand $model';

  bool matches(String query) {
    final q = query.toLowerCase();
    return brand.toLowerCase().contains(q) ||
        model.toLowerCase().contains(q) ||
        displayName.toLowerCase().contains(q);
  }
}

class CarDataRepository {
  static const String _brandCollection = 'car_brand';
  static const String _modelCollection = 'car_models';

  final FirebaseFirestore _firestore;

  // In-memory cache for global search to prevent hammering Firestore
  List<CarSearchResult>? _cachedAllModels;

  CarDataRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // --- Brand & Model Lookups ---

  Future<List<String>> getCarBrands() async {
    try {
      final snapshot = await _firestore
          .collection(_brandCollection)
          .get(const GetOptions(source: Source.server));

      final brands =
          snapshot.docs
              .map((doc) {
                final data = doc.data();
                final dynamic rawName = data['name'] ?? data['part_name'];
                if (rawName is String) {
                  final value = rawName.trim();
                  if (value.isNotEmpty) return value;
                }
                return null;
              })
              .whereType<String>()
              .toSet()
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      return brands;
    } catch (e, st) {
      AppLogger.error(
        'CarDataRepository',
        'Failed to fetch brands',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<List<String>> getCarModels(String brandName) async {
    final trimmedBrand = brandName.trim();
    if (trimmedBrand.isEmpty) return [];

    try {
      // 1. Find Brand ID
      final brandQuery = await _firestore
          .collection(_brandCollection)
          .where('part_name', isEqualTo: trimmedBrand)
          .limit(1)
          .get(const GetOptions(source: Source.server));

      if (brandQuery.docs.isEmpty) return [];

      final brandDoc = brandQuery.docs.first;
      final brandData = brandDoc.data();
      final dynamic rawId = brandData['id'];

      int? numericId;
      if (rawId is int) {
        numericId = rawId;
      } else if (rawId is String) {
        numericId = int.tryParse(rawId);
      }

      if (numericId == null) return [];

      // 2. Find Models by Brand ID
      final primaryModelsSnapshot = await _firestore
          .collection(_modelCollection)
          .where('car_makeid', isEqualTo: numericId)
          .get(const GetOptions(source: Source.server));

      QuerySnapshot<Map<String, dynamic>>? secondaryModelsSnapshot;

      if (primaryModelsSnapshot.docs.isEmpty) {
        secondaryModelsSnapshot = await _firestore
            .collection(_modelCollection)
            .where('car_makeid', isEqualTo: numericId.toString())
            .get(const GetOptions(source: Source.server));
      }

      final allDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[
        ...primaryModelsSnapshot.docs,
        if (secondaryModelsSnapshot != null) ...secondaryModelsSnapshot.docs,
      ];

      final models =
          allDocs
              .map((doc) {
                final data = doc.data();
                final dynamic rawModel = data['model'];
                if (rawModel is String) {
                  final m = rawModel.trim();
                  if (m.isNotEmpty) return m;
                }
                return null;
              })
              .whereType<String>()
              .toSet()
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      return models;
    } catch (e, st) {
      AppLogger.error(
        'CarDataRepository',
        'Failed to fetch models',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  List<int> getAvailableYears() {
    final currentYear = DateTime.now().year;
    return List.generate(currentYear - 1989, (index) => currentYear - index);
  }

  // --- Search Logic ---

  Future<List<String>> searchBrands(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];
    final brands = await getCarBrands();
    return brands
        .where((b) => b.toLowerCase().contains(normalized))
        .take(10)
        .toList();
  }

  Future<List<String>> searchModels(String brand, String query) async {
    final models = await getCarModels(brand);
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return models;
    return models
        .where((m) => m.toLowerCase().contains(normalized))
        .take(10)
        .toList();
  }

  // --- NEW: Global Model Search ---

  Future<List<CarSearchResult>> _loadAllModelsOnce() async {
    if (_cachedAllModels != null) return _cachedAllModels!;

    try {
      // Load brand ID -> Name map
      final brandSnapshot = await _firestore.collection(_brandCollection).get();
      final brandIdToName = <String, String>{};

      for (final doc in brandSnapshot.docs) {
        final data = doc.data();
        final dynamic rawId = data['id'] ?? data['car_makeid'] ?? doc.id;
        final idKey = rawId.toString();
        final dynamic rawName = data['part_name'] ?? data['name'];

        if (rawName is String && rawName.trim().isNotEmpty) {
          brandIdToName[idKey] = rawName.trim();
        }
      }

      // Load all models
      final modelSnapshot = await _firestore.collection(_modelCollection).get();
      final results = <CarSearchResult>[];

      for (final doc in modelSnapshot.docs) {
        final data = doc.data();
        final dynamic rawModel = data['model'];
        if (rawModel is! String) continue;

        final modelName = rawModel.trim();
        if (modelName.isEmpty) continue;

        final dynamic rawMakeId = data['car_makeid'] ?? data['brandId'];
        if (rawMakeId == null) continue;

        final brandName = brandIdToName[rawMakeId.toString()];
        if (brandName == null || brandName.isEmpty) continue;

        results.add(CarSearchResult(brand: brandName, model: modelName));
      }

      // Dedup and sort
      final uniqueResults = <String, CarSearchResult>{};
      for (var r in results) {
        uniqueResults[r.displayName] = r;
      }

      final sorted = uniqueResults.values.toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));

      _cachedAllModels = sorted;
      return sorted;
    } catch (e, st) {
      AppLogger.error(
        'CarDataRepository',
        'Failed to load global models',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<List<CarSearchResult>> searchModelsGlobally(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final allModels = await _loadAllModelsOnce();
    return allModels.where((m) => m.matches(q)).take(30).toList();
  }
}
