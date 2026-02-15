// lib/features/my_car/application/car_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/my_car/data/car_repository.dart';
import 'package:sparewo_client/features/my_car/domain/car_model.dart';

// 1. Repository Provider
final carRepositoryProvider = Provider<CarRepository>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final userId = userAsync.asData?.value?.id;
  return CarRepository(userId: userId);
});

// 2. Cars Stream Provider
final carsProvider = StreamProvider<List<CarModel>>((ref) {
  final repository = ref.watch(carRepositoryProvider);
  return repository.getUserCars();
});

// 3. Single Car Provider
final carByIdProvider = FutureProvider.family<CarModel?, String>((
  ref,
  carId,
) async {
  final repository = ref.watch(carRepositoryProvider);
  return repository.getCarById(carId);
});

// 4. Car Notifier
final carNotifierProvider = AsyncNotifierProvider<CarNotifier, void>(
  CarNotifier.new,
);

class CarNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() async {
    // No initial state needed for actions
  }

  Future<void> addCar(CarModel car) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(carRepositoryProvider);
      await repository.addCar(
        make: car.make,
        model: car.model,
        year: car.year,
        plateNumber: car.plateNumber,
        vin: car.vin,
        color: car.color,
        engineType: car.engineType,
        transmission: car.transmission,
        mileage: car.mileage,
        lastServiceDate: car.lastServiceDate,
        insuranceExpiryDate: car.insuranceExpiryDate,
      );
    });
  }

  Future<void> updateCar(CarModel car) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(carRepositoryProvider);

      // Convert model to map for update, excluding ID and userId which shouldn't change
      final data = {
        'make': car.make,
        'model': car.model,
        'year': car.year,
        'plateNumber': car.plateNumber,
        'vin': car.vin,
        'color': car.color,
        'engineType': car.engineType,
        'transmission': car.transmission,
        'mileage': car.mileage,
        'lastServiceDate': car.lastServiceDate,
        'insuranceExpiryDate': car.insuranceExpiryDate,
      };

      // Remove nulls to prevent overwriting with null if intention was to keep existing
      // data.removeWhere((key, value) => value == null);

      await repository.updateCar(car.id, data);
    });
  }

  Future<void> deleteCar(String carId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(carRepositoryProvider);
      await repository.deleteCar(carId);
    });
  }

  Future<void> setDefaultCar(String carId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(carRepositoryProvider);
      await repository.setDefaultCar(carId);
    });
  }
}
