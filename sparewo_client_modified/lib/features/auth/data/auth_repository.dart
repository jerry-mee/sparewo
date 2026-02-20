// lib/features/auth/data/auth_repository.dart
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/features/auth/domain/user_model.dart';
import 'package:sparewo_client/features/shared/services/email_service.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final EmailService _emailService;
  final GoogleSignIn _googleSignIn;

  final Map<String, String> _verificationCodes = {};
  final Map<String, DateTime> _codeExpiry = {};
  final Map<String, Map<String, dynamic>> _pendingUsers = {};
  bool _lastRegistrationWasPartial = false;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    EmailService? emailService,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _emailService = emailService ?? EmailService(),
       _googleSignIn = googleSignIn ?? GoogleSignIn();

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

  Future<bool> isEmailRegistered(String email) async {
    final normalized = _normalizeEmail(email);
    if (normalized.isEmpty) return false;
    try {
      // ignore: deprecated_member_use
      final methods = await _auth.fetchSignInMethodsForEmail(normalized);
      return methods.isNotEmpty;
    } on FirebaseAuthException catch (e) {
      // Do not return false on transient/blocked checks; that causes false
      // "email available" messaging in UI.
      if (e.code == 'operation-not-allowed' || e.code == 'too-many-requests') {
        throw FirebaseException(
          plugin: 'firebase_auth',
          code: 'email-check-unavailable',
          message: 'Email lookup is temporarily unavailable.',
        );
      }
      rethrow;
    }
  }

  // --- Email & Password Auth ---

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = _normalizeEmail(email);
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user!;
      final profile = await _firestore.collection('users').doc(user.uid).get();
      final profileData = profile.data();
      final isEmailVerified = profileData?['isEmailVerified'] == true;
      if (!profile.exists || !isEmailVerified) {
        await _auth.signOut();
        throw Exception(
          '__INCOMPLETE_SETUP__Account setup incomplete. Verify your email to finish onboarding.',
        );
      }
      return UserModel.fromJson({'id': user.uid, ...profileData!});
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this email address');
      } else if (e.code == 'wrong-password') {
        throw Exception('Incorrect password');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address');
      } else if (e.code == 'user-disabled') {
        throw Exception('This account has been disabled');
      } else {
        throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
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
    try {
      _lastRegistrationWasPartial = false;
      if (!RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      ).hasMatch(normalizedEmail)) {
        throw Exception('Please enter a valid email address');
      }

      try {
        if (await isEmailRegistered(normalizedEmail)) {
          AppLogger.info(
            'AuthRepository',
            'Signup blocked: email already has account',
            extra: {'email': normalizedEmail},
          );
          await _resumeExistingRegistration(
            email: normalizedEmail,
            password: password,
            name: name,
          );
          return;
        }
      } on FirebaseException catch (e) {
        AppLogger.warn(
          'AuthRepository',
          'Email precheck unavailable',
          extra: {'error': e.code},
        );
      }

      // Create the auth user now so "partial onboarding" is persistent across
      // app restarts. Completion is still gated by code verification.
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
      if (name.trim().isNotEmpty) {
        await createdUser.updateDisplayName(name.trim());
      }
      await _getOrCreateUserData(
        createdUser,
        name: name.trim().isNotEmpty ? name.trim() : null,
        markEmailVerified: false,
      );

      final code = _generateVerificationCode();
      final emailSent = await _emailService.sendVerificationEmail(
        to: normalizedEmail,
        code: code,
        customerName: name,
      );

      if (!emailSent) {
        throw Exception(_verificationEmailFailureMessage());
      }

      _verificationCodes[normalizedEmail] = code;
      _codeExpiry[normalizedEmail] = DateTime.now().add(
        const Duration(minutes: 30),
      );
      _pendingUsers[normalizedEmail] = {
        'email': normalizedEmail,
        'password': password,
        'name': name,
        'existingAccount': true,
      };
      await _auth.signOut();
    } catch (e) {
      if (createdUser != null) {
        try {
          await _firestore.collection('users').doc(createdUser.uid).delete();
        } catch (_) {}
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      _verificationCodes.remove(normalizedEmail);
      _codeExpiry.remove(normalizedEmail);
      _pendingUsers.remove(normalizedEmail);
      rethrow;
    }
  }

  Future<void> resumeIncompleteOnboarding({
    required String email,
    required String password,
    String? name,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    UserCredential? credential;
    try {
      _lastRegistrationWasPartial = false;
      credential = await _auth.signInWithEmailAndPassword(
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
      final emailSent = await _emailService.sendVerificationEmail(
        to: normalizedEmail,
        code: code,
        customerName: displayName,
      );

      await _auth.signOut();

      if (!emailSent) {
        throw Exception(_verificationEmailFailureMessage());
      }

      _verificationCodes[normalizedEmail] = code;
      _codeExpiry[normalizedEmail] = DateTime.now().add(
        const Duration(minutes: 30),
      );
      _pendingUsers[normalizedEmail] = {
        'email': normalizedEmail,
        'password': password,
        'name': displayName,
        'existingAccount': true,
      };
      _lastRegistrationWasPartial = true;
    } on FirebaseAuthException catch (e) {
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
    final storedCode = _verificationCodes[normalizedEmail];
    if (storedCode == null) {
      throw Exception('No verification code found. Please request a new one.');
    }

    final expiry = _codeExpiry[normalizedEmail];
    if (expiry == null || DateTime.now().isAfter(expiry)) {
      _verificationCodes.remove(normalizedEmail);
      _codeExpiry.remove(normalizedEmail);
      throw Exception(
        'Verification code has expired. Please request a new one.',
      );
    }

    if (storedCode != code) {
      throw Exception('Invalid verification code. Please check and try again.');
    }

    final userData = _pendingUsers[normalizedEmail];
    if (userData == null) {
      throw Exception('Registration data not found. Please start over.');
    }

    try {
      final isExistingAccount = userData['existingAccount'] == true;
      UserModel user;
      if (isExistingAccount) {
        final credential = await _auth.signInWithEmailAndPassword(
          email: userData['email'],
          password: userData['password'],
        );
        final fbUser = credential.user!;
        if ((fbUser.displayName ?? '').trim().isEmpty) {
          await fbUser.updateDisplayName(userData['name']);
        }
        user = await _getOrCreateUserData(
          fbUser,
          name: userData['name'],
          markEmailVerified: true,
        );
      } else {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: userData['email'],
          password: userData['password'],
        );

        await credential.user!.updateDisplayName(userData['name']);

        user = await _getOrCreateUserData(
          credential.user!,
          name: userData['name'],
          markEmailVerified: true,
        );
      }

      _verificationCodes.remove(normalizedEmail);
      _codeExpiry.remove(normalizedEmail);
      _pendingUsers.remove(normalizedEmail);

      await _emailService.sendWelcomeEmail(
        to: normalizedEmail,
        customerName: userData['name'],
      );

      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception(
          'This email is already registered. Please login instead.',
        );
      } else if (e.code == 'weak-password') {
        throw Exception(
          'Password is too weak. Please use a stronger password.',
        );
      } else {
        throw Exception('Registration failed: ${e.message}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to create account. Please try again.');
    }
  }

  Future<void> resendVerificationCode({required String email}) async {
    final normalizedEmail = _normalizeEmail(email);
    final userData = _pendingUsers[normalizedEmail];
    if (userData == null) {
      throw Exception(
        'No pending registration found. Please start the signup process again.',
      );
    }

    final code = _generateVerificationCode();

    _verificationCodes[normalizedEmail] = code;
    _codeExpiry[normalizedEmail] = DateTime.now().add(
      const Duration(minutes: 30),
    );

    final emailSent = await _emailService.sendVerificationEmail(
      to: normalizedEmail,
      code: code,
      customerName: userData['name'],
    );

    if (!emailSent) {
      throw Exception('Failed to send verification email. Please try again.');
    }
  }

  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  String _verificationEmailFailureMessage() {
    switch (_emailService.lastFailureReason) {
      case 'rate_limited':
        return 'Too many verification attempts right now. Please wait a moment and try again.';
      case 'permission_denied':
        return 'Verification email is temporarily unavailable. Please try again in a few minutes.';
      case 'network_error':
        return 'Network issue while sending verification email. Check your connection and try again.';
      default:
        return 'We could not send the verification email right now. Please try again shortly.';
    }
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

      // Ensure Firestore profile exists
      return _getOrCreateUserData(fbUser, name: fbUser.displayName);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
          'This email is already used with a different sign-in method. '
          'Please sign in with email and password, then link Google in Settings.',
        );
      } else {
        throw Exception('Google sign in failed: ${e.message}');
      }
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
      } else if (e.code == 'credential-already-in-use') {
        throw Exception(
          'This Google account is already linked to another SpareWo account.',
        );
      } else {
        throw Exception('Failed to link Google account: ${e.message}');
      }
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
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
