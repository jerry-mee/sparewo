// lib/features/my_car/application/car_data_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_client/features/my_car/data/car_data_repository.dart';

// 1. Repository Provider
final carDataRepositoryProvider = Provider<CarDataRepository>((ref) {
  return CarDataRepository();
});

// 2. Car Brands Provider
final carBrandsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(carDataRepositoryProvider);
  return repository.getCarBrands();
});

// 3. Car Models Provider (Family)
final carModelsProvider = FutureProvider.family<List<String>, String>((
  ref,
  brand,
) async {
  final repository = ref.watch(carDataRepositoryProvider);
  return repository.getCarModels(brand);
});

// 4. Available Years Provider
final availableYearsProvider = Provider<List<int>>((ref) {
  final repository = ref.watch(carDataRepositoryProvider);
  return repository.getAvailableYears();
});

// 5. Search Brands Provider (Family)
final searchCarBrandsProvider = FutureProvider.family<List<String>, String>((
  ref,
  query,
) async {
  final repository = ref.watch(carDataRepositoryProvider);
  return repository.searchBrands(query);
});

// 6. Search Models Provider (Family)
// Note: We need a tuple or custom object to pass two arguments to a family,
// or we can just expose the repository and let the UI call the method if it's not a stream.
// For simplicity in Riverpod 2.x manual style without tuples, we often return the Future directly from the UI
// or use a provider that returns the search function.
// Here, we'll keep it simple: exposed via repository, but if you need a specific provider:
final searchCarModelsProvider =
    FutureProvider.family<List<String>, ({String brand, String query})>((
      ref,
      args,
    ) async {
      final repository = ref.watch(carDataRepositoryProvider);
      return repository.searchModels(args.brand, args.query);
    });
