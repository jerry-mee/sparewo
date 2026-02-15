// lib/services/verification_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../exceptions/auth_exceptions.dart';
import '../services/email_service.dart';
import '../services/logger_service.dart';
import '../constants/api_constants.dart';

class VerificationService {
  final FirebaseFirestore _firestore;
  final EmailService _emailService;
  final LoggerService _logger = LoggerService.instance;

  late final CollectionReference _verificationCodesRef;

  static const int CODE_LENGTH = 6;
  static const int MAX_RETRIES = 5;

  VerificationService({
    required FirebaseFirestore firestore,
    required EmailService emailService,
  })  : _firestore = firestore,
        _emailService = emailService {
    _verificationCodesRef =
        _firestore.collection(ApiConstants.verificationCodesCollection);
    _logger.info('Verification service initialized');
  }

  Future<void> init() async {
    _logger.info('Verification service init called');
  }

  Future<void> sendVerificationCode({
    required String email,
    bool isVendor = true,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final code = _generateVerificationCode();
    _logger.info('Generated code for $normalizedEmail: $code');

    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _verificationCodesRef.doc(normalizedEmail);
        final data = {
          'code': code,
          'created_at': FieldValue.serverTimestamp(),
          'expires_at': Timestamp.fromDate(
              DateTime.now().add(const Duration(minutes: 30))),
          'verified': false,
          'attempts': 0,
          'email': normalizedEmail,
        };
        transaction.set(
            docRef, data); // Use set to overwrite any existing code.
      });
      _logger.info('Saved verification code for $normalizedEmail');
    } catch (e) {
      _logger.error('Failed to save verification code to Firestore', error: e);
      throw VerificationException(
        message: 'Could not prepare verification. Please try again.',
        code: AuthException.verificationFailed,
        wasCodeGenerated: false,
      );
    }

    final bool sent = await _emailService.sendVerificationEmail(
      to: normalizedEmail,
      code: code,
      isVendor: isVendor,
    );

    if (!sent) {
      throw VerificationException(
        message:
            'Failed to send verification email. Please check the address and try again.',
        code: AuthException.verificationFailed,
        wasCodeGenerated: true,
      );
    }
  }

  Future<bool> verifyCode(String email, String code) async {
    final normalizedEmail = email.trim().toLowerCase();
    _logger.info('Verifying code for $normalizedEmail: $code');
    final docRef = _verificationCodesRef.doc(normalizedEmail);

    return _firestore.runTransaction<bool>((transaction) async {
      final doc = await transaction.get(docRef);

      if (!doc.exists) {
        throw VerificationException(
          message:
              'Verification code not found or expired. Please request a new one.',
          code: AuthException.verificationNotFound,
        );
      }

      final data = doc.data() as Map<String, dynamic>;
      final storedCode = data['code'] as String;
      final expiryTime = (data['expires_at'] as Timestamp).toDate();
      final attempts = (data['attempts'] as int?) ?? 0;

      if (DateTime.now().isAfter(expiryTime)) {
        transaction.delete(docRef);
        throw VerificationException(
          message: 'Verification code has expired. Please request a new one.',
          code: AuthException.verificationExpired,
          expiresAt: expiryTime,
        );
      }

      if (attempts >= MAX_RETRIES) {
        transaction.delete(docRef);
        throw VerificationException(
          message: 'Too many failed attempts. Please request a new one.',
          code: AuthException.tooManyAttempts,
          attempts: attempts,
        );
      }

      if (code != storedCode) {
        transaction.update(docRef, {'attempts': FieldValue.increment(1)});
        throw VerificationException(
          message: 'Invalid verification code.',
          code: AuthException.invalidVerificationCode,
          attempts: attempts + 1,
        );
      }

      transaction.update(docRef,
          {'verified': true, 'verified_at': FieldValue.serverTimestamp()});
      return true;
    });
  }

  Future<bool> verifyEmail(
      {required String email, required String code}) async {
    return verifyCode(email, code);
  }

  String _generateVerificationCode() {
    final random = Random.secure();
    return List.generate(CODE_LENGTH, (_) => random.nextInt(10)).join();
  }

  Future<void> removeVerificationCode(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      await _verificationCodesRef.doc(normalizedEmail).delete();
      _logger.info('Removed verification code for $normalizedEmail');
    } catch (e) {
      _logger.error('Failed to remove verification code', error: e);
    }
  }

  Future<bool> _tryAllSendMethods(
      String email, String code, bool isVendor, List<dynamic> errors) async {
    // Method 1: Use EmailService first
    try {
      await _emailService.sendVerificationEmail(
        to: email,
        code: code,
        isVendor: isVendor,
      );
      _logger.info('Verification email sent successfully via EmailService');
      return true;
    } catch (e) {
      _logger.warning('EmailService failed to send verification email',
          error: e);
      errors.add({'method': 'emailService', 'error': e.toString()});
    }

    // Method 2: Direct HTTP call (fallback)
    try {
      final response = await _sendViaHttpEndpoint(email, code, isVendor);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _logger.info('Verification email sent successfully via direct HTTP');
        return true;
      } else {
        final errorMsg =
            'HTTP error: ${response.statusCode} - ${response.body}';
        _logger.warning(errorMsg);
        errors.add({'method': 'http', 'error': errorMsg});
      }
    } catch (e) {
      _logger.warning('HTTP request failed', error: e);
      errors.add({'method': 'http', 'error': e.toString()});
    }

    return false;
  }

  Future<http.Response> _sendViaHttpEndpoint(
      String email, String code, bool isVendor) async {
    final url = Uri.parse(
        '${ApiConstants.firebaseFunctionsBaseUrl}/api/sendVerificationEmail');

    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Origin': kIsWeb ? Uri.base.origin : 'app://sparewo.ug',
      },
      body: jsonEncode({
        'to': email,
        'code': code,
        'isVendor': isVendor,
      }),
    );
  }
}
