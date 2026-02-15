// lib/core/logging/app_logger.dart

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  static final List<String> _recentLogs = [];
  static const int _maxRecentLogs = 200;
  static File? _logFile;
  static bool _initialized = false;
  static final DateFormat _timeFormat = DateFormat('HH:mm:ss.SSS');

  static Future<void> init() async {
    if (_initialized) return;

    // Force print to terminal immediately
    print('🚀 [AppLogger] Initializing logger...');

    if (!kIsWeb) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final logDir = Directory('${directory.path}/logs');
        if (!await logDir.exists()) {
          await logDir.create(recursive: true);
        }

        final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        _logFile = File('${logDir.path}/app_log_$dateStr.log');

        final header = '\n\n===== SESSION START: ${DateTime.now()} =====\n';
        await _appendToFile(header);

        _initialized = true;
        print('📂 [AppLogger] File logging active at: ${_logFile?.path}');
      } catch (e) {
        print('❌ [AppLogger] Failed to init file logging: $e');
      }
    }
  }

  static void debug(
    String context,
    String message, {
    Map<String, dynamic>? extra,
  }) {
    _log('DEBUG', context, message, extra: extra);
  }

  static void info(
    String context,
    String message, {
    Map<String, dynamic>? extra,
  }) {
    _log('INFO', context, message, extra: extra);
  }

  static void warn(
    String context,
    String message, {
    Map<String, dynamic>? extra,
  }) {
    _log('WARN', context, message, extra: extra);
  }

  static void error(
    String context,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    final data = {
      if (extra != null) ...extra,
      if (error != null) 'error': error.toString(),
    };
    _log('ERROR', context, message, extra: data, stackTrace: stackTrace);
  }

  static void ui(String context, String action, {String? details}) {
    _log(
      'UI',
      context,
      action,
      extra: details != null ? {'details': details} : null,
    );
  }

  static void network(
    String method,
    String url, {
    int? statusCode,
    dynamic data,
  }) {
    _log(
      'NETWORK',
      method,
      url,
      extra: {
        'status': statusCode,
        if (data != null)
          'data': data is Map || data is List
              ? jsonEncode(data)
              : data.toString(),
      },
    );
  }

  static void auth(String action, String userEmail, {bool success = true}) {
    final level = success ? 'INFO' : 'WARN';
    _log(level, 'AUTH', '$action - $userEmail', extra: {'success': success});
  }

  static void _log(
    String level,
    String context,
    String message, {
    Map<String, dynamic>? extra,
    StackTrace? stackTrace,
  }) {
    final now = DateTime.now();
    final timeStr = _timeFormat.format(now);
    final extraStr = extra != null ? ' | data: $extra' : '';
    final stackStr = stackTrace != null ? '\nSTACK:\n$stackTrace' : '';

    // Simplified format for terminal readability
    final logLine = '[$timeStr] [$level] [$context] $message$extraStr$stackStr';

    // ALWAYS print to standard output for visibility in release mode terminal
    print(logLine);

    // Buffer in memory
    if (_recentLogs.length >= _maxRecentLogs) {
      _recentLogs.removeAt(0);
    }
    _recentLogs.add(logLine);

    // Write to file
    if (_logFile != null) {
      _appendToFile('$logLine\n');
    }

    // Send to DevTools (Timeline)
    developer.log(
      message,
      name: context,
      level: _getLevel(level),
      error: stackTrace,
      time: now,
    );
  }

  static Future<void> _appendToFile(String line) async {
    try {
      if (_logFile != null) {
        await _logFile!.writeAsString(line, mode: FileMode.append);
      }
    } catch (e) {
      print('Failed to write log: $e');
    }
  }

  static int _getLevel(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'UI':
        return 600;
      case 'NETWORK':
        return 700;
      case 'INFO':
        return 800;
      case 'WARN':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 0;
    }
  }

  static Future<String> exportLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      return _logFile!.path;
    }
    return "Log file unavailable";
  }
}
