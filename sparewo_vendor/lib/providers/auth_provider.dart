// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../constants/enums.dart';
import 'service_providers.dart';

// -------------------------------------------
// Updated Provider Definition Section
// -------------------------------------------

final authStateNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  final apiService = ref.watch(apiServiceProvider);

  return AuthNotifier(
    firebaseService: firebaseService,
    storageService: storageService,
    apiService: apiService,
  );
});

// -------------------------------------------
// Rest of the auth_provider.dart remains unchanged
// -------------------------------------------

class AuthState {
  final bool isLoading;
  final Vendor? vendor;
  final String? error;
  final AuthStatus status;

  const AuthState({
    this.isLoading = false,
    this.vendor,
    this.error,
    this.status = AuthStatus.initial,
  });

  AuthState copyWith({
    bool? isLoading,
    Vendor? vendor,
    String? error,
    AuthStatus? status,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      vendor: vendor ?? this.vendor,
      error: error,
      status: status ?? this.status,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get hasError => error != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseService _firebaseService;
  final StorageService _storageService;
  final ApiService _apiService;

  AuthNotifier({
    required FirebaseService firebaseService,
    required StorageService storageService,
    required ApiService apiService,
  })  : _firebaseService = firebaseService,
        _storageService = storageService,
        _apiService = apiService,
        super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final token = await _storageService.getToken();
    if (token != null) {
      _apiService.setAuthToken(token);
      await _checkCurrentUser();
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _checkCurrentUser() async {
    try {
      final result = await _firebaseService.getCurrentUser();
      if (result != null) {
        state = state.copyWith(
          vendor: result.vendor,
          status: AuthStatus.authenticated,
        );
      } else {
        await signOut();
      }
    } catch (e) {
      await signOut();
    }
  }

  Future<void> signIn(String email, String password) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _firebaseService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      await _handleAuthSuccess(result);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> signUp(Map<String, dynamic> vendorData, String password) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _firebaseService.createUserWithEmailPassword(
        email: vendorData['email'] as String,
        password: password,
        userData: vendorData,
      );
      await _handleAuthSuccess(result);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> signOut() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      await _firebaseService.signOut();
      await _handleSignOut();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _handleAuthSuccess(AuthResult result) async {
    await _storageService.setToken(result.token);
    _apiService.setAuthToken(result.token);

    state = state.copyWith(
      vendor: result.vendor,
      status: AuthStatus.authenticated,
      isLoading: false,
      error: null,
    );
  }

  Future<void> _handleSignOut() async {
    await _storageService.clearAll();
    _apiService.clearAuthToken();

    state = state.copyWith(
      vendor: null,
      status: AuthStatus.unauthenticated,
      isLoading: false,
      error: null,
    );
  }

  void _handleError(dynamic error) {
    state = state.copyWith(
      error: error.toString(),
      status: AuthStatus.error,
      isLoading: false,
    );
  }
}

// -------------------------------------------
// Derived Providers Section
// -------------------------------------------

// These derived providers remain unchanged.

final authProvider = Provider<AuthNotifier>((ref) {
  return ref.watch(authStateNotifierProvider.notifier);
});

final currentVendorProvider = Provider<Vendor?>((ref) {
  return ref.watch(authStateNotifierProvider).vendor;
});

final currentVendorIdProvider = Provider<String?>((ref) {
  return ref.watch(currentVendorProvider)?.id;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateNotifierProvider).isAuthenticated;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authStateNotifierProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authStateNotifierProvider).error;
});

final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authStateNotifierProvider).status;
});
