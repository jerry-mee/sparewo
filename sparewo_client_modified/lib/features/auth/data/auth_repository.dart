// lib/features/auth/data/auth_repository.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/features/auth/data/verification_session_store.dart';
import 'package:sparewo_client/features/auth/domain/user_model.dart';
import 'package:sparewo_client/features/shared/services/email_service.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    EmailService? emailService,
    GoogleSignIn? googleSignIn,
    VerificationSessionStore? verificationSessionStore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _emailService = emailService ?? EmailService(),
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _verificationStore =
           verificationSessionStore ?? VerificationSessionStore();

  static const _verificationExpiry = Duration(minutes: 30);
  static const _maxVerificationAttempts = 5;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final EmailService _emailService;
  final GoogleSignIn _googleSignIn;
  final VerificationSessionStore _verificationStore;

  bool _lastRegistrationWasPartial = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Stream<UserModel?> get userProfileChanges {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<UserModel?>.value(null);
      }
      return _firestore.collection('users').doc(user.uid).snapshots().map((
        snapshot,
      ) {
        final data = snapshot.data();
        if (data == null) return null;
        return UserModel.fromJson({'id': user.uid, ...data});
      });
    });
  }

  User? get currentUser => _auth.currentUser;

  String _normalizeEmail(String email) => email.trim().toLowerCase();

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
      final profile = await _firestore.collection('users').doc(user.uid).get();
      final profileData = profile.data();
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
      throw Exception('No verification code found. Please request a new one.');
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
        'No pending registration found. Please start the signup process again.',
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

  // --- Google Sign In & Linking ---

  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final fbUser = userCred.user;
      if (fbUser == null) {
        throw Exception('Failed to sign in with Google');
      }

      return _getOrCreateUserData(fbUser, name: fbUser.displayName);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
          'This email is already used with a different sign-in method. '
          'Please sign in with email and password, then link Google in Settings.',
        );
      }
      throw Exception('Google sign in failed: ${e.message}');
    } catch (e) {
      AppLogger.error('AUTH', 'Google sign in catch-all error', error: e);
      throw Exception('Google sign in error: ${e.toString()}');
    }
  }

  Future<UserModel> linkWithGoogle() async {
    final current = _auth.currentUser;
    if (current == null) {
      throw Exception('You must be signed in to link a Google account');
    }

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await current.linkWithCredential(credential);
      final fbUser = userCred.user ?? current;

      return _getOrCreateUserData(fbUser, name: fbUser.displayName);
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
    final doc = _firestore.collection('users').doc(user.uid);
    final snapshot = await doc.get();

    if (snapshot.exists) {
      if (markEmailVerified && snapshot.data()?['isEmailVerified'] != true) {
        await doc.set({
          'isEmailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        final refreshed = await doc.get();
        return UserModel.fromJson({'id': user.uid, ...refreshed.data()!});
      }
      return UserModel.fromJson({'id': user.uid, ...snapshot.data()!});
    }

    final userData = {
      'email': user.email!.toLowerCase(),
      'name': name ?? user.displayName ?? 'User',
      'isEmailVerified': markEmailVerified || user.emailVerified,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await doc.set(userData);

    return UserModel(
      id: user.uid,
      email: user.email!,
      name: userData['name'] as String,
      createdAt: DateTime.now(),
    );
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
}
