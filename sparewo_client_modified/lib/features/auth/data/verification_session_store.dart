import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';

class PendingVerificationSession {
  const PendingVerificationSession({
    required this.email,
    required this.password,
    required this.name,
    required this.code,
    required this.expiresAt,
    this.existingAccount = true,
    this.attemptCount = 0,
  });

  final String email;
  final String password;
  final String name;
  final String code;
  final DateTime expiresAt;
  final bool existingAccount;
  final int attemptCount;

  PendingVerificationSession copyWith({
    String? email,
    String? password,
    String? name,
    String? code,
    DateTime? expiresAt,
    bool? existingAccount,
    int? attemptCount,
  }) {
    return PendingVerificationSession(
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      code: code ?? this.code,
      expiresAt: expiresAt ?? this.expiresAt,
      existingAccount: existingAccount ?? this.existingAccount,
      attemptCount: attemptCount ?? this.attemptCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'code': code,
      'expiresAt': expiresAt.toIso8601String(),
      'existingAccount': existingAccount,
      'attemptCount': attemptCount,
    };
  }

  factory PendingVerificationSession.fromJson(Map<String, dynamic> json) {
    return PendingVerificationSession(
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      expiresAt:
          DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      existingAccount: json['existingAccount'] as bool? ?? true,
      attemptCount: json['attemptCount'] as int? ?? 0,
    );
  }
}

class VerificationSessionStore {
  VerificationSessionStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _keyPrefix = 'sparewo.pending.verification.';
  final FlutterSecureStorage _secureStorage;

  String _sessionKey(String normalizedEmail) => '$_keyPrefix$normalizedEmail';

  Future<void> save(PendingVerificationSession session) async {
    AppLogger.debug(
      'VerificationSessionStore',
      'Saving pending verification session',
      extra: {'email': session.email, 'attempts': session.attemptCount},
    );
    await _secureStorage.write(
      key: _sessionKey(session.email),
      value: jsonEncode(session.toJson()),
    );
  }

  Future<PendingVerificationSession?> load(String normalizedEmail) async {
    final raw = await _secureStorage.read(key: _sessionKey(normalizedEmail));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return PendingVerificationSession.fromJson(decoded);
    } catch (e) {
      AppLogger.error(
        'VerificationSessionStore',
        'Failed to decode stored verification session',
        error: e,
        extra: {'email': normalizedEmail},
      );
      return null;
    }
  }

  Future<void> clear(String normalizedEmail) {
    AppLogger.debug(
      'VerificationSessionStore',
      'Clearing pending verification session',
      extra: {'email': normalizedEmail},
    );
    return _secureStorage.delete(key: _sessionKey(normalizedEmail));
  }

  Future<PendingVerificationSession?> incrementAttempts(
    String normalizedEmail,
  ) async {
    final session = await load(normalizedEmail);
    if (session == null) return null;
    final updated = session.copyWith(attemptCount: session.attemptCount + 1);
    await save(updated);
    return updated;
  }

  Future<void> resetAttempts(String normalizedEmail) async {
    final session = await load(normalizedEmail);
    if (session == null) return;
    await save(session.copyWith(attemptCount: 0));
  }
}
