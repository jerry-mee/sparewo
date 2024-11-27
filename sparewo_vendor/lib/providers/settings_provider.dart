// lib/providers/settings_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings.dart';
import '../services/settings_service.dart';
import 'service_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class SettingsNotifier extends StateNotifier<Settings> {
  final SettingsService _settingsService;

  SettingsNotifier(this._settingsService) : super(const Settings()) {
    _init();
  }

  Future<void> _init() async {
    final settings = await _settingsService.getSettings();
    state = settings;
  }

  Future<void> updateTheme(bool isDarkMode) async {
    await _settingsService.updateTheme(isDarkMode);
    state = state.copyWith(isDarkMode: isDarkMode);
  }

  Future<void> updateLanguage(String language) async {
    await _settingsService.updateLanguage(language);
    state = state.copyWith(language: language);
  }

  Future<void> updateNotifications(bool enabled) async {
    await _settingsService.updateNotifications(enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> updateSound(bool enabled) async {
    await _settingsService.updateSound(enabled);
    state = state.copyWith(soundEnabled: enabled);
  }

  Future<void> updateVibration(bool enabled) async {
    await _settingsService.updateVibration(enabled);
    state = state.copyWith(vibrationEnabled: enabled);
  }

  Future<void> updateOrderNotifications(bool enabled) async {
    await _settingsService.updateOrderNotifications(enabled);
    state = state.copyWith(orderNotifications: enabled);
  }

  Future<void> updateStockAlerts(bool enabled) async {
    await _settingsService.updateStockAlerts(enabled);
    state = state.copyWith(stockAlerts: enabled);
  }

  Future<void> updatePromotionAlerts(bool enabled) async {
    await _settingsService.updatePromotionAlerts(enabled);
    state = state.copyWith(promotionAlerts: enabled);
  }

  Future<void> updateMaxOrderNotifications(int max) async {
    await _settingsService.updateMaxOrderNotifications(max);
    state = state.copyWith(maxOrderNotifications: max);
  }

  Future<void> updateCurrency(String currency) async {
    await _settingsService.updateCurrency(currency);
    state = state.copyWith(currency: currency);
  }

  Future<void> updateDateFormat(String format) async {
    await _settingsService.updateDateFormat(format);
    state = state.copyWith(dateFormat: format);
  }

  Future<void> updateSettings(Settings settings) async {
    await _settingsService.updateSettings(settings);
    state = settings;
  }
}

// Updated Provider Definition Section

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return SettingsNotifier(settingsService);
});

// Derived Providers

final themeProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).isDarkMode;
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).notificationsEnabled;
});

final soundEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).soundEnabled;
});

final vibrationEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).vibrationEnabled;
});

final languageProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).language;
});

final currencyProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).currency;
});

final dateFormatProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).dateFormat;
});

final orderNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).orderNotifications;
});

final stockAlertsProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).stockAlerts;
});

final promotionAlertsProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).promotionAlerts;
});

final maxOrderNotificationsProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).maxOrderNotifications;
});
