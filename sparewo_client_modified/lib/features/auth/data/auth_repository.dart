// lib/features/auth/data/auth_repository.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/features/auth/data/verification_session_store.dart';
import 'package:sparewo_client/features/auth/domain/user_model.dart';

import 'package:sparewo_client/features/shared/services/email_service.dart';

class AuthCancelledException implements Exception {
  final String message;
  AuthCancelledException([this.message = 'Sign in cancelled']);
  @override
  String toString() => message;
}

class ReauthenticationRequiredException implements Exception {
  final String message;
  ReauthenticationRequiredException([
    this.message =
        'For security, please reauthenticate and try deleting your account again.',
  ]);
  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    EmailService? emailService,
    GoogleSignIn? googleSignIn,
    VerificationSessionStore? verificationSessionStore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1'),
       _emailService = emailService ?? EmailService(),
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _verificationStore =
           verificationSessionStore ?? VerificationSessionStore();

  static const _verificationExpiry = Duration(minutes: 30);
  static const _maxVerificationAttempts = 5;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final EmailService _emailService;
  final GoogleSignIn _googleSignIn;
  final VerificationSessionStore _verificationStore;

  bool _lastRegistrationWasPartial = false;
  Future<UserModel>? _googleSignInOperation;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Stream<UserModel?> get userProfileChanges {
    return Stream.multi((controller) {
      StreamSubscription<User?>? authSubscription;
      StreamSubscription<UserModel?>? profileSubscription;
      var authChangeVersion = 0;

      Future<void> cancelProfile() async {
        final current = profileSubscription;
        profileSubscription = null;
        if (current != null) {
          await current.cancel();
        }
      }

      authSubscription = _auth.authStateChanges().listen((user) async {
        final eventVersion = ++authChangeVersion;
        await cancelProfile();
        if (eventVersion != authChangeVersion || controller.isClosed) return;
        if (user == null) {
          controller.add(null);
          return;
        }
        final nextSubscription = _safeUserProfileStream(
          user,
        ).listen(controller.add, onError: controller.addError);
        if (eventVersion != authChangeVersion || controller.isClosed) {
          await nextSubscription.cancel();
          return;
        }
        profileSubscription = nextSubscription;
      }, onError: controller.addError);

      controller.onCancel = () async {
        authChangeVersion += 1;
        await cancelProfile();
        await authSubscription?.cancel();
      };
    });
  }

  User? get currentUser => _auth.currentUser;

  bool _isCurrentUser(String uid) => _auth.currentUser?.uid == uid;

  Stream<UserModel?> _safeUserProfileStream(User user) async* {
    const retryDelay = Duration(seconds: 5);
    const maxPermissionRetryAttempts = 6;
    var attempt = 0;
    while (true) {
      if (!_isCurrentUser(user.uid)) return;
      final candidateCollections = <CollectionReference<Map<String, dynamic>>>[
        _firestore.collection('users'),
        _firestore.collection('clients'),
      ];
      var blockedCollections = 0;

      for (final collection in candidateCollections) {
        final collectionName = collection.path;
        final doc = collection.doc(user.uid);

        try {
          AppLogger.debug(
            'AuthRepository.userProfileChanges',
            'Subscribing to user profile stream',
            extra: {
              'uid': user.uid,
              'collection': collectionName,
              'attempt': attempt,
            },
          );
          await for (final snapshot in doc.snapshots()) {
            final data = snapshot.data();
            if (data == null) {
              yield _fallbackUserProfileFromAuth(user);
              continue;
            }
            yield UserModel.fromJson({'id': user.uid, ...data});
          }

          return;
        } on FirebaseException catch (error) {
          if (error.code == 'permission-denied' ||
              error.code == 'unauthenticated') {
            blockedCollections += 1;
            AppLogger.warn(
              'AuthRepository.userProfileChanges',
              'Profile stream blocked for this collection; trying fallback collection',
              extra: {
                'uid': user.uid,
                'collection': collectionName,
                'code': error.code,
                'attempt': attempt,
              },
            );
            continue;
          }
          rethrow;
        }
      }

      AppLogger.warn(
        'AuthRepository.userProfileChanges',
        'All profile streams blocked; using auth fallback and retrying',
        extra: {
          'uid': user.uid,
          'attempt': attempt,
          'blocked': blockedCollections,
        },
      );
      if (!_isCurrentUser(user.uid)) return;
      yield _fallbackUserProfileFromAuth(user);
      if (attempt >= maxPermissionRetryAttempts) {
        AppLogger.warn(
          'AuthRepository.userProfileChanges',
          'Profile stream retries exhausted; holding auth fallback until next auth state change',
          extra: {
            'uid': user.uid,
            'attempt': attempt,
            'blocked': blockedCollections,
          },
        );
        return;
      }
      attempt += 1;
      await Future<void>.delayed(retryDelay);
    }
  }

  UserModel _fallbackUserProfileFromAuth(User user) {
    final normalizedEmail = _normalizeEmail(user.email ?? '');
    final fallbackName =
        _normalizeDisplayName(user.displayName) ??
        (normalizedEmail.isNotEmpty
            ? _bestEffortNameFromEmail(normalizedEmail)
            : 'SpareWo User');
    return UserModel(
      id: user.uid,
      name: fallbackName,
      email: normalizedEmail,
      isEmailVerified: user.emailVerified,
      createdAt: DateTime.now(),
    );
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  String? _normalizeDisplayName(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String _bestEffortNameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) return 'SpareWo User';
    final spaced = localPart.replaceAll(RegExp(r'[._-]+'), ' ').trim();
    if (spaced.isEmpty) return 'SpareWo User';
    return spaced
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part.length == 1
              ? part.toUpperCase()
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  bool _isPlaceholderUserName(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == null ||
        normalized.isEmpty ||
        normalized == 'user' ||
        normalized == 'sparewo user';
  }

  String _resolvePreferredProfileName({
    required String? socialProvidedName,
    required String? firebaseDisplayName,
    required String normalizedEmail,
  }) {
    final normalizedSocialName = _normalizeDisplayName(socialProvidedName);
    if (!_isPlaceholderUserName(normalizedSocialName)) {
      return normalizedSocialName!;
    }

    final normalizedFirebaseName = _normalizeDisplayName(firebaseDisplayName);
    if (!_isPlaceholderUserName(normalizedFirebaseName)) {
      return normalizedFirebaseName!;
    }

    if (normalizedEmail.isNotEmpty) {
      return _bestEffortNameFromEmail(normalizedEmail);
    }

    return 'SpareWo User';
  }

  Future<String?> _findConflictingUserProfileUid({
    required String normalizedEmail,
    required String currentUid,
  }) async {
    try {
      final matches = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(5)
          .get();
      for (final doc in matches.docs) {
        if (doc.id != currentUid) return doc.id;
      }
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        AppLogger.warn(
          'AuthRepository.duplicateCheck',
          'Skipping duplicate check: query blocked by Firestore rules',
          extra: {'email': normalizedEmail, 'uid': currentUid},
        );
        return null;
      }
      rethrow;
    }
  }

