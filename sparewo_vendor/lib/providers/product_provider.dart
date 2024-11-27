import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_vendor/providers/app_providers.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../constants/enums.dart';

class ProductState {
  final List<Product> products;
  final LoadingStatus status;
  final String? error;
  final bool isLoading;

  const ProductState({
    this.products = const [],
    this.status = LoadingStatus.initial,
    this.error,
    this.isLoading = false,
  });

  ProductState copyWith({
    List<Product>? products,
    LoadingStatus? status,
    String? error,
    bool? isLoading,
  }) {
    return ProductState(
      products: products ?? this.products,
      status: status ?? this.status,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  AsyncValue<List<Product>> toAsyncValue() {
    if (isLoading) return const AsyncValue.loading();
    if (error != null) return AsyncValue.error(error!, StackTrace.current);
    return AsyncValue.data(products);
  }
}

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductService _productService;
  final String? _vendorId;

  ProductsNotifier(this._productService, this._vendorId)
      : super(const AsyncValue.loading()) {
    if (_vendorId != null) {
      loadProducts();
    }
  }

  Future<void> loadProducts() async {
    if (state.isLoading || _vendorId == null) return;

    state = const AsyncValue.loading();

    try {
      final products = await _productService.getVendorProducts(_vendorId!);
      state = AsyncValue.data(products);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addProduct(Product product) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();

    try {
      await _productService.createProduct(product);
      await loadProducts();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateProduct(Product product) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();

    try {
      await _productService.updateProduct(product);
      await loadProducts();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteProduct(String productId) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();

    try {
      await _productService.deleteProduct(productId);
      await loadProducts();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  List<Product> getFilteredProducts(String? filter) {
    if (filter == null || filter.isEmpty) return state.value ?? [];

    return state.value?.where((product) {
          final searchTerm = filter.toLowerCase();
          return product.title.toLowerCase().contains(searchTerm) ||
              product.description.toLowerCase().contains(searchTerm);
        }).toList() ??
        [];
  }

  List<Product> getProductsByStatus(ProductStatus status) {
    return state.value?.where((product) {
          switch (status) {
            case ProductStatus.pending:
              return product.status == ProductStatus.pending;
            case ProductStatus.approved:
              return product.status == ProductStatus.approved &&
                  !product.isOutOfStock;
            case ProductStatus.rejected:
              return product.status == ProductStatus.rejected;
            case ProductStatus.suspended:
              return product.status == ProductStatus.suspended;
          }
        }).toList() ??
        [];
  }

  List<Product> getOutOfStockProducts() {
    return state.value?.where((product) => product.isOutOfStock).toList() ?? [];
  }
}

final productsProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  final productService = ref.watch(productServiceProvider);
  final vendorId = ref.watch(currentVendorIdProvider);
  return ProductsNotifier(productService, vendorId);
});

final productsAsyncProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref.watch(productsProvider);
});

final filteredProductsProvider =
    Provider.family<List<Product>, String?>((ref, filter) {
  final productsNotifier = ref.watch(productsProvider.notifier);
  return productsNotifier.getFilteredProducts(filter);
});

final productsByStatusProvider =
    Provider.family<List<Product>, ProductStatus>((ref, status) {
  final productsNotifier = ref.watch(productsProvider.notifier);
  return productsNotifier.getProductsByStatus(status);
});

final outOfStockProductsProvider = Provider<List<Product>>((ref) {
  final productsNotifier = ref.watch(productsProvider.notifier);
  return productsNotifier.getOutOfStockProducts();
});

final productLoadingProvider = Provider<bool>((ref) {
  return ref.watch(productsProvider).isLoading;
});

final productErrorProvider = Provider<String?>((ref) {
  return ref.watch(productsProvider).error?.toString();
});

final productStatusProvider = Provider<LoadingStatus>((ref) {
  final state = ref.watch(productsProvider);
  if (state.isLoading) return LoadingStatus.loading;
  if (state.hasError) return LoadingStatus.error;
  return LoadingStatus.success;
});
