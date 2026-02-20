// lib/features/auth/application/auth_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import 'package:sparewo_client/features/auth/data/auth_repository.dart';
import 'package:sparewo_client/features/auth/domain/user_model.dart';

/// ---------------------------------------------------------------------------
/// REPOSITORY PROVIDER
/// ---------------------------------------------------------------------------

/// Single instance of our auth repository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// ---------------------------------------------------------------------------
/// AUTH STATE STREAMS
/// ---------------------------------------------------------------------------

/// Raw Firebase auth state – fast, used by the router.
final authStateChangesProvider = StreamProvider<fb_auth.User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Rich UserModel stream – for screens that need profile data.
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final repo = ref.watch(authRepositoryProvider);

  // When Firebase user changes, map to Firestore UserModel (or null).
  return repo.authStateChanges.asyncMap((fbUser) async {
    if (fbUser == null) return null;
    return repo.getCurrentUserData();
  });
});

/// ---------------------------------------------------------------------------
/// AUTH ACTIONS NOTIFIER
/// ---------------------------------------------------------------------------

/// Async notifier used purely for *actions* (sign in, sign up, verify, etc.).
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<UserModel?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  FutureOr<UserModel?> build() async {
    // We let currentUserProvider own the live user stream.
    // This notifier's state only reflects "this ongoing auth action".
    return null;
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _repo.signInWithEmailAndPassword(email: email, password: password);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.startRegistration(
        email: email,
        password: password,
        name: name,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.verifyEmailAndCompleteRegistration(
        email: email,
        code: code,
      );
      state = AsyncData(user);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> resendVerificationCode({required String email}) async {
    await _repo.resendVerificationCode(email: email);
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final user = await _repo.signInWithGoogle();
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> linkGoogleAccount() async {
    state = const AsyncLoading();
    try {
      final user = await _repo.linkWithGoogle();
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    state = const AsyncLoading();
    try {
      await _repo.sendPasswordResetEmail(email: email);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await _repo.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
