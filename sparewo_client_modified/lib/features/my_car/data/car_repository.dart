// lib/features/my_car/data/car_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/features/my_car/domain/car_model.dart';

class CarRepository {
  final FirebaseFirestore _firestore;
  final String? userId;

  CarRepository({required this.userId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get user's cars
  Stream<List<CarModel>> getUserCars() async* {
    if (userId == null) {
      AppLogger.warn('CarRepository', 'userId is null in getUserCars');
      yield const <CarModel>[];
      return;
    }

    AppLogger.debug(
      'CarRepository',
      'Subscribing to user cars',
      extra: {'userId': userId},
    );

    try {
      final stream = _firestore
          .collection('users')
          .doc(userId)
          .collection('cars')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error, stackTrace) {
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              AppLogger.warn(
                'CarRepository',
                'Permission denied in cars snapshot stream',
                extra: {'userId': userId},
              );
              return;
            }

            throw error;
          });

      await for (final snapshot in stream) {
        final cars = snapshot.docs.map((doc) {
          return CarModel.fromJson(_normalizeCarData(doc.id, doc.data()));
        }).toList();

        AppLogger.debug(
          'CarRepository',
          'Received snapshot',
          extra: {'userId': userId, 'count': cars.length},
        );

        yield cars;
      }
    } on FirebaseException catch (error, stack) {
      if (error.code == 'permission-denied') {
        AppLogger.warn(
          'CarRepository',
          'Permission denied in getUserCars; returning empty stream',
          extra: {'userId': userId},
        );
        yield const <CarModel>[];
        return;
      }

      AppLogger.error(
        'CarRepository',
        'Stream error in getUserCars',
        error: error,
        stackTrace: stack,
        extra: {'userId': userId},
      );
      rethrow;
    }
  }

  // Get a specific car
  Future<CarModel?> getCarById(String carId) async {
    if (userId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cars')
          .doc(carId)
          .get();

      if (!doc.exists) return null;

      return CarModel.fromJson(_normalizeCarData(doc.id, doc.data()!));
    } catch (e, st) {
      AppLogger.error(
        'CarRepository',
        'Error getting car by ID',
        error: e,
        stackTrace: st,
        extra: {'userId': userId, 'carId': carId},
      );
      rethrow;
    }
  }

  // Add a new car
  Future<void> addCar({
    required String make,
    required String model,
    required int year,
    String? plateNumber,
    String? vin,
    String? color,
    String? engineType,
    String? transmission,
    int? mileage,
    String? frontImageUrl,
    String? sideImageUrl,
    DateTime? lastServiceDate,
    DateTime? insuranceExpiryDate,
  }) async {
    if (userId == null) {
      throw Exception('User must be logged in to add a car.');
    }

    try {
      final batch = _firestore.batch();

      // 1. Set all existing cars to isDefault = false
      final existingCars = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cars')
          .get();

      for (final doc in existingCars.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      // 2. Add new car as default
      final newCarRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cars')
          .doc();

      final carData = {
        'userId': userId,
        'make': make,
        'model': model,
        'year': year,
        'plateNumber': plateNumber,
        'vin': vin,
        'color': color,
        'colour': color,
        'engineType': engineType,
        'engineSize': engineType,
        'transmission': transmission,
        'mileage': mileage,
        'frontImageUrl': frontImageUrl,
        'sideImageUrl': sideImageUrl,
        'photoUrls': <String>[
          if (frontImageUrl != null && frontImageUrl.trim().isNotEmpty)
            frontImageUrl.trim(),
          if (sideImageUrl != null && sideImageUrl.trim().isNotEmpty)
            sideImageUrl.trim(),
        ],
        'lastServiceDate': lastServiceDate != null
            ? Timestamp.fromDate(lastServiceDate)
            : null,
        'insuranceExpiryDate': insuranceExpiryDate != null
            ? Timestamp.fromDate(insuranceExpiryDate)
            : null,
        'isDefault': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Remove nulls to keep Firestore clean
      carData.removeWhere((key, value) => value == null);

      batch.set(newCarRef, carData);
      await batch.commit();

      AppLogger.info(
        'CarRepository',
        'Added car $make $model',
        extra: {'userId': userId, 'carId': newCarRef.id},
      );
    } catch (e, st) {
      AppLogger.error(
        'CarRepository',
        'Error adding car',
        error: e,
        stackTrace: st,
        extra: {'userId': userId, 'make': make, 'model': model},
      );
      rethrow;
    }
  }

  // Update a car
  Future<void> updateCar(String carId, Map<String, dynamic> data) async {
    if (userId == null) throw Exception('User required.');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cars')
          .doc(carId)
          .update({
            ..._prepareCarUpdateData(data),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.info(
        'CarRepository',
        'Updated car $carId',
        extra: {'userId': userId},
      );
    } catch (e, st) {
      AppLogger.error(
        'CarRepository',
        'Error updating car',
        error: e,
        stackTrace: st,
        extra: {'userId': userId, 'carId': carId, 'data': data},
      );
      rethrow;
    }
  }

  // Delete a car
  Future<void> deleteCar(String carId) async {
    if (userId == null) throw Exception('User required.');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cars')
          .doc(carId)
          .delete();

      AppLogger.info(
        'CarRepository',
        'Deleted car $carId',
        extra: {'userId': userId},
      );
    } catch (e, st) {
      AppLogger.error(
        'CarRepository',
        'Error deleting car',
        error: e,
        stackTrace: st,
        extra: {'userId': userId, 'carId': carId},
      );
      rethrow;
    }
  }

  // Set a car as default
  Future<void> setDefaultCar(String carId) async {
    if (userId == null) throw Exception('User required.');

    try {
      final batch = _firestore.batch();

      final cars = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cars')
          .get();

      for (final doc in cars.docs) {
        // If it's the selected car, set true, else false
        batch.update(doc.reference, {'isDefault': doc.id == carId});
      }

      await batch.commit();

      AppLogger.info(
        'CarRepository',
        'Set default car $carId',
        extra: {'userId': userId},
      );
    } catch (e, st) {
      AppLogger.error(
        'CarRepository',
        'Error setting default car',
        error: e,
        stackTrace: st,
        extra: {'userId': userId, 'carId': carId},
      );
      rethrow;
    }
  }

  Map<String, dynamic> _prepareCarUpdateData(Map<String, dynamic> data) {
    final mapped = Map<String, dynamic>.from(data);

    final mileage = mapped['mileage'];
    if (mileage is String) {
      mapped['mileage'] = _parseMileage(mileage);
    }

    final colour = mapped['color'];
    if (colour is String && colour.trim().isNotEmpty) {
      mapped['color'] = colour.trim();
      mapped['colour'] = colour.trim();
    }

    final engineSize = mapped['engineType'];
    if (engineSize is String && engineSize.trim().isNotEmpty) {
      mapped['engineType'] = engineSize.trim();
      mapped['engineSize'] = engineSize.trim();
    }

    final lastService = mapped['lastServiceDate'];
    if (lastService is DateTime) {
      mapped['lastServiceDate'] = Timestamp.fromDate(lastService);
    }

    final insurance = mapped['insuranceExpiryDate'];
    if (insurance is DateTime) {
      mapped['insuranceExpiryDate'] = Timestamp.fromDate(insurance);
    }

    final front = mapped['frontImageUrl'];
    final side = mapped['sideImageUrl'];
    if (front is String || side is String) {
      mapped['photoUrls'] = <String>[
        if (front is String && front.trim().isNotEmpty) front.trim(),
        if (side is String && side.trim().isNotEmpty) side.trim(),
      ];
    }

    mapped.removeWhere((key, value) => value == null);
    return mapped;
  }

  Map<String, dynamic> _normalizeCarData(
    String docId,
    Map<String, dynamic> rawData,
  ) {
    final photoUrls = _extractStringList(rawData['photoUrls']);

    String? extractImage(List<String> keys) {
      for (final key in keys) {
        final value = rawData[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }

      final images = rawData['images'];
      if (images is Map<String, dynamic>) {
        for (final key in keys) {
          final value = images[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
      }

      final photos = rawData['photos'];
      if (photos is Map<String, dynamic>) {
        for (final key in keys) {
          final value = photos[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
      }

      return null;
    }

    String? firstString(List<String> keys) {
      for (final key in keys) {
        final value = rawData[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      return null;
    }

    final normalisedMileage = _parseMileage(
      rawData['mileage'] ??
          rawData['odometer'] ??
          rawData['mileageKm'] ??
          rawData['mileage_km'],
    );

    final plateNumber = firstString([
      'plateNumber',
      'plate',
      'plate_number',
      'numberPlate',
      'number_plate',
      'licencePlate',
      'licence_plate',
      'licensePlate',
      'license_plate',
    ]);

    final vin = firstString(['vin', 'VIN']);
    final colour = firstString(['color', 'colour']);
    final transmission = firstString(['transmission', 'gearbox', 'gear_box']);
    final engineSize = firstString([
      'engineType',
      'engine_type',
      'engineSize',
      'engine_size',
      'engineCapacity',
      'engine_capacity',
    ]);

    return {
      ...rawData,
      'id': docId,
      'userId': userId,
      'createdAt': rawData['createdAt'] ?? Timestamp.now(),
      'updatedAt': rawData['updatedAt'],
      'plateNumber': plateNumber ?? rawData['plateNumber'],
      'vin': vin ?? rawData['vin'],
      'color': colour ?? rawData['color'],
      'engineType': engineSize ?? rawData['engineType'],
      'transmission': transmission ?? rawData['transmission'],
      'mileage': normalisedMileage,
      'frontImageUrl':
          extractImage([
            'frontImageUrl',
            'front_image_url',
            'frontImage',
            'front_image',
            'frontPhotoUrl',
            'front_photo_url',
            'frontPhoto',
            'front_photo',
            'frontUrl',
            'front_url',
          ]) ??
          (photoUrls.isNotEmpty ? photoUrls.first : null),
      'sideImageUrl':
          extractImage([
            'sideImageUrl',
            'side_image_url',
            'sideImage',
            'side_image',
            'sidePhotoUrl',
            'side_photo_url',
            'sidePhoto',
            'side_photo',
            'sideUrl',
            'side_url',
          ]) ??
          (photoUrls.length > 1 ? photoUrls[1] : null),
    };
  }

  int? _parseMileage(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is! String) return null;

    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  List<String> _extractStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
