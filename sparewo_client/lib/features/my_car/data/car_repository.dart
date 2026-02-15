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
  Stream<List<CarModel>> getUserCars() {
    if (userId == null) {
      AppLogger.warn('CarRepository', 'userId is null in getUserCars');
      return Stream.value([]);
    }

    AppLogger.debug(
      'CarRepository',
      'Subscribing to user cars',
      extra: {'userId': userId},
    );

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cars')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final cars = snapshot.docs.map((doc) {
            return CarModel.fromJson({
              'id': doc.id,
              'userId': userId,
              ...doc.data(),
            });
          }).toList();

          AppLogger.debug(
            'CarRepository',
            'Received snapshot',
            extra: {'userId': userId, 'count': cars.length},
          );

          return cars;
        })
        .handleError((error, stack) {
          AppLogger.error(
            'CarRepository',
            'Stream error in getUserCars',
            error: error,
            stackTrace: stack,
            extra: {'userId': userId},
          );
          throw error;
        });
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

      return CarModel.fromJson({
        'id': doc.id,
        'userId': userId,
        ...doc.data()!,
      });
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
        'engineType': engineType,
        'transmission': transmission,
        'mileage': mileage,
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
          .update({...data, 'updatedAt': FieldValue.serverTimestamp()});

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
}
