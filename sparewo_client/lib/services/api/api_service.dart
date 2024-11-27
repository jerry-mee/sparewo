import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'api_exception.dart';
import '../../models/user_model.dart';

class ApiService {
  static const String _baseUrl = 'https://sparewo.matchstick.ug/api/client';
  static const Duration _timeout = Duration(seconds: 30);

  final Map<String, String> _headers;

  ApiService([String? authToken])
      : _headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        };

  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _headers.remove('Authorization');
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    debugPrint('📥 Response Status: ${response.statusCode}');
    debugPrint('📦 Response Body Length: ${response.body.length}');
    debugPrint('🔍 Response Body: ${response.body}');

    final decodedBody = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    } else {
      final errorMessage = decodedBody is Map<String, dynamic>
          ? decodedBody['message'] as String? ?? 'An unexpected error occurred'
          : 'An unexpected error occurred';
      throw ApiException(errorMessage, response.statusCode);
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('🔍 Logging in user: $email');
      final response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: _headers,
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(_timeout);

      return await _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Login Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      debugPrint('🔍 Fetching user profile');
      final response = await http
          .get(
            Uri.parse('$_baseUrl/users/profile'),
            headers: _headers,
          )
          .timeout(_timeout);

      return await _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Get User Profile Error: $e');
      rethrow;
    }
  }

  Future<void> createOrUpdateUser(User user) async {
    try {
      debugPrint('🔍 Creating or updating user: ${user.toJson()}');
      final response = await http
          .post(
            Uri.parse('$_baseUrl/users'),
            headers: _headers,
            body: json.encode(user.toJson()),
          )
          .timeout(_timeout);

      await _handleResponse(response);
    } catch (e) {
      debugPrint('❌ Create or Update User Error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getProducts({
    int? categoryId,
    String? search,
    String? carModel,
    String? year,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (categoryId != null) 'category': categoryId.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (carModel != null) 'model': carModel,
        if (year != null) 'yom': year,
      };

      debugPrint('🔍 Fetching products with params: $queryParams');

      final response = await http
          .get(
            Uri.parse('$_baseUrl/products')
                .replace(queryParameters: queryParams),
            headers: _headers,
          )
          .timeout(_timeout);

      final data = await _handleResponse(response);
      final products =
          List<Map<String, dynamic>>.from(data['data'] as List? ?? []);

      if (products.isEmpty && search != null && search.isNotEmpty) {
        throw ApiException('No products found matching your search.');
      }

      return products;
    } catch (e) {
      debugPrint('❌ Get Products Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> orderData) async {
    try {
      debugPrint('🔍 Creating order: ${json.encode(orderData)}');

      final requiredFields = ['address', 'phone', 'email', 'payment_method'];
      for (final field in requiredFields) {
        if (!orderData.containsKey(field)) {
          throw ApiException('Missing required order information: $field');
        }
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/orders'),
            headers: _headers,
            body: json.encode(orderData),
          )
          .timeout(_timeout);

      return await _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Create Order Error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      debugPrint('🔍 Fetching orders');
      final response = await http
          .get(
            Uri.parse('$_baseUrl/orders'),
            headers: _headers,
          )
          .timeout(_timeout);

      final data = await _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['data'] as List? ?? []);
    } catch (e) {
      debugPrint('❌ Get Orders Error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCarBrands() async {
    try {
      debugPrint('🔍 Fetching car brands');
      final response = await http
          .get(
            Uri.parse('$_baseUrl/car-brand'),
            headers: _headers,
          )
          .timeout(_timeout);

      final data = await _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['data'] as List? ?? []);
    } catch (e) {
      debugPrint('❌ Get Car Brands Error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCarModels(String brandId) async {
    try {
      debugPrint('🔍 Fetching car models for brand: $brandId');
      final response = await http
          .get(
            Uri.parse('$_baseUrl/car-models?car_makeid=$brandId'),
            headers: _headers,
          )
          .timeout(_timeout);

      final data = await _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['data'] as List? ?? []);
    } catch (e) {
      debugPrint('❌ Get Car Models Error: $e');
      rethrow;
    }
  }
}
