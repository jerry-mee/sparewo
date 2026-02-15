// lib/config/env_config.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for managing environment variables
class EnvConfig {
  static final EnvConfig _instance = EnvConfig._internal();

  factory EnvConfig() {
    return _instance;
  }

  EnvConfig._internal();

  /// Initialize environment variables
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
  }

  /// Get Gmail app password
  static String get gmailAppPassword {
    return dotenv.env['GMAIL_APP_PASSWORD'] ?? '';
  }

  // Add other environment variables here as needed
}
