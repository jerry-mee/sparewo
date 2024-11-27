import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../exceptions/auth_exceptions.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class AuthResult {
  final User user;
  final String token;
  final bool isNewUser;

  const AuthResult({
    required this.user,
    required this.token,
    required this.isNewUser,
  });
}

class FirebaseService {
  firebase_auth.FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  bool _initialized = false;
  bool _disposed = false;

  FirebaseService({required String googleClientId}) {
    _googleSignIn = GoogleSignIn(
      clientId: googleClientId,
      scopes: ['email', 'profile'],
    );
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _auth = firebase_auth.FirebaseAuth.instance;
      _initAuthStateListener();
      _initialized = true;
    }
  }

  Stream<User?> get authStateChanges => _authStateController.stream;

  void _initAuthStateListener() {
    _auth!.authStateChanges().listen(
      (firebase_auth.User? firebaseUser) {
        if (_disposed) return;

        if (firebaseUser != null) {
          final user = _mapFirebaseUserToUser(firebaseUser);
          _authStateController.add(user);
        } else {
          _authStateController.add(null);
        }
      },
      onError: (error) {
        if (_disposed) return;
        debugPrint('Firebase auth state error: $error');
        _authStateController.addError(error);
      },
    );
  }

  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();

    try {
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw const CustomAuthException(
          message: 'Sign in failed - no user returned',
          code: 'no-user-credential',
        );
      }

      final token = await credential.user!.getIdToken();
      if (token == null) {
        throw const CustomAuthException(
          message: 'Failed to get authentication token',
          code: 'no-token',
        );
      }

      final user = _mapFirebaseUserToUser(credential.user!);

      return AuthResult(
        user: user,
        token: token,
        isNewUser: credential.additionalUserInfo?.isNewUser ?? false,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw CustomAuthException(
        message: 'Sign in failed: ${e.toString()}',
        code: 'unknown-error',
      );
    }
  }

  Future<AuthResult> createUserWithEmailPassword({
    required String email,
    required String password,
    String? name,
  }) async {
    await _ensureInitialized();

    try {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw const CustomAuthException(
          message: 'Account creation failed - no user returned',
          code: 'no-user-credential',
        );
      }

      if (name != null && name.isNotEmpty) {
        await credential.user!.updateDisplayName(name.trim());
        await credential.user!.reload();
      }

      final updatedUser = _auth!.currentUser;
      if (updatedUser == null) {
        throw const CustomAuthException(
          message: 'Failed to get updated user profile',
          code: 'no-user-profile',
        );
      }

      final token = await updatedUser.getIdToken();
      if (token == null) {
        throw const CustomAuthException(
          message: 'Failed to get authentication token',
          code: 'no-token',
        );
      }

      final user = _mapFirebaseUserToUser(updatedUser);

      return AuthResult(
        user: user,
        token: token,
        isNewUser: true,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw CustomAuthException(
        message: 'Account creation failed: ${e.toString()}',
        code: 'unknown-error',
      );
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    await _ensureInitialized();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

      if (googleUser == null) {
        throw const CustomAuthException(
          message: 'Google sign in was cancelled',
          code: 'google-signin-cancelled',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw const CustomAuthException(
          message: 'Failed to get Google authentication tokens',
          code: 'no-google-tokens',
        );
      }

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth!.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw const CustomAuthException(
          message: 'Google sign in failed - no user returned',
          code: 'no-user-credential',
        );
      }

      final token = await userCredential.user!.getIdToken();
      if (token == null) {
        throw const CustomAuthException(
          message: 'Failed to get authentication token',
          code: 'no-token',
        );
      }

      final user = _mapFirebaseUserToUser(userCredential.user!);

      return AuthResult(
        user: user,
        token: token,
        isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw CustomAuthException(
        message: 'Google sign in failed: ${e.toString()}',
        code: 'unknown-error',
      );
    }
  }

  Future<bool> isGoogleAccount(String email) async {
    await _ensureInitialized();

    try {
      final methods = await _auth!.fetchSignInMethodsForEmail(email.trim());
      return methods.contains('google.com');
    } catch (e) {
      debugPrint('Google account check failed: $e');
      return false;
    }
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    await _ensureInitialized();

    try {
      if (_auth!.currentUser == null) {
        debugPrint('No current user found when getting ID token');
        return null;
      }
      return await _auth!.currentUser!.getIdToken(forceRefresh);
    } catch (e) {
      debugPrint('Token retrieval failed: $e');
      return null;
    }
  }

  Future<firebase_auth.User?> getCurrentUser() async {
    await _ensureInitialized();
    return _auth!.currentUser;
  }

  Future<void> signOut() async {
    if (_disposed) {
      throw const CustomAuthException(
        message: 'Cannot sign out - service is disposed',
        code: 'service-disposed',
      );
    }

    await _ensureInitialized();

    try {
      final isSignedInWithGoogle = await _googleSignIn!.isSignedIn();
      if (isSignedInWithGoogle) {
        if (!kIsWeb) {
          try {
            await _googleSignIn!.disconnect();
          } catch (e) {
            debugPrint('Google disconnect failed: $e');
          }
        }
        await _googleSignIn!.signOut();
      }
      await _auth!.signOut();
    } catch (e) {
      throw CustomAuthException(
        message: 'Sign out failed: ${e.toString()}',
        code: 'signout-failed',
      );
    }
  }

  CustomAuthException _handleFirebaseAuthError(
      firebase_auth.FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No account exists with this email';
        break;
      case 'wrong-password':
        message = 'Incorrect password';
        break;
      case 'invalid-email':
        message = 'Invalid email address';
        break;
      case 'user-disabled':
        message = 'This account has been disabled';
        break;
      case 'email-already-in-use':
        message = 'This email is already registered';
        break;
      case 'operation-not-allowed':
        message = 'This operation is not allowed';
        break;
      case 'weak-password':
        message = 'Please use a stronger password';
        break;
      case 'network-request-failed':
        message =
            'Network connection failed. Please check your internet connection';
        break;
      case 'too-many-requests':
        message = 'Too many failed attempts. Please try again later';
        break;
      case 'requires-recent-login':
        message = 'Please sign in again to complete this operation';
        break;
      case 'invalid-credential':
        message = 'The provided credential is malformed or expired';
        break;
      case 'account-exists-with-different-credential':
        message =
            'An account already exists with the same email but different sign-in credentials';
        break;
      case 'popup-blocked':
        message = 'Sign in popup was blocked by the browser';
        break;
      case 'popup-closed-by-user':
        message = 'Sign in popup was closed before completing the sign in';
        break;
      case 'unauthorized-domain':
        message =
            'The domain of this application is not authorized for OAuth operations';
        break;
      default:
        message = e.message ?? 'Authentication failed';
    }
    return CustomAuthException(message: message, code: e.code);
  }

  User _mapFirebaseUserToUser(firebase_auth.User firebaseUser) {
    final now = DateTime.now();
    return User(
      id: int.parse(firebaseUser.uid.hashCode.abs().toString().substring(0, 8)),
      name: firebaseUser.displayName?.trim() ?? '',
      email: firebaseUser.email?.trim() ?? '',
      phone: firebaseUser.phoneNumber?.trim(),
      profileImg: firebaseUser.photoURL,
      status: true,
      createdAt: firebaseUser.metadata.creationTime ?? now,
      updatedAt: firebaseUser.metadata.lastSignInTime ?? now,
    );
  }

  void dispose() {
    _disposed = true;
    _authStateController.close();
  }
}
