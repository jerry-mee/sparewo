import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';

// Create the missing exception file
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException({required this.message, this.code});

  @override
  String toString() {
    return 'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

class UserRepository {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;

  UserRepository({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  // Create user in Firestore after Firebase Auth signup
  Future<User> createUser({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      // Create Firebase Auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException(
          message: 'Failed to create Firebase Auth account.',
          code: 'firebase-auth-creation-failed',
        );
      }

      // Generate new user ID (Consider using Firestore's auto-generated IDs)
      // Note: The original code relies on a static method `User.getNextId`.
      // If you have that implementation, keep it. Otherwise, consider
      // using Firestore's auto-generated IDs for simplicity and scalability.
      // For demonstration, let's assume User model can generate its own ID.
      final user = User(
        id: User
            .generateId(), // Assuming User model has a static generateId method
        name: name,
        email: email,
        phone: phone,
        status: true,
        createdAt: DateTime.now().toUtc(), // Store timestamps in UTC
        updatedAt: DateTime.now().toUtc(),
        firebaseUid: firebaseUser.uid,
      );

      // Save to Firestore using the Firebase Auth UID as the document ID
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toFirestore());

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(
          message: e.message ?? 'Firebase Auth error', code: e.code);
    } catch (e) {
      throw AuthException(message: 'Failed to create user: ${e.toString()}');
    }
  }

  // Fetch user profile
  Future<User?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return User.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw AuthException(
        message: 'Failed to get user profile: ${e.message ?? e.toString()}',
        code: e.code,
      );
    } catch (e) {
      throw AuthException(
          message: 'Failed to get user profile: ${e.toString()}');
    }
  }

  // Update user profile
  Future<User> updateUser(User user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.firebaseUid);

      final updatedUser = user.copyWith(
        updatedAt: DateTime.now().toUtc(), // Update timestamp in UTC
      );

      await userRef.update(updatedUser.toFirestore());
      return updatedUser;
    } on FirebaseException catch (e) {
      throw AuthException(
        message: 'Failed to update profile: ${e.message ?? e.toString()}',
        code: e.code,
      );
    } catch (e) {
      throw AuthException(message: 'Failed to update profile: ${e.toString()}');
    }
  }

  // Migration helper
  Future<void> migrateUserData(Map<String, dynamic> legacyData) async {
    try {
      final email = legacyData['email'] as String?;
      if (email == null || email.isEmpty) {
        throw const AuthException(
            message: 'Email is missing in legacy data.', code: 'missing-email');
      }

      // Check if a user with this email already exists in Firebase Auth
      firebase_auth.UserCredential credential;
      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password:
              _generateRandomPassword(), // Generate a random temporary password
        );
      } on firebase_auth.FirebaseAuthException catch (e) {
        // If user already exists, handle accordingly (e.g., link accounts)
        if (e.code == 'email-already-in-use') {
          // Consider your migration strategy here. For example, you might:
          // 1. Fetch the existing user's UID.
          // 2. Merge the legacy data with the existing user's data.
          // 3. Inform the user to reset their password.
          print('User with email "$email" already exists. Handling...');
          final existingUsers = await _auth.fetchSignInMethodsForEmail(email);
          if (existingUsers.isNotEmpty) {
            // Assuming only one account exists with this email
            final users = _auth.currentUser;
            if (users != null) {
              // You might want to update the existing user's data here
              final existingUserDoc = await _firestore
                  .collection('users')
                  .where('email', isEqualTo: email)
                  .get();
              if (existingUserDoc.docs.isNotEmpty) {
                final existingUserRef = _firestore
                    .collection('users')
                    .doc(existingUserDoc.docs.first.id);
                final migratedUser = await User.migrateFromLegacy(
                  legacyData: legacyData,
                  firestore: _firestore,
                  existingFirebaseUid: users.uid,
                  newFirebaseUid: '', // Pass existing UID
                );
                await existingUserRef.set(
                    migratedUser.toFirestore(), SetOptions(merge: true));
                return;
              }
            }
          }
          throw AuthException(
              message: 'User with this email already exists.',
              code: 'email-already-exists');
        }
        throw AuthException(
            message: e.message ?? 'Firebase Auth error', code: e.code);
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException(
            message: 'Failed to create Firebase Auth account during migration.',
            code: 'migration-auth-failed');
      }

      // Create migrated user
      final user = await User.migrateFromLegacy(
        legacyData: legacyData,
        firestore: _firestore,
        newFirebaseUid: firebaseUser.uid,
        existingFirebaseUid: '', // Pass the newly created UID
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toFirestore());

      // Send password reset email instead of email verification
      try {
        await _auth.sendPasswordResetEmail(email: email);
      } catch (e) {
        print('Error sending password reset email: ${e.toString()}');
        // Consider logging this error and informing the user through other means.
      }
    } on AuthException catch (e) {
      throw Exception('Migration failed: ${e.message}');
    } catch (e) {
      throw Exception('Migration failed: ${e.toString()}');
    }
  }

  // Helper function to generate a random password
  String _generateRandomPassword({int length = 20}) {
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final rnd = DateTime.now().microsecondsSinceEpoch;
    final sb = StringBuffer();
    for (var i = 0; i < length; i++) {
      sb.write(chars[(rnd + i) % chars.length]);
    }
    return sb.toString();
  }
}
