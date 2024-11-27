import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  Future<void> setToken(String token) async {
    if (!_initialized) await init();
    await _prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    if (!_initialized) await init();
    return _prefs.getString(_tokenKey);
  }

  Future<void> deleteToken() async {
    if (!_initialized) await init();
    await _prefs.remove(_tokenKey);
  }

  Future<void> setUserData(String userData) async {
    if (!_initialized) await init();
    await _prefs.setString(_userKey, userData);
  }

  Future<String?> getUserData() async {
    if (!_initialized) await init();
    return _prefs.getString(_userKey);
  }

  Future<void> deleteUserData() async {
    if (!_initialized) await init();
    await _prefs.remove(_userKey);
  }

  Future<void> clearAll() async {
    if (!_initialized) await init();
    await _prefs.clear();
  }
}
