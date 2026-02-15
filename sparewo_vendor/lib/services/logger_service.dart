import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// A singleton service for logging throughout the app
class LoggerService {
  static LoggerService? _instance;
  final Logger _logger;

  // List of fields to mask in logs
  static const List<String> _sensitiveFields = [
    'email',
    'token',
    'password',
    'phone',
    'phoneNumber',
    'address',
    'businessAddress',
    'fcmToken',
    'refreshToken',
    'idToken',
    'accessToken',
  ];

  // Private constructor
  LoggerService._()
      : _logger = Logger(
          printer: PrettyPrinter(
            methodCount: 2,
            errorMethodCount: 8,
            lineLength: 120,
            colors: true,
            printEmojis: true,
            printTime: true,
          ),
        );

  /// Returns the singleton instance of [LoggerService]
  static LoggerService get instance {
    _instance ??= LoggerService._();
    return _instance!;
  }

  /// Logs a debug message
  void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.d(_maskSensitiveData(message),
          error: error, stackTrace: stackTrace);
    }
  }

  /// Logs a verbose message
  void verbose(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.v(_maskSensitiveData(message),
          error: error, stackTrace: stackTrace);
    }
  }

  /// Logs a warning message
  void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.w(_maskSensitiveData(message),
          error: error, stackTrace: stackTrace);
    }
  }

  /// Logs an info message
  void info(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.i(_maskSensitiveData(message),
          error: error, stackTrace: stackTrace);
    }
  }

  /// Logs an error message
  void error(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.e(_maskSensitiveData(message),
          error: error, stackTrace: stackTrace);
    }
  }

  /// Logs a critical error message
  void critical(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.f(_maskSensitiveData(message),
          error: error, stackTrace: stackTrace);
    }
  }

  /// Masks sensitive information in logs
  dynamic _maskSensitiveData(dynamic data) {
    if (data == null) return null;

    // Handle strings
    if (data is String) {
      return data;
    }

    // Handle maps
    if (data is Map) {
      final maskedData = <String, dynamic>{};

      data.forEach((key, value) {
        // Check if this key should be masked
        if (_shouldMaskField(key.toString())) {
          if (value is String && value.isNotEmpty) {
            maskedData[key] = '***MASKED***';
          } else {
            maskedData[key] = value;
          }
        }
        // Recursively mask nested maps
        else if (value is Map || value is List) {
          maskedData[key] = _maskSensitiveData(value);
        }
        // For regular values, keep as is
        else {
          maskedData[key] = value;
        }
      });

      return maskedData;
    }

    // Handle lists
    if (data is List) {
      return data.map((item) => _maskSensitiveData(item)).toList();
    }

    // For other types, return as is
    return data;
  }

  /// Check if a field name should be masked based on sensitive field patterns
  bool _shouldMaskField(String fieldName) {
    fieldName = fieldName.toLowerCase();

    // Direct match with sensitive fields
    if (_sensitiveFields.contains(fieldName)) {
      return true;
    }

    // Check for sensitive field patterns in the field name
    for (final pattern in _sensitiveFields) {
      if (fieldName.contains(pattern.toLowerCase())) {
        return true;
      }
    }

    return false;
  }
}