  Future<String?> _lookupExistingNameByEmail({
    required String normalizedEmail,
    String? excludingUid,
  }) async {
    try {
      final userDocs = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(5)
          .get();
      for (final doc in userDocs.docs) {
        if (excludingUid != null && doc.id == excludingUid) continue;
        final candidate = _normalizeDisplayName(doc.data()['name']?.toString());
        if (candidate != null) return candidate;
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      AppLogger.warn(
        'AuthRepository.nameLookup',
        'Skipping cross-user name lookup: query blocked by Firestore rules',
        extra: {'email': normalizedEmail, 'uid': excludingUid},
      );
      return null;
    }
    return null;
  }

  bool takeLastRegistrationWasPartial() {
    final value = _lastRegistrationWasPartial;
    _lastRegistrationWasPartial = false;
    return value;
  }

  Future<UserModel?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromJson({'id': user.uid, ...doc.data()!});
  }

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    AppLogger.info(
      'AuthRepository.signIn',
      'Attempting email sign-in',
      extra: {'email': normalizedEmail},
    );
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user!;
      DocumentSnapshot<Map<String, dynamic>>? profile;
      Map<String, dynamic>? profileData;
      try {
        profile = await _firestore.collection('users').doc(user.uid).get();
        profileData = profile.data();
      } on FirebaseException catch (error, stack) {
        if (error.code == 'permission-denied' ||
            error.code == 'unauthenticated') {
          AppLogger.warn(
            'AuthRepository.signIn',
            'Profile lookup blocked after successful auth; continuing with auth fallback',
            extra: {
              'uid': user.uid,
              'email': normalizedEmail,
              'code': error.code,
              'stack': stack.toString(),
            },
          );
          return _fallbackUserProfileFromAuth(user);
        }
        rethrow;
      }
      final isEmailVerified = profileData?['isEmailVerified'] == true;
      if (!profile.exists || !isEmailVerified) {
        AppLogger.warn(
          'AuthRepository.signIn',
          'Signed in user has incomplete setup',
          extra: {'uid': user.uid, 'email': normalizedEmail},
        );
        await _auth.signOut();
        throw Exception(
          '__INCOMPLETE_SETUP__Account setup incomplete. Verify your email to finish onboarding.',
        );
      }
      AppLogger.info(
        'AuthRepository.signIn',
        'Sign-in succeeded',
        extra: {'uid': user.uid, 'email': normalizedEmail},
      );
      return UserModel.fromJson({'id': user.uid, ...profileData!});
    } on FirebaseAuthException catch (e) {
      AppLogger.warn(
        'AuthRepository.signIn',
        'FirebaseAuthException',
        extra: {'email': normalizedEmail, 'code': e.code, 'message': e.message},
      );
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this email address');
      }
      if (e.code == 'wrong-password') {
        throw Exception('Incorrect password');
      }
      if (e.code == 'invalid-credential') {
        throw Exception('Invalid email or password');
      }
      if (e.code == 'invalid-email') {
        throw Exception('Invalid email address');
      }
      if (e.code == 'user-disabled') {
        throw Exception('This account has been disabled');
      }
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      AppLogger.error(
        'AuthRepository.signIn',
        'Unexpected sign-in failure',
        error: e,
        extra: {'email': normalizedEmail},
      );
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> startRegistration({
    required String email,
    required String password,
    required String name,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    User? createdUser;
    AppLogger.info(
      'AuthRepository.startRegistration',
      'Starting registration',
      extra: {'email': normalizedEmail},
    );
    try {
      _lastRegistrationWasPartial = false;
      if (!RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      ).hasMatch(normalizedEmail)) {
        throw Exception('Please enter a valid email address');
      }

      UserCredential credential;
      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          AppLogger.info(
            'AuthRepository',
            'Signup create blocked: email already in use',
            extra: {'email': normalizedEmail},
          );
          await _resumeExistingRegistration(
            email: normalizedEmail,
            password: password,
            name: name,
          );
          return;
        }
        if (e.code == 'weak-password') {
          throw Exception(
            'Password is too weak. Please use at least 8 characters with uppercase and numbers.',
          );
        }
        rethrow;
      }

      createdUser = credential.user;
      if (createdUser == null) {
        throw Exception('Failed to create your account. Please try again.');
      }
      final resolvedName = name.trim().isNotEmpty
          ? name.trim()
          : 'SpareWo User';
      if (resolvedName.isNotEmpty) {
        await createdUser.updateDisplayName(resolvedName);
      }
      await _getOrCreateUserData(
        createdUser,
        name: resolvedName,
        markEmailVerified: false,
      );

      final code = _generateVerificationCode();
      final emailSent = await _emailService
          .sendVerificationEmail(
            to: normalizedEmail,
            code: code,
            customerName: resolvedName,
          )
          .timeout(const Duration(seconds: 4), onTimeout: () => false);

      if (!emailSent) {
        AppLogger.warn(
          'AuthRepository.startRegistration',
          'Initial verification email send deferred/failed; user can resend from verification screen',
          extra: {'email': normalizedEmail},
        );
      }

      await _verificationStore.save(
        PendingVerificationSession(
          email: normalizedEmail,
          password: password,
          name: resolvedName,
          code: code,
          expiresAt: DateTime.now().add(_verificationExpiry),
          existingAccount: true,
          attemptCount: 0,
        ),
      );
      AppLogger.info(
        'AuthRepository.startRegistration',
        'Verification session saved',
        extra: {
          'email': normalizedEmail,
          'expiresAt': DateTime.now()
              .add(_verificationExpiry)
              .toIso8601String(),
        },
      );

      await _auth.signOut();
      AppLogger.info(
        'AuthRepository.startRegistration',
        'Registration staged and user signed out pending verification',
        extra: {'email': normalizedEmail},
      );
    } catch (e) {
      AppLogger.error(
        'AuthRepository.startRegistration',
        'Registration start failed',
        error: e,
        extra: {'email': normalizedEmail, 'createdUid': createdUser?.uid},
      );
      if (createdUser != null) {
        try {
          await _firestore.collection('users').doc(createdUser.uid).delete();
        } catch (_) {}
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      await _verificationStore.clear(normalizedEmail);
      rethrow;
    }
  }

  Future<void> resumeIncompleteOnboarding({
    required String email,
    required String password,
    String? name,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    AppLogger.info(
      'AuthRepository.resumeIncomplete',
      'Attempting resume incomplete onboarding',
      extra: {'email': normalizedEmail},
    );
    try {
      _lastRegistrationWasPartial = false;
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Could not resume setup. Please try again.');
      }

      final profile = await _firestore.collection('users').doc(user.uid).get();
      final profileData = profile.data();
      final isEmailVerified = profileData?['isEmailVerified'] == true;
      if (profile.exists && isEmailVerified) {
        AppLogger.warn(
          'AuthRepository.resumeIncomplete',
          'Resume blocked: account already verified',
          extra: {'email': normalizedEmail, 'uid': user.uid},
        );
        await _auth.signOut();
        throw Exception(
          'This email is already registered. Please login instead.',
        );
      }

      final displayName = (name?.trim().isNotEmpty == true)
          ? name!.trim()
          : (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : 'SpareWo User');

      await _getOrCreateUserData(
        user,
        name: displayName,
        markEmailVerified: false,
      );

      final code = _generateVerificationCode();
      final emailSent = await _emailService
          .sendVerificationEmail(
            to: normalizedEmail,
            code: code,
            customerName: displayName,
          )
          .timeout(const Duration(seconds: 4), onTimeout: () => false);

      await _auth.signOut();

      if (!emailSent) {
        AppLogger.warn(
          'AuthRepository.resumeIncomplete',
          'Initial verification email resend deferred/failed; user can resend from verification screen',
          extra: {'email': normalizedEmail},
        );
      }

      await _verificationStore.save(
        PendingVerificationSession(
          email: normalizedEmail,
          password: password,
          name: displayName,
          code: code,
          expiresAt: DateTime.now().add(_verificationExpiry),
          existingAccount: true,
          attemptCount: 0,
        ),
      );
      _lastRegistrationWasPartial = true;
      AppLogger.info(
        'AuthRepository.resumeIncomplete',
        'Resume succeeded and verification session refreshed',
        extra: {'email': normalizedEmail, 'uid': user.uid},
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.warn(
        'AuthRepository.resumeIncomplete',
        'FirebaseAuthException while resuming',
        extra: {'email': normalizedEmail, 'code': e.code, 'message': e.message},
      );
      try {
        await _auth.signOut();
      } catch (_) {}
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception(
          'This email already exists. Use the original password to continue verification, or reset your password.',
        );
      }
      if (e.code == 'user-not-found') {
        throw Exception(
          'No account found for this email. Please sign up again.',
        );
      }
      throw Exception('Could not resume setup. Please try again.');
    }
  }

  Future<UserModel> verifyEmailAndCompleteRegistration({
    required String email,
    required String code,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    AppLogger.info(
      'AuthRepository.verifyCode',
      'Attempting verification completion',
      extra: {'email': normalizedEmail},
    );
    final session = await _verificationStore.load(normalizedEmail);
    if (session == null) {
      AppLogger.warn(
        'AuthRepository.verifyCode',
        'No pending session found',
        extra: {'email': normalizedEmail},
      );
      throw Exception(
        'Your session expired. Please return to login and sign in again to receive a new verification code.',
      );
    }

    if (DateTime.now().isAfter(session.expiresAt)) {
      AppLogger.warn(
        'AuthRepository.verifyCode',
        'Session expired',
        extra: {
          'email': normalizedEmail,
          'expiresAt': session.expiresAt.toIso8601String(),
        },
      );
      await _verificationStore.clear(normalizedEmail);
      throw Exception(
        'Verification code has expired. Please request a new one.',
      );
    }

    if (session.code != code) {
      final updated = await _verificationStore.incrementAttempts(
        normalizedEmail,
      );
      final attempts = updated?.attemptCount ?? (session.attemptCount + 1);
      final remaining = _maxVerificationAttempts - attempts;
      AppLogger.warn(
        'AuthRepository.verifyCode',
        'Invalid verification code',
        extra: {
          'email': normalizedEmail,
          'attempts': attempts,
          'remaining': remaining,
        },
      );
      if (remaining <= 0) {
        await _verificationStore.clear(normalizedEmail);
        throw Exception(
          'Too many invalid attempts. Request a new verification code and try again.',
        );
      }
      throw Exception(
        'Invalid verification code. Please check and try again. $remaining attempt(s) remaining.',
      );
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: session.email,
        password: session.password,
      );
      final fbUser = credential.user!;
      if ((fbUser.displayName ?? '').trim().isEmpty) {
        await fbUser.updateDisplayName(session.name);
      }

      final user = await _getOrCreateUserData(
        fbUser,
        name: session.name,
        markEmailVerified: true,
      );

      await _verificationStore.clear(normalizedEmail);
      AppLogger.info(
        'AuthRepository.verifyCode',
        'Verification completed successfully',
        extra: {'email': normalizedEmail, 'uid': fbUser.uid},
      );

      await _emailService.sendWelcomeEmail(
        to: normalizedEmail,
        customerName: session.name,
      );

      return user;
    } on FirebaseAuthException catch (e) {
      AppLogger.warn(
        'AuthRepository.verifyCode',
        'FirebaseAuthException while completing verification',
        extra: {'email': normalizedEmail, 'code': e.code, 'message': e.message},
      );
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        throw Exception(
          'Could not verify your setup with the original credentials. Please restart signup.',
        );
      }
      if (e.code == 'user-not-found') {
        throw Exception('Account session not found. Please sign up again.');
      }
      throw Exception('Registration failed: ${e.message}');
    } catch (e) {
      AppLogger.error(
        'AuthRepository.verifyCode',
        'Unexpected verification failure',
        error: e,
        extra: {'email': normalizedEmail},
      );
      if (e is Exception) rethrow;
      throw Exception('Failed to create account. Please try again.');
    }
  }

  Future<void> resendVerificationCode({required String email}) async {
    final normalizedEmail = _normalizeEmail(email);
    AppLogger.info(
      'AuthRepository.resendCode',
      'Attempting verification code resend',
      extra: {'email': normalizedEmail},
    );
    final session = await _verificationStore.load(normalizedEmail);
    if (session == null) {
      AppLogger.warn(
        'AuthRepository.resendCode',
        'Resend blocked: no pending session',
        extra: {'email': normalizedEmail},
      );
      throw Exception(
        'Your session expired. Please return to login and sign in again to receive a new code.',
      );
    }

    final code = _generateVerificationCode();
    final refreshed = session.copyWith(
      code: code,
      expiresAt: DateTime.now().add(_verificationExpiry),
      attemptCount: 0,
    );

    final emailSent = await _emailService.sendVerificationEmail(
      to: normalizedEmail,
      code: code,
      customerName: refreshed.name,
    );

    if (!emailSent) {
      AppLogger.warn(
        'AuthRepository.resendCode',
        'Verification resend failed',
        extra: {'email': normalizedEmail},
      );
      throw Exception('Failed to send verification email. Please try again.');
    }

    await _verificationStore.save(refreshed);
    AppLogger.info(
      'AuthRepository.resendCode',
      'Verification code resent successfully',
      extra: {'email': normalizedEmail},
    );
  }

  String _generateVerificationCode() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256OfString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  Map<String, dynamic>? _decodeJwtClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _claimString(Map<String, dynamic>? claims, String key) {
    final value = claims?[key];
    if (value == null) return null;
    return value.toString();
  }

  OAuthCredential _buildAppleOAuthCredential({
    required AuthorizationCredentialAppleID appleCredential,
    required String rawNonce,
  }) {
    final idToken = appleCredential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Apple sign in failed: missing identity token.');
    }
    final authorizationCode = appleCredential.authorizationCode;
    return OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
      accessToken: authorizationCode.isNotEmpty ? authorizationCode : null,
    );
  }

  Future<void> _guardAgainstDuplicateSocialProfile({
    required User firebaseUser,
    required UserCredential credential,
    required String providerLabel,
  }) async {
    final email = firebaseUser.email;
    if (email == null || email.isEmpty) return;

    final normalizedEmail = _normalizeEmail(email);
    final conflictingUid = await _findConflictingUserProfileUid(
      normalizedEmail: normalizedEmail,
      currentUid: firebaseUser.uid,
    );
    if (conflictingUid == null) return;

    AppLogger.warn(
      'AuthRepository.socialSignIn',
      'Blocked duplicate profile creation for same email',
      extra: {
        'provider': providerLabel,
        'email': normalizedEmail,
        'currentUid': firebaseUser.uid,
        'existingUid': conflictingUid,
        'isNewUser': credential.additionalUserInfo?.isNewUser,
      },
    );

    if (credential.additionalUserInfo?.isNewUser == true) {
      final mergedOnBackend = await _attemptDuplicateMergeViaBackend(
        sourceUid: firebaseUser.uid,
        targetUid: conflictingUid,
        normalizedEmail: normalizedEmail,
        providerLabel: providerLabel,
      );
      if (mergedOnBackend) {
        try {
          await _auth.signOut();
        } catch (_) {}
        throw Exception(
          'This email already has a SpareWo account. '
          'We safely merged the duplicate profile. '
          'Sign in with your existing method, then link $providerLabel in Settings > Security.',
        );
      }

      try {
        await firebaseUser.delete();
      } catch (e) {
        AppLogger.warn(
          'AuthRepository.socialSignIn',
          'Failed to auto-delete new duplicate auth account',
          extra: {'provider': providerLabel, 'uid': firebaseUser.uid},
        );
      }
    }
    try {
      await _auth.signOut();
    } catch (_) {}

    throw Exception(
      'This email already has a SpareWo account. '
      'Sign in with your existing method, then go to Settings > Security to link $providerLabel.',
    );
  }

  Future<bool> _attemptDuplicateMergeViaBackend({
    required String sourceUid,
    required String targetUid,
    required String normalizedEmail,
    required String providerLabel,
  }) async {
    try {
      final callable = _functions.httpsCallable('mergeClientAccounts');
      final response = await callable.call(<String, dynamic>{
        'sourceUid': sourceUid,
        'targetUid': targetUid,
        'deleteSourceAuthUser': true,
      });
      final data = response.data;
      final ok = data is Map && data['ok'] == true;
      AppLogger.info(
        'AuthRepository.socialSignIn',
        'Duplicate account merge attempt completed',
        extra: {
          'provider': providerLabel,
          'email': normalizedEmail,
          'sourceUid': sourceUid,
          'targetUid': targetUid,
          'ok': ok,
          'result': data?.toString(),
        },
      );
      return ok;
    } catch (e, st) {
      AppLogger.warn(
        'AuthRepository.socialSignIn',
        'Duplicate account merge callable failed',
        extra: {
          'provider': providerLabel,
          'email': normalizedEmail,
          'sourceUid': sourceUid,
          'targetUid': targetUid,
          'error': e.toString(),
          'stack': st.toString(),
        },
      );
      return false;
    }
  }

  String _friendlyAppleAuthError(FirebaseAuthException e) {
    final message = (e.message ?? '').toLowerCase();
    if (e.code == 'operation-not-allowed' ||
        message.contains('identity provider configuration is not found')) {
      return 'Sign in with Apple is not available yet. Please try again shortly.';
    }
    if (e.code == 'invalid-credential') {
      return 'We could not validate your Apple credentials. Please try again.';
    }
    if (e.code == 'network-request-failed') {
      return 'Network issue detected. Check your connection and try again.';
    }
    return e.message ?? 'Apple sign in failed. Please try again.';
  }

  Future<void> _resumeExistingRegistration({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await resumeIncompleteOnboarding(
        email: email,
        password: password,
        name: name,
      );
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '').toLowerCase();
      if (message.contains('already registered') ||
          message.contains('please login instead')) {
        throw Exception(
          'This email is already registered. Please log in instead.',
        );
      }
      rethrow;
    }
  }

  // --- Social Sign In & Linking ---

  Future<UserModel> signInWithGoogle() {
    final inFlight = _googleSignInOperation;
    if (inFlight != null) {
      AppLogger.debug(
        'AuthRepository.signInWithGoogle',
        'Joining in-flight Google sign-in operation',
      );
      return inFlight;
    }

    final operation = _signInWithGoogleInternal();
    _googleSignInOperation = operation;
    operation.whenComplete(() {
      if (identical(_googleSignInOperation, operation)) {
        _googleSignInOperation = null;
      }
    });
    return operation;
  }

  Future<UserModel> _signInWithGoogleInternal() async {
    final stopwatch = Stopwatch()..start();
    void logPhase(String phase, {Map<String, Object?> extra = const {}}) {
      AppLogger.debug(
        'AuthRepository.signInWithGoogle',
        phase,
        extra: {'elapsedMs': stopwatch.elapsedMilliseconds, ...extra},
      );
    }

    try {
      logPhase('Starting Google sign-in intent');
      // Do not timeout the chooser step: it depends on user interaction.
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthCancelledException('Google sign in was cancelled');
      }

      logPhase('Google account selected');
      final googleAuth = await googleUser.authentication.timeout(
        const Duration(seconds: 30),
      );
      logPhase(
        'Google auth token resolved',
        extra: {
          'hasAccessToken': googleAuth.accessToken != null,
          'hasIdToken': googleAuth.idToken != null,
        },
      );

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      logPhase('Exchanging credential with Firebase Auth');
      final userCred = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 45));
      final fbUser = userCred.user;
      if (fbUser == null) {
        throw Exception('Failed to sign in with Google');
      }
      logPhase('Firebase Auth sign-in succeeded', extra: {'uid': fbUser.uid});
      await _guardAgainstDuplicateSocialProfile(
        firebaseUser: fbUser,
        credential: userCred,
        providerLabel: 'Google',
      );

      final user = await _getOrCreateUserData(
        fbUser,
        name: fbUser.displayName,
        markEmailVerified: true,
      ).timeout(const Duration(seconds: 45));
      logPhase('Profile hydration completed', extra: {'uid': user.id});
      return user;
    } on TimeoutException {
      throw Exception(
        'Google sign-in is taking too long. Please check your connection and try again.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
          'This email is already used with a different sign-in method. '
          'Please sign in with email and password, then link Google in Settings.',
        );
      }
      if (e.code == 'network-request-failed') {
        throw Exception(
          'Network issue detected. Please check your connection and try again.',
        );
      }
      throw Exception(e.message ?? 'Google sign in failed. Please try again.');
    } on FirebaseException catch (e, st) {
      if (e.code == 'permission-denied') {
        final fbUser = _auth.currentUser;
        if (fbUser != null) {
          final normalizedEmail = _normalizeEmail(fbUser.email ?? '');
          final fallbackName =
              _normalizeDisplayName(fbUser.displayName) ??
              (normalizedEmail.isNotEmpty
                  ? _bestEffortNameFromEmail(normalizedEmail)
                  : 'SpareWo User');
          AppLogger.warn(
            'AUTH',
            'Google sign in profile sync blocked by Firestore rules; continuing with auth user',
            extra: {
              'uid': fbUser.uid,
              'email': normalizedEmail,
              'error': e.toString(),
              'stack': st.toString(),
            },
          );
          return UserModel(
            id: fbUser.uid,
            name: fallbackName,
            email: normalizedEmail,
            isEmailVerified: true,
            createdAt: DateTime.now(),
          );
        }
      }
      rethrow;
    } catch (e, st) {
      if (e is AuthCancelledException) rethrow;
      if (_looksLikePermissionBlocked(e)) {
        final fallback = _fallbackSignedInUserModel(
          providerLabel: 'Google',
          error: e,
          stackTrace: st,
        );
        if (fallback != null) {
          return fallback;
        }
      }
      AppLogger.error('AUTH', 'Google sign in catch-all error', error: e);
      throw Exception('Google sign in failed. Please try again.');
    } finally {
      stopwatch.stop();
    }
  }

  Future<UserModel> signInWithApple() async {
    Map<String, dynamic>? tokenClaims;
    var hadAuthorizationCode = false;
    OAuthCredential? pendingAppleCredential;
    String? normalizedAppleEmailHint;
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Sign in with Apple is not available on this device.');
      }

      final rawNonce = _generateNonce();
      final hashedNonce = _sha256OfString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Apple sign in failed: missing identity token.');
      }
      tokenClaims = _decodeJwtClaims(idToken);
      normalizedAppleEmailHint = _normalizeEmail(
        (appleCredential.email ?? _claimString(tokenClaims, 'email') ?? '')
            .toString(),
      );
      hadAuthorizationCode = appleCredential.authorizationCode.isNotEmpty;
      AppLogger.info(
        'AuthRepository.signInWithApple',
        'Apple identity token received',
        extra: {
          'aud': _claimString(tokenClaims, 'aud'),
          'iss': _claimString(tokenClaims, 'iss'),
          'sub': _claimString(tokenClaims, 'sub'),
          'nonce': _claimString(tokenClaims, 'nonce'),
          'hasAuthorizationCode': hadAuthorizationCode,
        },
      );

      final oauthCredential = _buildAppleOAuthCredential(
        appleCredential: appleCredential,
        rawNonce: rawNonce,
      );
      pendingAppleCredential = oauthCredential;

      final userCred = await _auth.signInWithCredential(oauthCredential);
      final fbUser = userCred.user;
      if (fbUser == null) {
        throw Exception('Failed to sign in with Apple');
      }
      await _guardAgainstDuplicateSocialProfile(
        firebaseUser: fbUser,
        credential: userCred,
        providerLabel: 'Apple',
      );

      final fullName = [
        appleCredential.givenName?.trim(),
        appleCredential.familyName?.trim(),
      ].whereType<String>().where((part) => part.isNotEmpty).join(' ');

      final preferredName = _resolvePreferredProfileName(
        socialProvidedName: fullName,
        firebaseDisplayName: fbUser.displayName,
        normalizedEmail: _normalizeEmail(fbUser.email ?? ''),
      );
      if ((fbUser.displayName ?? '').trim().isEmpty ||
          _isPlaceholderUserName(fbUser.displayName)) {
        await fbUser.updateDisplayName(preferredName);
      }

      return await _getOrCreateUserData(
        fbUser,
        name: preferredName,
        markEmailVerified: true,
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.error(
        'AuthRepository.signInWithApple',
        'Firebase auth rejected Apple credential',
        error: e,
        extra: {
          'code': e.code,
          'message': e.message,
          'aud': _claimString(tokenClaims, 'aud'),
          'iss': _claimString(tokenClaims, 'iss'),
          'nonce': _claimString(tokenClaims, 'nonce'),
          'hasAuthorizationCode': hadAuthorizationCode,
        },
      );
      if (e.code == 'account-exists-with-different-credential') {
        final linkedUser =
            await _attemptLinkExistingSessionWithPendingCredential(
              pendingCredential: pendingAppleCredential,
              normalizedEmailHint: normalizedAppleEmailHint,
            );
        if (linkedUser != null) {
          return linkedUser;
        }
        throw Exception(
          'This email is already used with a different sign-in method. '
          'Please sign in with your existing method first, then link Apple in Settings > Security.',
        );
      }
      throw Exception(_friendlyAppleAuthError(e));
    } on FirebaseException catch (e, st) {
      if (e.code == 'permission-denied') {
        final fbUser = _auth.currentUser;
        if (fbUser != null) {
          final normalizedEmail = _normalizeEmail(fbUser.email ?? '');
          final fallbackName =
              _normalizeDisplayName(fbUser.displayName) ??
              (normalizedEmail.isNotEmpty
                  ? _bestEffortNameFromEmail(normalizedEmail)
                  : 'SpareWo User');
          AppLogger.warn(
            'AUTH',
            'Apple sign in profile sync blocked by Firestore rules; continuing with auth user',
            extra: {
              'uid': fbUser.uid,
              'email': normalizedEmail,
              'error': e.toString(),
              'stack': st.toString(),
            },
          );
          return UserModel(
            id: fbUser.uid,
            name: fallbackName,
            email: normalizedEmail,
            isEmailVerified: true,
            createdAt: DateTime.now(),
          );
        }
      }
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthCancelledException('Apple sign in was cancelled');
      }
      throw Exception('Apple sign in failed. Please try again.');
    } catch (e, st) {
      if (_looksLikePermissionBlocked(e)) {
        final fallback = _fallbackSignedInUserModel(
          providerLabel: 'Apple',
          error: e,
          stackTrace: st,
        );
        if (fallback != null) {
          return fallback;
        }
      }
      AppLogger.error('AUTH', 'Apple sign in catch-all error', error: e);
      if (e is Exception) rethrow;
      throw Exception('Apple sign in failed. Please try again.');
    }
  }

  bool _looksLikePermissionBlocked(Object error) {
    final normalized = error.toString().toLowerCase();
    return normalized.contains('permission-denied') ||
        normalized.contains('does not have permission');
  }

  UserModel? _fallbackSignedInUserModel({
    required String providerLabel,
    required Object error,
    StackTrace? stackTrace,
  }) {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    final normalizedEmail = _normalizeEmail(fbUser.email ?? '');
    final fallbackName =
        _normalizeDisplayName(fbUser.displayName) ??
        (normalizedEmail.isNotEmpty
            ? _bestEffortNameFromEmail(normalizedEmail)
            : 'SpareWo User');
    AppLogger.warn(
      'AUTH',
      '$providerLabel sign in profile sync blocked by Firestore rules; continuing with auth user',
      extra: {
        'provider': providerLabel,
        'uid': fbUser.uid,
        'email': normalizedEmail,
        'error': error.toString(),
        'stack': stackTrace?.toString() ?? '',
      },
    );
    return UserModel(
      id: fbUser.uid,
      name: fallbackName,
      email: normalizedEmail,
      isEmailVerified: true,
      createdAt: DateTime.now(),
    );
  }

  Future<UserModel> linkWithGoogle() async {
    final current = _auth.currentUser;
    if (current == null) {
      throw Exception('You must be signed in to link a Google account');
    }

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthCancelledException('Google sign in was cancelled');
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await current.linkWithCredential(credential);
      final fbUser = userCred.user ?? current;

      return await _getOrCreateUserData(
        fbUser,
        name: fbUser.displayName,
        markEmailVerified: true,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        throw Exception('Google is already linked to this account.');
      }
      if (e.code == 'credential-already-in-use') {
        throw Exception(
          'This Google account is already linked to another SpareWo account.',
        );
      }
      throw Exception('Failed to link Google account: ${e.message}');
    } catch (e) {
      throw Exception('Failed to link Google account. Please try again.');
    }
  }

  Future<UserModel> linkWithApple() async {
    final current = _auth.currentUser;
    if (current == null) {
      throw Exception('You must be signed in to link an Apple account');
    }

    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Sign in with Apple is not available on this device.');
      }

      final rawNonce = _generateNonce();
      final hashedNonce = _sha256OfString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final credential = _buildAppleOAuthCredential(
        appleCredential: appleCredential,
        rawNonce: rawNonce,
      );

      final userCred = await current.linkWithCredential(credential);
      final fbUser = userCred.user ?? current;

      final fullName = [
        appleCredential.givenName?.trim(),
        appleCredential.familyName?.trim(),
      ].whereType<String>().where((part) => part.isNotEmpty).join(' ');

      final preferredName = _resolvePreferredProfileName(
        socialProvidedName: fullName,
        firebaseDisplayName: fbUser.displayName,
        normalizedEmail: _normalizeEmail(fbUser.email ?? ''),
      );
      if ((fbUser.displayName ?? '').trim().isEmpty ||
          _isPlaceholderUserName(fbUser.displayName)) {
        await fbUser.updateDisplayName(preferredName);
      }

      return await _getOrCreateUserData(
        fbUser,
        name: preferredName,
        markEmailVerified: true,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthCancelledException('Apple sign in was cancelled');
      }
      throw Exception('Failed to link Apple account. Please try again.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        throw Exception('Apple is already linked to this account.');
      }
      if (e.code == 'credential-already-in-use') {
        throw Exception(
          'This Apple account is already linked to another SpareWo account.',
        );
      }
      throw Exception(_friendlyAppleAuthError(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to link Apple account. Please try again.');
    }
  }

  Future<UserModel> unlinkProvider(String providerId) async {
    final current = _auth.currentUser;
    if (current == null) {
      throw Exception('You must be signed in to manage linked accounts.');
    }

    final linkedProviders = current.providerData
        .map((info) => info.providerId)
        .toSet();
    if (!linkedProviders.contains(providerId)) {
      throw Exception('This sign-in method is not linked to your account.');
    }
    if (linkedProviders.length <= 1) {
      throw Exception(
        'You must keep at least one sign-in method linked to your account.',
      );
    }

    try {
      final user = await current.unlink(providerId);
      return await _getOrCreateUserData(
        user,
        name: user.displayName,
        markEmailVerified: true,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to unlink account: ${e.message}');
    }
  }

  Future<void> reauthenticateForDeletion({
    required String providerId,
    String? password,
  }) async {
    final current = _auth.currentUser;
    if (current == null) {
      throw Exception('No active user session found.');
    }

    try {
      if (providerId == 'password') {
        final email = current.email;
        if (email == null || email.isEmpty) {
          throw Exception('No email found for password reauthentication.');
        }
        if (password == null || password.isEmpty) {
          throw Exception('Password is required to continue.');
        }
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await current.reauthenticateWithCredential(credential);
        return;
      }

      if (providerId == 'google.com') {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw AuthCancelledException('Google sign in was cancelled');
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await current.reauthenticateWithCredential(credential);
        return;
      }

      if (providerId == 'apple.com') {
        final isAvailable = await SignInWithApple.isAvailable();
        if (!isAvailable) {
          throw Exception(
            'Sign in with Apple is not available on this device.',
          );
        }
        final rawNonce = _generateNonce();
        final hashedNonce = _sha256OfString(rawNonce);
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: const <AppleIDAuthorizationScopes>[],
          nonce: hashedNonce,
        );
        final credential = _buildAppleOAuthCredential(
          appleCredential: appleCredential,
          rawNonce: rawNonce,
        );
        await current.reauthenticateWithCredential(credential);
        return;
      }

      throw Exception('Unsupported reauthentication provider: $providerId');
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthCancelledException('Apple sign in was cancelled');
      }
      throw Exception('Reauthentication with Apple failed. Please try again.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Incorrect password. Please try again.');
      }
      throw Exception('Reauthentication failed: ${e.message}');
    }
  }

  Future<void> deleteAccount() async {
    final current = _auth.currentUser;
    if (current == null) {
      throw Exception('No signed-in account was found.');
    }

    try {
      final callable = _functions.httpsCallable('deleteClientAccount');
      final response = await callable.call(<String, dynamic>{});
      final data = response.data;
      if (data is! Map || data['ok'] != true) {
        throw Exception('Account deletion did not complete. Please try again.');
      }

      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      try {
        await _auth.signOut();
      } catch (_) {}
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'permission-denied') {
        throw ReauthenticationRequiredException(
          e.message ??
              'For security, please reauthenticate and try deleting your account again.',
        );
      }
      if (e.code == 'unauthenticated') {
        throw ReauthenticationRequiredException(
          'Your session expired. Please sign in again before deleting your account.',
        );
      }
      throw Exception(
        e.message ?? 'Failed to delete account. Please try again.',
      );
    } catch (e) {
      if (e is ReauthenticationRequiredException) rethrow;
      if (e is Exception) rethrow;
      throw Exception('Failed to delete account. Please try again.');
    }
  }

  Future<Map<String, dynamic>> mergeDuplicateAccountsForCurrentEmail({
    String? sourceUid,
    String? targetUid,
    bool deleteSourceAuthUser = true,
  }) async {
    final callable = _functions.httpsCallable('mergeClientAccounts');
    try {
      final response = await callable.call(<String, dynamic>{
        if (sourceUid != null && sourceUid.isNotEmpty) 'sourceUid': sourceUid,
        if (targetUid != null && targetUid.isNotEmpty) 'targetUid': targetUid,
        'deleteSourceAuthUser': deleteSourceAuthUser,
      });
      final raw = response.data;
      if (raw is! Map || raw['ok'] != true) {
        throw Exception(
          'We could not merge duplicate accounts right now. Please try again.',
        );
      }
      return Map<String, dynamic>.from(raw);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'permission-denied') {
        throw ReauthenticationRequiredException(
          e.message ??
              'For security, please reauthenticate and try account merge again.',
        );
      }
      if (e.code == 'not-found') {
        throw Exception(
          e.message ??
              'No duplicate account was found for this email. Nothing to merge.',
        );
      }
      throw Exception(
        e.message ?? 'Failed to merge duplicate accounts. Please try again.',
      );
    }
  }

  // --- Password Management ---

  Future<void> sendPasswordResetEmail({String? email}) async {
    final targetEmail = email ?? _auth.currentUser?.email;
    if (targetEmail == null) {
      throw Exception('No email address provided for password reset.');
    }

    try {
      await _auth.sendPasswordResetEmail(email: targetEmail);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this email address.');
      }
      throw Exception('Failed to send reset email: ${e.message}');
    } catch (_) {
      throw Exception('Failed to send reset email. Please try again.');
    }
  }

  // --- Helpers ---

  Future<UserModel> _getOrCreateUserData(
    User user, {
    String? name,
    bool markEmailVerified = false,
  }) async {
    final normalizedEmail = _normalizeEmail(user.email ?? '');
    final preferredName = _normalizeDisplayName(name);
    final displayName = _normalizeDisplayName(user.displayName);
    final refs = <DocumentReference<Map<String, dynamic>>>[
      _firestore.collection('users').doc(user.uid),
      _firestore.collection('clients').doc(user.uid),
    ];

    final existingSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
    var blockedReadCollections = 0;
    for (final ref in refs) {
      try {
        final snapshot = await ref.get();
        if (snapshot.exists) {
          existingSnapshots.add(snapshot);
        }
      } on FirebaseException catch (error) {
        if (error.code == 'permission-denied' ||
            error.code == 'unauthenticated') {
          blockedReadCollections += 1;
          AppLogger.warn(
            'AuthRepository._getOrCreateUserData',
            'Profile read blocked for collection; trying fallback',
            extra: {
              'uid': user.uid,
              'collection': ref.parent.path,
              'code': error.code,
            },
          );
          continue;
        }
        rethrow;
      }
    }

    if (blockedReadCollections == refs.length) {
      AppLogger.warn(
        'AuthRepository._getOrCreateUserData',
        'Profile reads blocked in all candidate collections; returning auth fallback',
        extra: {'uid': user.uid},
      );
      return _fallbackUserProfileFromAuth(user);
    }

    if (existingSnapshots.isNotEmpty) {
      final primary = existingSnapshots.first;
      final existingData = primary.data()!;
      final patch = <String, dynamic>{};
      if (markEmailVerified && existingData['isEmailVerified'] != true) {
        patch['isEmailVerified'] = true;
      }
      final existingName = _normalizeDisplayName(
        existingData['name']?.toString(),
      );
      if (_isPlaceholderUserName(existingName)) {
        final fallbackKnownName = await _lookupExistingNameByEmail(
          normalizedEmail: normalizedEmail,
          excludingUid: user.uid,
        );
        final replacementName = _resolvePreferredProfileName(
          socialProvidedName: preferredName,
          firebaseDisplayName: displayName ?? fallbackKnownName,
          normalizedEmail: normalizedEmail,
        );
        if (!_isPlaceholderUserName(replacementName)) {
          patch['name'] = replacementName;
        }
      }

      if (patch.isNotEmpty) {
        patch['updatedAt'] = FieldValue.serverTimestamp();
        for (final ref in refs) {
          try {
            await ref.set(patch, SetOptions(merge: true));
          } on FirebaseException catch (error) {
            if (error.code == 'permission-denied' ||
                error.code == 'unauthenticated') {
              continue;
            }
            rethrow;
          }
        }
      }

      return UserModel.fromJson({'id': user.uid, ...existingData});
    }

    if (normalizedEmail.isEmpty) {
      throw Exception('A valid email is required to complete account setup.');
    }
    final fallbackKnownName = await _lookupExistingNameByEmail(
      normalizedEmail: normalizedEmail,
      excludingUid: user.uid,
    );
    final finalName = _resolvePreferredProfileName(
      socialProvidedName: preferredName ?? fallbackKnownName,
      firebaseDisplayName: displayName,
      normalizedEmail: normalizedEmail,
    );

    final userData = {
      'email': normalizedEmail,
      'name': finalName,
      'isEmailVerified': markEmailVerified || user.emailVerified,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    var wroteAtLeastOneProfile = false;
    for (final ref in refs) {
      try {
        await ref.set(userData, SetOptions(merge: true));
        wroteAtLeastOneProfile = true;
      } on FirebaseException catch (error) {
        if (error.code == 'permission-denied' ||
            error.code == 'unauthenticated') {
          AppLogger.warn(
            'AuthRepository._getOrCreateUserData',
            'Profile write blocked for collection; trying fallback',
            extra: {
              'uid': user.uid,
              'collection': ref.parent.path,
              'code': error.code,
            },
          );
          continue;
        }
        rethrow;
      }
    }

    if (!wroteAtLeastOneProfile) {
      AppLogger.warn(
        'AuthRepository._getOrCreateUserData',
        'Profile writes blocked in all candidate collections; returning auth fallback',
        extra: {'uid': user.uid},
      );
      return _fallbackUserProfileFromAuth(user);
    }

    return UserModel(
      id: user.uid,
      email: normalizedEmail,
      name: finalName,
      createdAt: DateTime.now(),
    );
  }

  Future<UserModel?> _attemptLinkExistingSessionWithPendingCredential({
    required OAuthCredential? pendingCredential,
    required String? normalizedEmailHint,
  }) async {
    if (pendingCredential == null) return null;

    final current = _auth.currentUser;
    if (current == null) return null;

    final currentEmail = _normalizeEmail(current.email ?? '');
    if (normalizedEmailHint == null ||
        normalizedEmailHint.isEmpty ||
        currentEmail != normalizedEmailHint) {
      return null;
    }

    try {
      final linked = await current.linkWithCredential(pendingCredential);
      final user = linked.user ?? current;
      return await _getOrCreateUserData(
        user,
        name: user.displayName,
        markEmailVerified: true,
      );
    } on FirebaseAuthException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    AppLogger.info(
      'AuthRepository.signOut',
      'Signing out current user',
      extra: {'uid': _auth.currentUser?.uid},
    );
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> attemptSilentGoogleSessionRestore() async {
    if (_auth.currentUser != null) return;
    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      AppLogger.info(
        'AuthRepository.sessionRestore',
        'Silent Google session restore succeeded',
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.warn(
        'AuthRepository.sessionRestore',
        'Silent Google session restore failed',
        extra: {'code': e.code, 'message': e.message},
      );
    } catch (e) {
      AppLogger.warn(
        'AuthRepository.sessionRestore',
        'Silent Google session restore skipped',
        extra: {'error': e.toString()},
      );
    }
  }
}
