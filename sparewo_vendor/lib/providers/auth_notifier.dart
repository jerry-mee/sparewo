// /Users/jeremy/Development/sparewo/sparewo_vendor/lib/providers/auth_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/ui_notification_service.dart';
import '../constants/enums.dart';
import '../models/auth_result.dart';
import '../models/vendor.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../services/verification_service.dart';
import '../services/logger_service.dart';
import '../exceptions/auth_exceptions.dart';
import '../exceptions/firebase_exceptions.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseService _firebaseService;
  final StorageService _storageService;
  final VerificationService _verificationService;
  final LoggerService _logger = LoggerService.instance;
  final UINotificationService _uiNotificationService = UINotificationService();

  AuthNotifier({
    required FirebaseService firebaseService,
    required StorageService storageService,
    required VerificationService verificationService,
  })  : _firebaseService = firebaseService,
        _storageService = storageService,
        _verificationService = verificationService,
        super(const AuthState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final token = _storageService.getToken();
      if (token != null) {
        final result = await _firebaseService.getCurrentUser();
        if (result != null) {
          await _handleAuthSuccess(result);
          return;
        }
      }
      await _handleSignOut();
    } catch (e, s) {
      _logger.error('Error checking current user', error: e, stackTrace: s);
      await _handleSignOut();
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _firebaseService.signInWithEmailPassword(
          email: email, password: password);
      await _handleAuthSuccess(result);
    } catch (e) {
      _handleError(e);
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signUp(Map<String, dynamic> vendorData, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final email = vendorData['email'] as String;
      final result = await _firebaseService.createUserWithEmailPassword(
          email: email, password: password, vendorData: vendorData);
      await _verificationService.sendVerificationCode(
          email: email, isVendor: true);
      _uiNotificationService
          .showInfo('A verification code has been sent to your email.');
      await _handleAuthSuccess(result);
    } catch (e) {
      _handleError(e);
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> verifyEmail(String email, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (await _verificationService.verifyCode(email, code)) {
        if (state.vendor != null) {
          // Create a new vendor with updated status
          final updatedVendor = Vendor(
            id: state.vendor!.id,
            name: state.vendor!.name,
            email: state.vendor!.email,
            phone: state.vendor!.phone,
            businessName: state.vendor!.businessName,
            businessAddress: state.vendor!.businessAddress,
            categories: state.vendor!.categories,
            profileImage: state.vendor!.profileImage,
            businessHours: state.vendor!.businessHours,
            settings: state.vendor!.settings,
            isVerified: true,
            status: VendorStatus.approved,
            rating: state.vendor!.rating,
            completedOrders: state.vendor!.completedOrders,
            totalProducts: state.vendor!.totalProducts,
            fcmToken: state.vendor!.fcmToken,
            latitude: state.vendor!.latitude,
            longitude: state.vendor!.longitude,
            createdAt: state.vendor!.createdAt,
            updatedAt: DateTime.now(),
          );

          await _firebaseService.updateVendorProfile(updatedVendor);
          await refreshVendorProfile();
          _uiNotificationService
              .showSuccess('Email successfully verified! Welcome.');
        } else {
          throw Exception(
              "Critical error: Cannot verify profile, user data not found in state.");
        }
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendVerificationEmail(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await _verificationService.sendVerificationCode(
          email: email, isVendor: true);
      state = state.copyWith(verificationEmail: email, isLoading: false);
    } catch (e, s) {
      _handleError(e, s);
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshVendorProfile() async {
    if (state.vendor?.id == null) return;
    try {
      final updatedVendor =
          await _firebaseService.getVendorProfile(state.vendor!.id);
      if (updatedVendor != null) {
        state = state.copyWith(
            vendor: updatedVendor,
            status: updatedVendor.isVerified
                ? AuthStatus.authenticated
                : AuthStatus.unverified);
      }
    } catch (e, s) {
      _logger.error('Failed to refresh vendor profile',
          error: e, stackTrace: s);
    }
  }

  Future<void> updateVendorProfile(Vendor vendor) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firebaseService.updateVendorProfile(vendor);
      state = state.copyWith(vendor: vendor, isLoading: false);
    } catch (e, s) {
      _handleError(e, s);
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await firebase_auth.FirebaseAuth.instance
          .sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
    } catch (e, s) {
      _handleError(e, s);
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void skipLogin() {
    state = state.copyWith(status: AuthStatus.unauthenticated, isSkipped: true);
  }

  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      await _handleSignOut();
    } catch (e, s) {
      _handleError(e, s);
      rethrow;
    }
  }

  Future<void> _handleAuthSuccess(AuthResult result) async {
    if (result.vendor == null) {
      await _storageService.clearAuthData();
      state = const AuthState(status: AuthStatus.onboardingRequired);
      _logger.warning(
          'Authentication successful, but no vendor profile found. Redirecting to onboarding.');
      return;
    }

    await _storageService.saveAuthResult(result);

    state = state.copyWith(
      vendor: result.vendor,
      status: result.vendor!.isVerified
          ? AuthStatus.authenticated
          : AuthStatus.unverified,
      token: result.token,
      userRole: result.userRole,
      isLoading: false,
      error: null,
      verificationEmail: result.vendor!.email,
    );
  }

  Future<void> _handleSignOut() async {
    await _storageService.clearAuthData();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void _handleError(dynamic error, [StackTrace? stackTrace]) {
    _logger.error('Auth operation failed',
        error: error, stackTrace: stackTrace);
    String friendlyMessage = 'An unexpected error occurred. Please try again.';

    if (error is firebase_auth.FirebaseAuthException) {
      friendlyMessage = FirebaseService.handleFirebaseAuthError(error).message;
    } else if (error is AuthException) {
      friendlyMessage = error.message;
    } else if (error is VerificationException) {
      friendlyMessage = error.message;
    } else if (error is FirestoreException) {
      friendlyMessage = error.message;
    }

    _uiNotificationService.showError(friendlyMessage);
    state = state.copyWith(
      error: friendlyMessage,
      status: AuthStatus.error,
      isLoading: false,
    );
  }
}
