// lib/features/auth/data/auth_repository.dart
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromJson({'id': user.uid, ...doc.data()!});
  }

  // --- Email & Password Auth ---

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return _getOrCreateUserData(credential.user!);
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
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> startRegistration({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Please enter a valid email address');
      }

      final code = _generateVerificationCode();

      _verificationCodes[email] = code;
      _codeExpiry[email] = DateTime.now().add(const Duration(minutes: 30));

      _pendingUsers[email] = {
        'email': email,
        'password': password,
        'name': name,
      };

      final emailSent = await _emailService.sendVerificationEmail(
        to: email,
        code: code,
        customerName: name,
      );

      if (!emailSent) {
        throw Exception(
          'Failed to send verification email. Please check your email address and try again.',
        );
      }
    } catch (e) {
      _verificationCodes.remove(email);
      _codeExpiry.remove(email);
      _pendingUsers.remove(email);
      rethrow;
    }
  }

  Future<UserModel> verifyEmailAndCompleteRegistration({
    required String email,
    required String code,
  }) async {
    final storedCode = _verificationCodes[email];
    if (storedCode == null) {
      throw Exception('No verification code found. Please request a new one.');
    }

    final expiry = _codeExpiry[email];
    if (expiry == null || DateTime.now().isAfter(expiry)) {
      _verificationCodes.remove(email);
      _codeExpiry.remove(email);
      throw Exception(
        'Verification code has expired. Please request a new one.',
      );
    }

    if (storedCode != code) {
      throw Exception('Invalid verification code. Please check and try again.');
    }

    final userData = _pendingUsers[email];
    if (userData == null) {
      throw Exception('Registration data not found. Please start over.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: userData['email'],
        password: userData['password'],
      );

      await credential.user!.updateDisplayName(userData['name']);

      final user = await _getOrCreateUserData(
        credential.user!,
        name: userData['name'],
      );

      _verificationCodes.remove(email);
      _codeExpiry.remove(email);
      _pendingUsers.remove(email);

      await _emailService.sendWelcomeEmail(
        to: email,
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
      throw Exception('Failed to create account. Please try again.');
    }
  }

  Future<void> resendVerificationCode({required String email}) async {
    final userData = _pendingUsers[email];
    if (userData == null) {
      throw Exception(
        'No pending registration found. Please start the signup process again.',
      );
    }

    final code = _generateVerificationCode();

    _verificationCodes[email] = code;
    _codeExpiry[email] = DateTime.now().add(const Duration(minutes: 30));

    final emailSent = await _emailService.sendVerificationEmail(
      to: email,
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
      throw Exception('Google sign in failed. Please try again.');
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

  Future<void> sendPasswordResetEmail() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No signed-in user with an email address found.');
    }

    try {
      await _auth.sendPasswordResetEmail(email: user.email!);
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to send reset email: ${e.message}');
    } catch (_) {
      throw Exception('Failed to send reset email. Please try again.');
    }
  }

  // --- Helpers ---

  Future<UserModel> _getOrCreateUserData(User user, {String? name}) async {
    final doc = _firestore.collection('users').doc(user.uid);
    final snapshot = await doc.get();

    if (snapshot.exists) {
      return UserModel.fromJson({'id': user.uid, ...snapshot.data()!});
    }

    final userData = {
      'email': user.email!,
      'name': name ?? user.displayName ?? 'User',
      'createdAt': FieldValue.serverTimestamp(),
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
