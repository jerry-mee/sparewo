import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../exceptions/api_exceptions.dart';
import '../constants/api_constants.dart';
import '../services/storage_service.dart';

class ApiService {
  final StorageService storageService;
  final http.Client _client;
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  ApiService({
    required this.storageService,
    http.Client? client,
  }) : _client = client ?? http.Client();

  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _headers.remove('Authorization');
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final statusCode = response.statusCode;
    final body = utf8.decode(response.bodyBytes);

    try {
      final decodedBody = json.decode(body) as Map<String, dynamic>;

      if (statusCode >= 200 && statusCode < 300) {
        return decodedBody;
      }

      throw ApiException(
        message: decodedBody['message'] ?? 'An error occurred',
        statusCode: statusCode,
        errors: decodedBody['errors'] as Map<String, dynamic>?,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to process response: ${e.toString()}',
        statusCode: statusCode,
      );
    }
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Duration timeout = ApiConstants.defaultTimeout,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.baseUrl + endpoint)
          .replace(queryParameters: queryParams);

      final response =
          await _client.get(uri, headers: _headers).timeout(timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(
    String endpoint, {
    required Map<String, dynamic> data,
    Duration timeout = ApiConstants.defaultTimeout,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.baseUrl + endpoint);

      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: json.encode(data),
          )
          .timeout(timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> put(
    String endpoint, {
    required Map<String, dynamic> data,
    Duration timeout = ApiConstants.defaultTimeout,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.baseUrl + endpoint);

      final response = await _client
          .put(
            uri,
            headers: _headers,
            body: json.encode(data),
          )
          .timeout(timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    Duration timeout = ApiConstants.defaultTimeout,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.baseUrl + endpoint);

      final response =
          await _client.delete(uri, headers: _headers).timeout(timeout);

      return await _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(dynamic error) {
    if (error is TimeoutException) {
      return const ApiException(
        message: 'Request timed out. Please try again.',
        statusCode: 408,
      );
    }

    if (error is ApiException) {
      return error;
    }

    return ApiException(
      message: error.toString(),
      statusCode: 500,
    );
  }

  void dispose() {
    _client.close();
  }
}
