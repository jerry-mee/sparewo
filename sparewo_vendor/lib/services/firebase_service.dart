// lib/services/firebase_service.dart
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../models/auth_result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../exceptions/auth_exceptions.dart';
import '../exceptions/firebase_exceptions.dart';
import '../models/vendor.dart';
import '../constants/enums.dart';
import '../models/user_roles.dart';

class FirebaseService {
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseService(this._auth, this._firestore, this._storage);

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  Future<AuthResult?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final token = await user.getIdToken(true); // Force refresh token
      final vendor = await getVendorProfile(user.uid);
      final userRole = await _getUserRole(user.uid);

      if (vendor == null) return null;

      return AuthResult(
        vendor: vendor,
        token: token ?? '',
        isNewUser: false,
        userRole: userRole,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current user: $e');
      }
      throw AuthException(
        message: 'Failed to get current user: ${e.toString()}',
        code: 'get-user-failed',
      );
    }
  }

  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    firebase_auth.UserCredential? credential;
    firebase_auth.User? user;

    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = credential.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw handleFirebaseAuthError(e);
    } catch (e) {
      // Handle the PigeonUserDetails error specifically
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains("type 'List<Object?>' is not a subtype")) {
        // Try to get the current user directly after a small delay
        await Future.delayed(const Duration(milliseconds: 300));
        user = _auth.currentUser;
        if (user == null) {
          throw const AuthException(
            message: 'Authentication failed. Please try again.',
            code: 'auth-failed',
          );
        }
      } else {
        throw AuthException(message: e.toString());
      }
    }

    if (user == null) {
      throw const AuthException(
        message: 'Sign in failed - no user returned',
        code: 'sign-in-failed',
      );
    }

    try {
      final token = await user.getIdToken();
      final vendor = await getVendorProfile(user.uid);
      final userRole = await _getUserRole(user.uid);

      return AuthResult(
        vendor: vendor,
        token: token ?? '',
        isNewUser: false,
        userRole: userRole,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
          message: 'Failed to complete sign in: ${e.toString()}');
    }
  }

  Future<AuthResult> createUserWithEmailPassword({
    required String email,
    required String password,
    required Map<String, dynamic> vendorData,
  }) async {
    firebase_auth.UserCredential? credential;
    firebase_auth.User? user;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = credential.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw handleFirebaseAuthError(e);
    } catch (e) {
      // Handle the PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains("type 'List<Object?>' is not a subtype")) {
        await Future.delayed(const Duration(milliseconds: 300));
        user = _auth.currentUser;
        if (user == null) {
          throw AuthException(
              message: 'Account creation failed. Please try again.');
        }
      } else {
        throw AuthException(message: e.toString());
      }
    }

    if (user == null) {
      throw const AuthException(
        message: 'Account creation failed - no user returned',
        code: 'creation-failed',
      );
    }

    try {
      final token = await user.getIdToken();
      final now = DateTime.now();

      final vendor = Vendor(
        id: user.uid,
        email: email.trim(),
        name: vendorData['name'] as String,
        phone: vendorData['phone'] as String,
        businessName: vendorData['businessName'] as String,
        businessAddress: vendorData['businessAddress'] as String,
        categories: List<String>.from(vendorData['categories'] as List),
        status: VendorStatus.pending,
        isVerified: false,
        rating: 0.0,
        completedOrders: 0,
        totalProducts: 0,
        createdAt: now,
        updatedAt: now,
      );

      await _createVendorProfile(vendor);

      final defaultRole = UserRoles(
        uid: user.uid,
        isAdmin: false,
        role: 'vendor',
        createdAt: now,
        updatedAt: now,
      );

      await _setUserRole(defaultRole);

      return AuthResult(
        vendor: vendor,
        token: token ?? '',
        isNewUser: true,
        userRole: defaultRole,
      );
    } catch (e) {
      // If profile creation fails, delete the auth user
      try {
        await user.delete();
      } catch (_) {}

      if (e is AuthException || e is FirestoreException) {
        rethrow;
      }
      throw AuthException(
        message: 'Failed to create vendor profile: ${e.toString()}',
        code: 'profile-creation-failed',
      );
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

  Future<void> _setUserRole(UserRoles role) async {
    try {
      await _firestore.collection('userRoles').doc(role.uid).set(role.toJson());
    } catch (e) {
      throw FirestoreException('Failed to set user role: ${e.toString()}');
    }
  }

  Future<UserRoles> _getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('userRoles').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        return UserRoles.fromJson(doc.data()!);
      }

      // Return a default 'vendor' role if no role document exists
      return UserRoles(
        uid: uid,
        role: 'vendor',
        isAdmin: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      // Return a default role on error as well
      return UserRoles(
        uid: uid,
        role: 'vendor',
        isAdmin: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
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

  Future<List<String>> getVehicleBrands() async {
    try {
      final snapshot =
          await _firestore.collection('car_brand').orderBy('part_name').get();

      return snapshot.docs
          .map((doc) => doc.data()['part_name'] as String)
          .toList();
    } catch (e) {
      throw FirestoreException('Failed to get vehicle brands: ${e.toString()}');
    }
  }

  Future<List<String>> getVehicleModels(String brandName) async {
    try {
      // Find the brand by name
      final brandQuery = await _firestore
          .collection('car_brand')
          .where('part_name', isEqualTo: brandName)
          .limit(1)
          .get();

      if (brandQuery.docs.isEmpty) {
        // Try case-insensitive search
        final allBrands = await _firestore.collection('car_brand').get();
        final matchingBrand = allBrands.docs.firstWhere(
          (doc) =>
              (doc.data()['part_name'] as String?)?.toLowerCase() ==
              brandName.toLowerCase(),
          orElse: () => throw FirestoreException('Brand not found'),
        );

        // Get the numeric ID
        final numericId = matchingBrand.data()['id'];

        // Query models using the numeric ID
        final modelsSnapshot = await _firestore
            .collection('car_models')
            .where('car_makeid', isEqualTo: numericId)
            .get();

        return modelsSnapshot.docs
            .map((doc) => doc.data()['model'] as String)
            .toList();
      }

      // Get the numeric ID from brand
      final brandData = brandQuery.docs.first.data();
      final numericId = brandData['id'];

      // Query models using the numeric ID
      final modelsSnapshot = await _firestore
          .collection('car_models')
          .where('car_makeid', isEqualTo: numericId)
          .get();

      return modelsSnapshot.docs
          .map((doc) => doc.data()['model'] as String)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get models for brand $brandName: ${e.toString()}');
      }
      return [];
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

  static AuthException handleFirebaseAuthError(
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
      case 'invalid-credential':
        return const AuthException(
          message: 'Invalid email or password',
          code: 'invalid-credential',
        );
      case 'network-request-failed':
        return const AuthException(
          message: 'Network error. Please check your internet connection.',
          code: 'network-error',
        );
      default:
        return AuthException(
          message: e.message ?? 'An authentication error occurred',
          code: e.code,
        );
    }
  }
}
