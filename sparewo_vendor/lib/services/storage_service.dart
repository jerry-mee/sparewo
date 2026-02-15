// lib/services/storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_result.dart';
import '../models/user_roles.dart';

/// A service to manage all persistent app data using SharedPreferences.
/// This is the single source of truth for cached data, including authentication state.
class StorageService {
  late final SharedPreferences _prefs;

  // --- Private Keys (Migrated from AuthStateManager for data continuity) ---
  // Using the exact same keys from the old AuthStateManager is CRITICAL.
  // This ensures existing users are not logged out when they update the app.
  static const String _authTokenKey = 'auth_token';
  static const String _vendorIdKey = 'vendor_id';
  static const String _userRoleKey = 'user_role';
  static const String _emailKey = 'user_email';
  static const String _isAuthenticatedKey = 'is_authenticated';

  // Generic key for other non-auth cache data
  static const String _cacheKey = 'data_cache';

  /// Initializes the service by getting the SharedPreferences instance.
  /// This must be called once during app startup before any other methods are used.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- AUTHENTICATION-SPECIFIC METHODS ---

  /// Saves the entire authentication result to persistent storage.
  /// This is the primary method to call after a successful login or signup.
  Future<void> saveAuthResult(AuthResult authResult) async {
    await _prefs.setString(_authTokenKey, authResult.token);
    await _prefs.setBool(_isAuthenticatedKey, true);
    // FIX: Handle nullable vendor
    if (authResult.vendor != null) {
      await _prefs.setString(_vendorIdKey, authResult.vendor!.id);
      await _prefs.setString(_emailKey, authResult.vendor!.email);
    }
    if (authResult.userRole != null) {
      await _prefs.setString(
          _userRoleKey, jsonEncode(authResult.userRole!.toJson()));
    }
  }

  /// Retrieves the saved authentication token.
  /// Returns null if no token is found.
  String? getToken() {
    return _prefs.getString(_authTokenKey);
  }

  /// Clears all authentication-related data from storage upon sign-out.
  Future<void> clearAuthData() async {
    await _prefs.remove(_authTokenKey);
    await _prefs.remove(_isAuthenticatedKey);
    await _prefs.remove(_vendorIdKey);
    await _prefs.remove(_emailKey);
    await _prefs.remove(_userRoleKey);
  }

  // --- GENERIC CACHING METHODS ---

  Future<void> setCacheData(String key, dynamic data) async {
    final cache = _getCache();
    cache[key] = {
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _prefs.setString(_cacheKey, jsonEncode(cache));
  }

  Future<dynamic> getCacheData(String key, {Duration? maxAge}) async {
    final cache = _getCache();
    final cacheEntry = cache[key] as Map<String, dynamic>?;

    if (cacheEntry == null) return null;

    if (maxAge != null) {
      final timestamp = DateTime.parse(cacheEntry['timestamp'] as String);
      if (DateTime.now().difference(timestamp) > maxAge) {
        return null; // Cache is stale
      }
    }
    return cacheEntry['data'];
  }

  /// Wipes everything from SharedPreferences. Use with extreme caution.
  /// Prefer `clearAuthData` for sign-outs.
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  // --- PRIVATE HELPERS ---

  Map<String, dynamic> _getCache() {
    final cacheData = _prefs.getString(_cacheKey);
    if (cacheData == null) return {};
    return jsonDecode(cacheData) as Map<String, dynamic>;
  }
}
