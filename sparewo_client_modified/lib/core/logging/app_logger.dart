// lib/core/logging/app_logger.dart

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  static final List<String> _recentLogs = <String>[];
  static final Queue<String> _pendingFileLines = Queue<String>();
  static final DateFormat _timeFormat = DateFormat('HH:mm:ss.SSS');
  static const int _maxRecentLogs = 500;
  static const int _maxPendingLines = 1000;
  static const int _maxDataChars = 4000;
  static const Duration _duplicateWindow = Duration(seconds: 2);

  static File? _logFile;
  static IOSink? _sink;
  static bool _initialized = false;
  static bool _initializing = false;
  static int _sequence = 0;
  static final String _sessionId = DateTime.now().millisecondsSinceEpoch
      .toRadixString(36);
  static DateTime? _lastFlushAt;
  static String? _lastFingerprint;
  static DateTime? _lastFingerprintAt;
  static int _suppressedDuplicates = 0;
  static bool _crashlyticsForwardingEnabled = false;
  static bool _crashlyticsIncludeInfo = true;
  static bool _crashlyticsIncludeDebug = false;
  static bool _crashlyticsRecordNonFatalErrors = true;

  static Future<void> init() async {
    if (_initialized || _initializing) return;
    _initializing = true;

    final now = DateTime.now().toIso8601String();
    _writeConsole('[Logger] init start (session=$_sessionId at=$now)');

    try {
      if (!kIsWeb) {
        final directory = await getApplicationDocumentsDirectory();
        final logDir = Directory('${directory.path}/logs');
        if (!await logDir.exists()) {
          await logDir.create(recursive: true);
        }

        final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        _logFile = File('${logDir.path}/app_log_$dateStr.log');
        _sink = _logFile!.openWrite(mode: FileMode.append);
        _queueFileLine('\n\n===== SESSION START: ${DateTime.now()} =====\n');
        _queueFileLine(
          'session=$_sessionId appMode=${kReleaseMode
              ? 'release'
              : kDebugMode
              ? 'debug'
              : 'profile'}',
        );
      }

      _initialized = true;
      _initializing = false;
      await _flushPendingLines();

      _writeConsole(
        '[Logger] init complete (file=${_logFile?.path ?? 'disabled'})',
      );
    } catch (e, st) {
      _initialized = true;
      _initializing = false;
      _writeConsole('[Logger] init failed: $e');
      developer.log(
        'Logger init failed',
        name: 'LOGGER',
        level: 1000,
        error: e,
        stackTrace: st,
      );
    }
  }

  static Future<void> dispose() async {
    try {
      await _flushPendingLines(force: true);
      await _sink?.flush();
      await _sink?.close();
    } catch (_) {
      // Best effort.
    } finally {
      _sink = null;
    }
  }

  static Future<void> enableCrashlyticsForwarding({
    bool includeInfo = true,
    bool includeDebug = false,
    bool recordNonFatalErrors = true,
  }) async {
    if (kIsWeb || Firebase.apps.isEmpty) return;

    _crashlyticsForwardingEnabled = true;
    _crashlyticsIncludeInfo = includeInfo;
    _crashlyticsIncludeDebug = includeDebug;
    _crashlyticsRecordNonFatalErrors = recordNonFatalErrors;

    try {
      await FirebaseCrashlytics.instance.setCustomKey(
        'app_logger_session',
        _sessionId,
      );
      await FirebaseCrashlytics.instance.log(
        'AppLogger Crashlytics forwarding enabled (session=$_sessionId)',
      );
    } catch (e) {
      _writeConsole('Failed to enable Crashlytics forwarding: $e');
    }
  }

  static Future<void> setUserIdentifier(String? uid) async {
    if (!_crashlyticsForwardingEnabled || kIsWeb || Firebase.apps.isEmpty) {
      return;
    }
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(uid ?? '');
    } catch (_) {
      // Best effort.
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
    final payload = <String, dynamic>{
      if (extra != null) ...extra,
      if (error != null) 'error': error.toString(),
    };
    _log(
      'ERROR',
      context,
      message,
      extra: payload.isEmpty ? null : payload,
      error: error,
      stackTrace: stackTrace,
    );
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
      extra: <String, dynamic>{
        'status': statusCode,
        if (data != null) 'data': _serializeData(data),
      },
    );
  }

  static void auth(String action, String userEmail, {bool success = true}) {
    final level = success ? 'INFO' : 'WARN';
    _log(
      level,
      'AUTH',
      '$action - $userEmail',
      extra: <String, dynamic>{'success': success},
    );
  }

  static List<String> recentLogs() => List<String>.unmodifiable(_recentLogs);

  static void _log(
    String level,
    String context,
    String message, {
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final now = DateTime.now();
    final fingerprint = '$level|$context|$message|${extra?.toString() ?? ''}';
    if (_isDuplicateWithinWindow(fingerprint, now)) {
      _suppressedDuplicates += 1;
      return;
    }
    _emitSuppressedDuplicatesIfAny(context, now);

    _sequence += 1;
    final timeStr = _timeFormat.format(now);
    final data = _normalizeExtra(extra);
    final extraStr = data == null ? '' : ' | data: $data';
    final stackStr = stackTrace == null ? '' : '\nSTACK:\n$stackTrace';
    final logLine =
        '[#$_sequence][$timeStr][$level][$context][session=$_sessionId] $message$extraStr$stackStr';

    _writeConsole(logLine);

    if (_recentLogs.length >= _maxRecentLogs) {
      _recentLogs.removeAt(0);
    }
    _recentLogs.add(logLine);

    _queueFileLine('$logLine\n');
    _scheduleFlush();

    developer.log(
      message,
      name: context,
      level: _getLevel(level),
      error: error,
      stackTrace: stackTrace,
      time: now,
    );

    _forwardToCrashlytics(
      level: level,
      context: context,
      message: message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static bool _isDuplicateWithinWindow(String fingerprint, DateTime now) {
    if (_lastFingerprint == null ||
        _lastFingerprintAt == null ||
        _lastFingerprint != fingerprint ||
        now.difference(_lastFingerprintAt!) > _duplicateWindow) {
      _lastFingerprint = fingerprint;
      _lastFingerprintAt = now;
      return false;
    }
    _lastFingerprintAt = now;
    return true;
  }

  static void _emitSuppressedDuplicatesIfAny(String context, DateTime now) {
    if (_suppressedDuplicates == 0) return;
    final timeStr = _timeFormat.format(now);
    final line =
        '[#${_sequence + 1}][$timeStr][DEBUG][$context][session=$_sessionId] Suppressed $_suppressedDuplicates duplicate log event(s)';
    _sequence += 1;
    _writeConsole(line);
    _queueFileLine('$line\n');
    _suppressedDuplicates = 0;
  }

  static Map<String, dynamic>? _normalizeExtra(Map<String, dynamic>? extra) {
    if (extra == null || extra.isEmpty) return null;
    final normalized = <String, dynamic>{};
    extra.forEach((key, value) {
      normalized[key] = _truncate(_serializeData(value));
    });
    return normalized;
  }

  static String _serializeData(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }

  static String _truncate(String value) {
    if (value.length <= _maxDataChars) return value;
    return '${value.substring(0, _maxDataChars)}...[truncated:${value.length - _maxDataChars}]';
  }

  static void _queueFileLine(String line) {
    if (_pendingFileLines.length >= _maxPendingLines) {
      _pendingFileLines.removeFirst();
    }
    _pendingFileLines.add(line);
  }

  static void _scheduleFlush() {
    if (_sink == null || _pendingFileLines.isEmpty) return;
    final now = DateTime.now();
    if (_lastFlushAt == null ||
        now.difference(_lastFlushAt!) > const Duration(milliseconds: 250)) {
      _lastFlushAt = now;
      Future<void>.microtask(_flushPendingLines);
    }
  }

  static Future<void> _flushPendingLines({bool force = false}) async {
    if (_sink == null || _pendingFileLines.isEmpty) return;

    try {
      while (_pendingFileLines.isNotEmpty) {
        _sink!.write(_pendingFileLines.removeFirst());
      }
      if (force) {
        await _sink!.flush();
      }
    } catch (e) {
      _writeConsole('Failed to write log: $e');
    }
  }

  static void _writeConsole(String line) {
    try {
      debugPrint(line);
    } catch (_) {
      // Best effort console path.
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

  static void _forwardToCrashlytics({
    required String level,
    required String context,
    required String message,
    required Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_crashlyticsForwardingEnabled ||
        kIsWeb ||
        Firebase.apps.isEmpty ||
        !_shouldForwardLevel(level)) {
      return;
    }

    final breadcrumb =
        '[${level.toUpperCase()}][$context] $message'
        '${data == null ? '' : ' data=$data'}';
    unawaited(FirebaseCrashlytics.instance.log(_truncate(breadcrumb)));

    if (level == 'ERROR' && _crashlyticsRecordNonFatalErrors) {
      final errObject = error ?? Exception('[$context] $message');
      unawaited(
        FirebaseCrashlytics.instance.recordError(
          errObject,
          stackTrace ?? StackTrace.current,
          reason: 'AppLogger ERROR in $context',
          information: data == null ? const <Object>[] : <Object>[data.toString()],
          fatal: false,
        ),
      );
    }
  }

  static bool _shouldForwardLevel(String level) {
    switch (level) {
      case 'ERROR':
      case 'WARN':
        return true;
      case 'INFO':
      case 'UI':
      case 'NETWORK':
        return _crashlyticsIncludeInfo;
      case 'DEBUG':
        return _crashlyticsIncludeDebug;
      default:
        return false;
    }
  }

  static Future<String> exportLogs() async {
    await _flushPendingLines(force: true);
    if (_logFile != null && await _logFile!.exists()) {
      return _logFile!.path;
    }
    return 'Log file unavailable';
  }
}
