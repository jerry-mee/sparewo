import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemUIService {
  static final SystemUIService _instance = SystemUIService._internal();
  factory SystemUIService() => _instance;
  SystemUIService._internal();

  static const Color _defaultBackgroundColor = Color(0xFF1A1B4B);

  Future<void> configureSystemUI() async {
    try {
      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Configure system overlays
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          // Status bar configuration
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.light,

          // Navigation bar configuration
          systemNavigationBarColor: _defaultBackgroundColor,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,

          // System overlay configuration
          systemStatusBarContrastEnforced: false,
          systemNavigationBarContrastEnforced: false,
        ),
      );

      // Ensure full screen
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [
          SystemUiOverlay.top,
          SystemUiOverlay.bottom,
        ],
      );
    } catch (e) {
      debugPrint('Failed to configure system UI: $e');
      // Fallback configuration
      _applyFallbackConfiguration();
    }
  }

  void _applyFallbackConfiguration() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _defaultBackgroundColor,
      ),
    );
  }

  void setLightTheme() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
      ),
    );
  }

  void setDarkTheme() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _defaultBackgroundColor,
      ),
    );
  }

  void setSplashScreenTheme() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _defaultBackgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }
}
