// lib/providers/product_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/api_service.dart';

final productProvider =
    StateNotifierProvider<ProductNotifier, List<Product>>((ref) {
  return ProductNotifier(ApiService());
});

class ProductNotifier extends StateNotifier<List<Product>> {
  final ApiService _apiService;

  ProductNotifier(this._apiService) : super([]);

  Future<void> fetchProducts() async {
    state = await _apiService.getProducts();
  }

  Future<void> addProduct(Product product) async {
    await _apiService.addProduct(product);
    state = [...state, product];
  }

  Future<void> updateProduct(Product updatedProduct) async {
    await _apiService.updateProduct(updatedProduct);
    state = [
      for (final product in state)
        if (product.id == updatedProduct.id) updatedProduct else product,
    ];
  }

  Future<void> deleteProduct(String productId) async {
    await _apiService.deleteProduct(productId);
    state = state.where((product) => product.id != productId).toList();
  }
}
