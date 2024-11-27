import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../exceptions/api_exceptions.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _vendorKey = 'vendor_data';
  static const String _configKey = 'app_config';
  static const String _cacheKey = 'data_cache';

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // Authentication Storage
  Future<void> setToken(String token) async {
    await _ensureInitialized();
    await _prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    await _ensureInitialized();
    return _prefs.getString(_tokenKey);
  }

  Future<void> deleteToken() async {
    await _ensureInitialized();
    await _prefs.remove(_tokenKey);
  }

  // Vendor Data Storage
  Future<void> setVendorData(Map<String, dynamic> data) async {
    await _ensureInitialized();
    await _prefs.setString(_vendorKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getVendorData() async {
    await _ensureInitialized();
    final data = _prefs.getString(_vendorKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  // Configuration Storage
  Future<void> setConfig(Map<String, dynamic> config) async {
    await _ensureInitialized();
    await _prefs.setString(_configKey, jsonEncode(config));
  }

  Future<Map<String, dynamic>> getConfig() async {
    await _ensureInitialized();
    final data = _prefs.getString(_configKey);
    if (data == null) return {};
    return jsonDecode(data) as Map<String, dynamic>;
  }

  // Cache Management
  Future<void> setCacheData(String key, dynamic data) async {
    await _ensureInitialized();
    final cache = await _getCache();
    cache[key] = {
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _prefs.setString(_cacheKey, jsonEncode(cache));
  }

  Future<dynamic> getCacheData(String key, {Duration? maxAge}) async {
    await _ensureInitialized();
    final cache = await _getCache();
    final cacheEntry = cache[key];

    if (cacheEntry == null) return null;

    if (maxAge != null) {
      final timestamp = DateTime.parse(cacheEntry['timestamp'] as String);
      final age = DateTime.now().difference(timestamp);
      if (age > maxAge) return null;
    }

    return cacheEntry['data'];
  }

  Future<void> clearCache() async {
    await _ensureInitialized();
    await _prefs.remove(_cacheKey);
  }

  Future<void> removeCacheEntry(String key) async {
    await _ensureInitialized();
    final cache = await _getCache();
    cache.remove(key);
    await _prefs.setString(_cacheKey, jsonEncode(cache));
  }

  // Clear All Data
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _prefs.clear();
  }

  // Error Handling
  Future<T> handleStorageOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      throw ApiException(
        message: 'Storage operation failed: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Private Helpers
  Future<void> _ensureInitialized() async {
    if (!_initialized) await init();
  }

  Future<Map<String, dynamic>> _getCache() async {
    final cacheData = _prefs.getString(_cacheKey);
    if (cacheData == null) return {};
    return jsonDecode(cacheData) as Map<String, dynamic>;
  }
}
