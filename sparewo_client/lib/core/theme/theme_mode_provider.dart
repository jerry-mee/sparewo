// lib/core/theme/theme_mode_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Default to system to respect device settings (Dark/Light/Low Power)
    return ThemeMode.system;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
  }

  void toggleDarkMode(bool isDark) {
    // Override system setting when user manually toggles
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}
