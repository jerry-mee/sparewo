import 'package:shared_preferences/shared_preferences.dart';
import '../exceptions/api_exceptions.dart';
import '../models/settings.dart';

class SettingsService {
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _soundKey = 'sound_enabled';
  static const String _vibrationKey = 'vibration_enabled';
  static const String _currencyKey = 'currency';
  static const String _dateFormatKey = 'date_format';
  static const String _orderNotificationsKey = 'order_notifications';
  static const String _stockAlertsKey = 'stock_alerts';
  static const String _promotionAlertsKey = 'promotion_alerts';
  static const String _maxOrderNotificationsKey = 'max_order_notifications';

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  Future<Settings> getSettings() async {
    try {
      await _ensureInitialized();
      return Settings(
        isDarkMode: _prefs.getBool(_themeKey) ?? false,
        language: _prefs.getString(_languageKey) ?? 'English',
        notificationsEnabled: _prefs.getBool(_notificationsKey) ?? true,
        soundEnabled: _prefs.getBool(_soundKey) ?? true,
        vibrationEnabled: _prefs.getBool(_vibrationKey) ?? true,
        orderNotifications: _prefs.getBool(_orderNotificationsKey) ?? true,
        stockAlerts: _prefs.getBool(_stockAlertsKey) ?? true,
        promotionAlerts: _prefs.getBool(_promotionAlertsKey) ?? true,
        maxOrderNotifications: _prefs.getInt(_maxOrderNotificationsKey) ?? 100,
        dateFormat: _prefs.getString(_dateFormatKey) ?? 'dd/MM/yyyy',
        currency: _prefs.getString(_currencyKey) ?? 'UGX',
      );
    } catch (e) {
      throw ApiException(
        message: 'Failed to load settings: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<void> updateTheme(bool isDarkMode) async {
    await _ensureInitialized();
    await _prefs.setBool(_themeKey, isDarkMode);
  }

  Future<void> updateLanguage(String language) async {
    await _ensureInitialized();
    await _prefs.setString(_languageKey, language);
  }

  Future<void> updateNotifications(bool enabled) async {
    await _ensureInitialized();
    await _prefs.setBool(_notificationsKey, enabled);
  }

  Future<void> updateSound(bool enabled) async {
    await _ensureInitialized();
    await _prefs.setBool(_soundKey, enabled);
  }

  Future<void> updateVibration(bool enabled) async {
    await _ensureInitialized();
    await _prefs.setBool(_vibrationKey, enabled);
  }

  Future<void> updateOrderNotifications(bool enabled) async {
    await _ensureInitialized();
    await _prefs.setBool(_orderNotificationsKey, enabled);
  }

  Future<void> updateStockAlerts(bool enabled) async {
    await _ensureInitialized();
    await _prefs.setBool(_stockAlertsKey, enabled);
  }

  Future<void> updatePromotionAlerts(bool enabled) async {
    await _ensureInitialized();
    await _prefs.setBool(_promotionAlertsKey, enabled);
  }

  Future<void> updateMaxOrderNotifications(int max) async {
    await _ensureInitialized();
    await _prefs.setInt(_maxOrderNotificationsKey, max);
  }

  Future<void> updateCurrency(String currency) async {
    await _ensureInitialized();
    await _prefs.setString(_currencyKey, currency);
  }

  Future<void> updateDateFormat(String format) async {
    await _ensureInitialized();
    await _prefs.setString(_dateFormatKey, format);
  }

  Future<void> clearSettings() async {
    await _ensureInitialized();
    final keysToRemove = [
      _themeKey,
      _languageKey,
      _notificationsKey,
      _soundKey,
      _vibrationKey,
      _currencyKey,
      _dateFormatKey,
      _orderNotificationsKey,
      _stockAlertsKey,
      _promotionAlertsKey,
      _maxOrderNotificationsKey,
    ];

    for (final key in keysToRemove) {
      await _prefs.remove(key);
    }
  }

  Future<void> updateSettings(Settings settings) async {
    await _ensureInitialized();
    await Future.wait([
      updateTheme(settings.isDarkMode),
      updateLanguage(settings.language),
      updateNotifications(settings.notificationsEnabled),
      updateSound(settings.soundEnabled),
      updateVibration(settings.vibrationEnabled),
      updateOrderNotifications(settings.orderNotifications),
      updateStockAlerts(settings.stockAlerts),
      updatePromotionAlerts(settings.promotionAlerts),
      updateMaxOrderNotifications(settings.maxOrderNotifications),
      updateCurrency(settings.currency),
      updateDateFormat(settings.dateFormat),
    ]);
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await init();
  }
}
