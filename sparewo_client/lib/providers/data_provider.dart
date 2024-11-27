import 'package:flutter/material.dart';
import '../services/api/api_service.dart';
import '../services/api/api_exception.dart';
import '../utils/cart_helper.dart';
import 'dart:async';

class DataProvider extends ChangeNotifier {
  final ApiService _apiService;

  DataProvider({required ApiService apiService}) : _apiService = apiService;

  final List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _cartItems = [];
  final List<Map<String, dynamic>> _carBrands = [];
  final List<Map<String, dynamic>> _carModels = [];
  final List<Map<String, dynamic>> _pastOrders = [];
  bool _isLoading = false;
  String? _error;
  Timer? _loadingTimer;

  // Getters
  List<Map<String, dynamic>> get products => List.unmodifiable(_products);
  List<Map<String, dynamic>> get cartItems => List.unmodifiable(_cartItems);
  List<Map<String, dynamic>> get carBrands => List.unmodifiable(_carBrands);
  List<Map<String, dynamic>> get carModels => List.unmodifiable(_carModels);
  List<Map<String, dynamic>> get pastOrders => List.unmodifiable(_pastOrders);
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalPrice {
    return _cartItems.fold(0.0, (total, item) {
      final price = CartHelper.parsePrice(item['price']);
      final quantity = CartHelper.parseQuantity(item['quantity']);
      return total + (price * quantity);
    });
  }

  // State Management Methods
  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void clearError() => _setError(null);

  void _startLoadingTimer() {
    _cancelLoadingTimer();
    _loadingTimer = Timer(const Duration(seconds: 15), () {
      if (_isLoading) {
        _setLoading(false);
        _setError('Operation timed out. Please try again.');
      }
    });
  }

  void _cancelLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  // Product Methods
  Future<void> loadProducts({
    int? categoryId,
    String? search,
    String? carModel,
    String? year,
    int page = 1,
    int limit = 20,
  }) async {
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);
    _startLoadingTimer();

    try {
      final products = await _apiService.getProducts(
        categoryId: categoryId,
        search: search,
        carModel: carModel,
        year: year,
        page: page,
        limit: limit,
      );
      _products
        ..clear()
        ..addAll(products);
    } catch (e) {
      _setError('Failed to load products.');
    } finally {
      _cancelLoadingTimer();
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> getProductById(String productId) async {
    try {
      final products = await _apiService.getProducts(search: productId);
      if (products.isEmpty) {
        throw ApiException('Product not found');
      }
      return products.first;
    } catch (e) {
      throw ApiException('Failed to fetch product details: ${e.toString()}');
    }
  }

  // Cart Methods
  Future<void> addToCart(Map<String, dynamic> product, int quantity) async {
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);

    try {
      if (quantity <= 0) {
        throw ApiException('Quantity must be greater than 0');
      }

      final productId = product['id']?.toString();
      if (productId == null) {
        throw ApiException('Invalid product');
      }

      final price = CartHelper.parsePrice(product['selling_price']);
      final existingItemIndex = _cartItems.indexWhere(
        (item) => item['product_id'].toString() == productId,
      );

      if (existingItemIndex != -1) {
        final currentQuantity =
            CartHelper.parseQuantity(_cartItems[existingItemIndex]['quantity']);
        _cartItems[existingItemIndex] = {
          ..._cartItems[existingItemIndex],
          'quantity': currentQuantity + quantity,
        };
      } else {
        _cartItems.add({
          'id': DateTime.now().millisecondsSinceEpoch,
          'product_id': productId,
          'title': product['title'] ?? 'Unknown Product',
          'price': price,
          'product_img': product['product_img'],
          'quantity': quantity,
        });
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to add to cart: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCartItemQuantity(
      dynamic cartItemId, int newQuantity) async {
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);

    try {
      if (newQuantity <= 0) {
        throw ApiException('Quantity must be greater than 0');
      }

      final itemIndex =
          _cartItems.indexWhere((item) => item['id'] == cartItemId);
      if (itemIndex == -1) {
        throw ApiException('Cart item not found');
      }

      _cartItems[itemIndex] = {
        ..._cartItems[itemIndex],
        'quantity': newQuantity,
      };

      notifyListeners();
    } catch (e) {
      _setError('Failed to update quantity: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeFromCart(dynamic cartItemId) async {
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);

    try {
      _cartItems.removeWhere((item) => item['id'] == cartItemId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove item from cart: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCart() async {
    notifyListeners();
  }

  // Order Methods
  Future<void> loadPastOrders() async {
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);
    _startLoadingTimer();

    try {
      final orders = await _apiService.getOrders();
      _pastOrders
        ..clear()
        ..addAll(orders);
    } catch (e) {
      _setError('Failed to load past orders.');
    } finally {
      _cancelLoadingTimer();
      _setLoading(false);
    }
  }

  Future<void> placeOrder({
    required String address,
    required String phone,
    required String email,
    required String paymentMethod,
  }) async {
    if (_isLoading) return;

    if (_cartItems.isEmpty) {
      throw ApiException('Cart is empty');
    }

    _setLoading(true);
    _setError(null);
    _startLoadingTimer();

    try {
      final orderItems = _cartItems
          .map((item) => {
                'product_id': item['product_id'],
                'quantity': CartHelper.parseQuantity(item['quantity']),
                'price': CartHelper.parsePrice(item['price']),
              })
          .toList();

      await _apiService.createOrder({
        'address': address.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'payment_method': paymentMethod,
        'items': orderItems,
      });

      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      _setError('Failed to place order.');
      rethrow;
    } finally {
      _cancelLoadingTimer();
      _setLoading(false);
    }
  }

  // Car Related Methods
  Future<void> loadCarBrands() async {
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);
    _startLoadingTimer();

    try {
      final brands = await _apiService.getCarBrands();
      _carBrands
        ..clear()
        ..addAll(brands);
    } catch (e) {
      _setError('Failed to load car brands.');
    } finally {
      _cancelLoadingTimer();
      _setLoading(false);
    }
  }

  Future<void> loadCarModels(String brandId) async {
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);
    _startLoadingTimer();

    try {
      final models = await _apiService.getCarModels(brandId);
      _carModels
        ..clear()
        ..addAll(models);
    } catch (e) {
      _setError('Failed to load car models.');
    } finally {
      _cancelLoadingTimer();
      _setLoading(false);
    }
  }

  // Helper Methods
  int _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      final parsedValue = int.tryParse(value);
      if (parsedValue != null) return parsedValue;
    }
    throw ApiException('Invalid ID format: $value');
  }

  // Cleanup Methods
  void reset() {
    _products.clear();
    _cartItems.clear();
    _carBrands.clear();
    _carModels.clear();
    _pastOrders.clear();
    _isLoading = false;
    _error = null;
    _cancelLoadingTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelLoadingTimer();
    super.dispose();
  }
}
