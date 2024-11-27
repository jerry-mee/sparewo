import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api/api_service.dart';
import '../services/storage/storage_service.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../exceptions/auth_exceptions.dart';
import '../utils/error_handler.dart';

enum AuthState {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;
  final FirebaseService _firebaseService;

  StreamSubscription<User?>? _authStateSubscription;
  Timer? _tokenRefreshTimer;
  AuthState _state = AuthState.initial;
  User? _currentUser;
  String? _error;

  AuthProvider({
    required ApiService apiService,
    required StorageService storageService,
    required String googleClientId,
  })  : _apiService = apiService,
        _storageService = storageService,
        _firebaseService = FirebaseService(googleClientId: googleClientId);

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _state == AuthState.loading;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;
  AuthState get state => _state;

  Future<void> init() async {
    try {
      _setState(AuthState.loading);
      await _storageService.init();
      _setupAuthStateListener();
      await _restoreSession();
    } catch (e, stackTrace) {
      ErrorHandler.handleCriticalError(e, stackTrace);
      _setError('Authentication initialization failed');
      _setState(AuthState.error);
    }
  }

  void _setupAuthStateListener() {
    _authStateSubscription?.cancel();
    _authStateSubscription = _firebaseService.authStateChanges.listen(
      (user) async {
        if (user == null) {
          await _handleSignOut();
        } else {
          _currentUser = user;
          _setState(AuthState.authenticated);
        }
      },
      onError: (error) {
        _setError('Authentication state monitoring failed');
        _setState(AuthState.error);
      },
    );
  }

  Future<void> _restoreSession() async {
    try {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        _apiService.setAuthToken(token);
        await refreshUserProfile();
        _startTokenRefreshTimer();
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      debugPrint('Session restoration failed: $e');
      _setState(AuthState.unauthenticated);
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    if (isLoading) return;
    _beginAuthFlow();

    try {
      final result = await _firebaseService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      await _handleAuthSuccess(result);
    } catch (e, stackTrace) {
      _handleAuthError(e, stackTrace);
      rethrow;
    }
  }

  Future<void> refreshUserProfile() async {
    try {
      final userData = await _apiService.getUserProfile();
      _currentUser = User.fromJson(userData);
      notifyListeners();
    } catch (e) {
      debugPrint('User profile refresh failed: $e');
      rethrow;
    }
  }

  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    if (isLoading) return;
    _beginAuthFlow();

    try {
      final isGoogleAccount = await _firebaseService.isGoogleAccount(email);
      if (isGoogleAccount) {
        throw const GoogleAccountException(
          'This email is registered with Google. Please sign in with Google instead.',
        );
      }

      final result = await _firebaseService.createUserWithEmailPassword(
        email: email,
        password: password,
        name: name,
      );
      await _handleAuthSuccess(result);
    } catch (e, stackTrace) {
      _handleAuthError(e, stackTrace);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    if (isLoading) return;
    _beginAuthFlow();

    try {
      final result = await _firebaseService.signInWithGoogle();
      await _handleAuthSuccess(result);
    } catch (e, stackTrace) {
      _handleAuthError(e, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (isLoading) return;
    _setState(AuthState.loading);

    try {
      await _firebaseService.signOut();
      await _handleSignOut();
    } catch (e, stackTrace) {
      ErrorHandler.handleCriticalError(e, stackTrace);
      _setError('Sign out failed');
      rethrow;
    } finally {
      _setState(AuthState.unauthenticated);
    }
  }

  void _beginAuthFlow() {
    _setState(AuthState.loading);
    _clearError();
  }

  Future<void> _handleAuthSuccess(AuthResult result) async {
    await _storageService.setToken(result.token);
    _apiService.setAuthToken(result.token);
    _currentUser = result.user;

    if (result.isNewUser) {
      await _createUserProfile(result.user);
    }

    _startTokenRefreshTimer();
    _setState(AuthState.authenticated);
  }

  void _handleAuthError(Object error, StackTrace stackTrace) {
    ErrorHandler.handleCriticalError(error, stackTrace);
    _setError(_formatErrorMessage(error));
    _setState(AuthState.error);
  }

  String _formatErrorMessage(Object error) {
    if (error is CustomAuthException) {
      return error.message;
    }
    return error.toString();
  }

  Future<void> _createUserProfile(User user) async {
    try {
      await _apiService.createOrUpdateUser(user);
    } catch (e) {
      debugPrint('User profile creation failed: $e');
    }
  }

  Future<void> _handleSignOut() async {
    await _storageService.clearAll();
    _apiService.clearAuthToken();
    _currentUser = null;
    _stopTokenRefreshTimer();
  }

  void _startTokenRefreshTimer() {
    _stopTokenRefreshTimer();
    _tokenRefreshTimer = Timer.periodic(
      const Duration(minutes: 45),
      (_) => _refreshToken(),
    );
  }

  void _stopTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  Future<void> _refreshToken() async {
    try {
      final newToken = await _firebaseService.getIdToken(forceRefresh: true);
      if (newToken != null) {
        await _storageService.setToken(newToken);
        _apiService.setAuthToken(newToken);
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }
  }

  void _setState(AuthState newState) {
    if (_state == newState) return;
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _stopTokenRefreshTimer();
    _firebaseService.dispose();
    super.dispose();
  }
}
