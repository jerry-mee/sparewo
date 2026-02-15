// lib/features/catalog/application/product_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_client/features/catalog/data/catalog_repository.dart';
import 'package:sparewo_client/features/catalog/domain/product_model.dart';

// 1. Repository Provider
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository();
});

// 2. Catalog Products Stream (Family)
// Using a record for the family parameters (category, searchQuery)
final catalogProductsProvider =
    StreamProvider.family<
      List<ProductModel>,
      ({String? category, String? searchQuery})
    >((ref, args) {
      final repository = ref.watch(catalogRepositoryProvider);
      return repository.getCatalogProducts(
        category: args.category,
        searchQuery: args.searchQuery,
      );
    });

// 3. Product By ID Provider (Family)
final productByIdProvider = FutureProvider.family<ProductModel?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(catalogRepositoryProvider);
  return repository.getProductById(id);
});

// 4. Categories Provider
final productCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(catalogRepositoryProvider);
  return repository.getProductCategories();
});

// 5. Featured Products Provider
final featuredProductsProvider = StreamProvider.family<List<ProductModel>, int>((
  ref,
  limit,
) {
  // Default limit of 6 is handled by the UI passing 6, or we can default here if arg is null (not possible with family type safety usually)
  final repository = ref.watch(catalogRepositoryProvider);
  return repository.getFeaturedProducts(limit: limit);
});

// 6. Products By Brand Provider
final productsByBrandProvider =
    StreamProvider.family<List<ProductModel>, String>((ref, brand) {
      final repository = ref.watch(catalogRepositoryProvider);
      return repository.getProductsByBrand(brand);
    });

// 7. Recent Products Provider
final recentProductsProvider = StreamProvider.family<List<ProductModel>, int>((
  ref,
  limit,
) {
  final repository = ref.watch(catalogRepositoryProvider);
  return repository.getRecentProducts(limit: limit);
});

// 8. Search By Part Number
final searchByPartNumberProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, partNumber) async {
      final repository = ref.watch(catalogRepositoryProvider);
      return repository.searchByPartNumber(partNumber);
    });
