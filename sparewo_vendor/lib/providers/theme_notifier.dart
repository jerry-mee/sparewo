// lib/providers/theme_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
import 'providers.dart';

class ThemeNotifier extends StateNotifier<bool> {
  final SettingsService _settingsService;

  ThemeNotifier(this._settingsService) : super(false) {
    _init();
  }

  Future<void> _init() async {
    final settings = await _settingsService.getSettings();
    state = settings.isDarkMode;
  }

  Future<void> toggleTheme() async {
    state = !state;
    await _settingsService.updateTheme(state);
  }
}

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return ThemeNotifier(settingsService);
});

final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeNotifierProvider);
});
