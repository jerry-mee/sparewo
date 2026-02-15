// lib/providers/firebase_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/firebase_service.dart';

/// Provides the instance of [FirebaseAuth].
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provides the instance of [FirebaseFirestore].
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provides the instance of [FirebaseStorage].
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

/// Provides the instance of our custom [FirebaseService].
///
/// This provider watches the other Firebase providers and injects their
/// instances into the [FirebaseService] constructor. This is the
/// correct way to handle dependencies with Riverpod.
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  final storage = ref.watch(firebaseStorageProvider);
  return FirebaseService(auth, firestore, storage);
});
