// lib/providers/providers.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/vendor.dart';
import '../models/auth_result.dart';
import '../models/settings.dart' as app_settings;
import '../constants/enums.dart';
import '../models/notification.dart';
import '../models/user_roles.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../services/verification_service.dart';
import '../services/settings_service.dart';
import '../services/vendor_product_service.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';
import '../services/stats_service.dart';
import '../services/catalog_product_service.dart';
import '../services/camera_service.dart';
import '../services/email_service.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';
import 'vendor_product_provider.dart';
import 'order_notifier.dart';
import 'stats_provider.dart';
import 'theme_notifier.dart';
import 'settings_provider.dart';
import 'firebase_providers.dart';

// Re-export themeNotifierProvider
export 'theme_notifier.dart' show themeNotifierProvider;

// --- Service Providers ---
// Changed from FutureProvider to a regular Provider with lazy initialization
final storageServiceProvider = Provider<StorageService>((ref) {
  final service = StorageService();
  // The init() will be called when the service is first used
  service.init().catchError((e) {
    debugPrint('Failed to initialize StorageService: $e');
  });
  return service;
});

final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService();
});

final verificationServiceProvider = Provider<VerificationService>((ref) {
  return VerificationService(
    firestore: ref.watch(firebaseFirestoreProvider),
    emailService: ref.watch(emailServiceProvider),
  );
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final orderServiceProvider = Provider.autoDispose<OrderService>((ref) {
  return OrderService(firestore: ref.watch(firebaseFirestoreProvider));
});

final notificationServiceProvider =
    Provider.autoDispose<NotificationService>((ref) {
  return NotificationService(firestore: ref.watch(firebaseFirestoreProvider));
});

final statsServiceProvider = Provider.autoDispose<StatsService>((ref) {
  return StatsService();
});

final catalogProductServiceProvider = Provider<CatalogProductService>((ref) {
  return CatalogProductService(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService(storage: ref.watch(firebaseStorageProvider));
});

final vendorProductServiceProvider =
    Provider.autoDispose<VendorProductService?>((ref) {
  final vendorId = ref.watch(currentVendorIdProvider);
  if (vendorId == null) {
    return null;
  }
  return VendorProductService(
    vendorId: vendorId,
    isAdmin: false,
    firestore: ref.watch(firebaseFirestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

// --- Auth Providers ---
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  // Get the synchronously available services
  final firebaseService = ref.watch(firebaseServiceProvider);
  final verificationService = ref.watch(verificationServiceProvider);
  final storageService = ref.watch(storageServiceProvider);

  return AuthNotifier(
    firebaseService: firebaseService,
    storageService: storageService,
    verificationService: verificationService,
  );
});

final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authNotifierProvider);
});

final currentVendorProvider = Provider<Vendor?>((ref) {
  return ref.watch(authStateProvider).vendor;
});

final currentVendorIdProvider = Provider<String?>((ref) {
  return ref.watch(currentVendorProvider)?.id;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).status == AuthStatus.authenticated;
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAdmin;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider.select((state) => state.isLoading));
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider.select((state) => state.error));
});

// --- Settings Provider ---
final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, app_settings.Settings>((ref) {
  return SettingsNotifier(ref.watch(settingsServiceProvider));
});

// --- Order Provider ---
final orderNotifierProvider =
    StateNotifierProvider.autoDispose<OrderNotifier, OrderState>((ref) {
  final vendorId = ref.watch(currentVendorIdProvider);
  if (vendorId == null) {
    return OrderNotifier.empty();
  }
  return OrderNotifier(
    ref.watch(orderServiceProvider),
    ref.watch(notificationServiceProvider),
    vendorId,
  );
});

// --- Notification Provider ---
final notificationsStreamProvider =
    StreamProvider.autoDispose<List<VendorNotification>>((ref) {
  final vendorId = ref.watch(currentVendorIdProvider);
  if (vendorId == null) {
    return Stream.value([]);
  }
  return ref
      .watch(notificationServiceProvider)
      .watchVendorNotifications(vendorId);
});

final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  final vendorId = ref.watch(currentVendorIdProvider);
  if (vendorId == null) {
    return Stream.value(0);
  }
  return ref.watch(notificationServiceProvider).watchUnreadCount(vendorId);
});

// --- Stats Provider ---
final statsNotifierProvider =
    StateNotifierProvider.autoDispose<StatsNotifier, StatsState>((ref) {
  final vendorId = ref.watch(currentVendorIdProvider);
  if (vendorId == null) {
    return StatsNotifier.empty();
  }
  return StatsNotifier(
    ref.watch(statsServiceProvider),
    vendorId,
  );
});
