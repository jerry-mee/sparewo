// lib/providers/service_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../services/stats_service.dart';

// --------------------------
// Firebase Instance Providers
// --------------------------

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// --------------------------
// Service Providers
// --------------------------

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final storage = ref.watch(firebaseStorageProvider);
  return FirebaseService(
    auth: auth,
    firestore: firestore,
    storage: storage,
  );
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ApiService(storageService: storageService);
});

final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService();
});

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final statsServiceProvider = Provider<StatsService>((ref) {
  return StatsService();
});

// --------------------------
// Current User ID Provider
// --------------------------

final currentUserIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.currentUser?.uid;
});

// --------------------------
// Auth State Changes Stream Provider
// --------------------------

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});
