import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../exceptions/auth_exceptions.dart';
import '../exceptions/firebase_exceptions.dart';
import '../models/vendor.dart';
import '../constants/enums.dart';

class AuthResult {
  final Vendor vendor;
  final String token;
  final bool isNewUser;

  AuthResult({
    required this.vendor,
    required this.token,
    required this.isNewUser,
  });
}

class FirebaseService {
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseService({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  Future<AuthResult?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final token = await user.getIdToken();
    final vendor = await getVendorProfile(user.uid);

    if (vendor == null) return null;

    return AuthResult(
      vendor: vendor,
      token: token ?? '',
      isNewUser: false,
    );
  }

  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw const AuthException(
          message: 'Sign in failed - no user returned',
          code: 'sign-in-failed',
        );
      }

      final token = await credential.user!.getIdToken();
      final vendor = await getVendorProfile(credential.user!.uid);

      if (vendor == null) {
        throw const AuthException(
          message: 'Vendor profile not found',
          code: 'profile-not-found',
        );
      }

      return AuthResult(
        vendor: vendor,
        token: token ?? '',
        isNewUser: false,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  Future<AuthResult> createUserWithEmailPassword({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw const AuthException(
          message: 'Account creation failed - no user returned',
          code: 'creation-failed',
        );
      }

      final token = await credential.user!.getIdToken();

      // Create vendor profile
      final vendor = Vendor(
        id: credential.user!.uid,
        email: email.trim(),
        name: userData['name'] as String,
        phone: userData['phone'] as String,
        businessName: userData['businessName'] as String,
        businessAddress: userData['businessAddress'] as String,
        categories: List<String>.from(userData['categories'] as List),
        status: VendorStatus.pending,
        isVerified: false,
        rating: 0.0,
        completedOrders: 0,
        totalProducts: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _createVendorProfile(vendor);

      return AuthResult(
        vendor: vendor,
        token: token ?? '',
        isNewUser: true,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException(
        message: 'Failed to sign out: ${e.toString()}',
        code: 'sign-out-failed',
      );
    }
  }

  Future<void> _createVendorProfile(Vendor vendor) async {
    try {
      await _firestore
          .collection('vendors')
          .doc(vendor.id)
          .set(vendor.toFirestore());
    } catch (e) {
      throw FirestoreException(
          'Failed to create vendor profile: ${e.toString()}');
    }
  }

  Future<Vendor?> getVendorProfile(String vendorId) async {
    try {
      final doc = await _firestore.collection('vendors').doc(vendorId).get();
      if (!doc.exists) return null;
      return Vendor.fromFirestore(doc);
    } catch (e) {
      throw FirestoreException('Failed to get vendor profile: ${e.toString()}');
    }
  }

  Future<void> updateVendorProfile(Vendor vendor) async {
    try {
      await _firestore
          .collection('vendors')
          .doc(vendor.id)
          .update(vendor.toFirestore());
    } catch (e) {
      throw FirestoreException(
          'Failed to update vendor profile: ${e.toString()}');
    }
  }

  Future<String> uploadProfileImage(String path) async {
    try {
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('vendor_profiles/$fileName');

      final uploadTask = await ref.putFile(File(path));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw StorageException('Failed to upload profile image: ${e.toString()}');
    }
  }

  AuthException _handleFirebaseAuthError(
      firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthException(
          message: 'No account exists with this email',
          code: 'user-not-found',
        );
      case 'wrong-password':
        return const AuthException(
          message: 'Incorrect password',
          code: 'wrong-password',
        );
      case 'invalid-email':
        return const AuthException(
          message: 'Invalid email address',
          code: 'invalid-email',
        );
      case 'user-disabled':
        return const AuthException(
          message: 'This account has been disabled',
          code: 'user-disabled',
        );
      case 'email-already-in-use':
        return const AuthException(
          message: 'This email is already registered',
          code: 'email-already-in-use',
        );
      case 'operation-not-allowed':
        return const AuthException(
          message: 'Email/password accounts are not enabled',
          code: 'operation-not-allowed',
        );
      case 'weak-password':
        return const AuthException(
          message: 'Please use a stronger password',
          code: 'weak-password',
        );
      default:
        return AuthException(
          message: e.message ?? 'An authentication error occurred',
          code: e.code,
        );
    }
  }
}
