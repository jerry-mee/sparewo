// lib/features/auth/application/auth_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:sparewo_client/core/logging/app_logger.dart';

import 'package:sparewo_client/features/auth/data/auth_repository.dart';
import 'package:sparewo_client/features/auth/data/verification_session_store.dart';
import 'package:sparewo_client/features/auth/domain/user_model.dart';

/// ---------------------------------------------------------------------------
/// REPOSITORY PROVIDER
/// ---------------------------------------------------------------------------

/// Single instance of our auth repository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(verificationSessionStore: VerificationSessionStore());
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
  return repo.userProfileChanges;
});

final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateChangesProvider).asData?.value?.uid;
});

final registrationInProgressProvider =
    NotifierProvider<RegistrationInProgressNotifier, bool>(
      RegistrationInProgressNotifier.new,
    );

class RegistrationInProgressNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setInProgress(bool value) => state = value;
}

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
    AppLogger.info(
      'AuthNotifier.signIn',
      'Action started',
      extra: {'email': email.trim().toLowerCase()},
    );
    state = const AsyncLoading();
    try {
      await _repo.signInWithEmailAndPassword(email: email, password: password);
      state = const AsyncData(null);
      AppLogger.info('AuthNotifier.signIn', 'Action completed');
    } catch (e, st) {
      AppLogger.error(
        'AuthNotifier.signIn',
        'Action failed',
        error: e,
        stackTrace: st,
      );
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    AppLogger.info(
      'AuthNotifier.signUp',
      'Action started',
      extra: {'email': email.trim().toLowerCase()},
    );
    state = const AsyncLoading();
    ref.read(registrationInProgressProvider.notifier).setInProgress(true);
    try {
      await _repo.startRegistration(
        email: email,
        password: password,
        name: name,
      );
      state = const AsyncData(null);
      AppLogger.info('AuthNotifier.signUp', 'Action completed');
    } catch (e, st) {
      AppLogger.error(
        'AuthNotifier.signUp',
        'Action failed',
        error: e,
        stackTrace: st,
      );
      state = AsyncError(e, st);
      rethrow;
    } finally {
      ref.read(registrationInProgressProvider.notifier).setInProgress(false);
    }
  }

  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    AppLogger.info(
      'AuthNotifier.verifyEmail',
      'Action started',
      extra: {'email': email.trim().toLowerCase()},
    );
    state = const AsyncLoading();
    ref.read(registrationInProgressProvider.notifier).setInProgress(true);
    try {
      final user = await _repo.verifyEmailAndCompleteRegistration(
        email: email,
        code: code,
      );
      state = AsyncData(user);
      AppLogger.info(
        'AuthNotifier.verifyEmail',
        'Action completed',
        extra: {'uid': user.id},
      );
      return true;
    } catch (e, st) {
      AppLogger.error(
        'AuthNotifier.verifyEmail',
        'Action failed',
        error: e,
        stackTrace: st,
      );
      state = AsyncError(e, st);
      rethrow;
    } finally {
      ref.read(registrationInProgressProvider.notifier).setInProgress(false);
    }
  }

  Future<void> resendVerificationCode({required String email}) async {
    AppLogger.info(
      'AuthNotifier.resendVerification',
      'Action started',
      extra: {'email': email.trim().toLowerCase()},
    );
    await _repo.resendVerificationCode(email: email);
    AppLogger.info('AuthNotifier.resendVerification', 'Action completed');
  }

  Future<void> resumeIncompleteOnboarding({
    required String email,
    required String password,
    String? name,
  }) async {
    AppLogger.info(
      'AuthNotifier.resumeOnboarding',
      'Action started',
      extra: {'email': email.trim().toLowerCase()},
    );
    state = const AsyncLoading();
    ref.read(registrationInProgressProvider.notifier).setInProgress(true);
    try {
      await _repo.resumeIncompleteOnboarding(
        email: email,
        password: password,
        name: name,
      );
      state = const AsyncData(null);
      AppLogger.info('AuthNotifier.resumeOnboarding', 'Action completed');
    } catch (e, st) {
      AppLogger.error(
        'AuthNotifier.resumeOnboarding',
        'Action failed',
        error: e,
        stackTrace: st,
      );
      state = AsyncError(e, st);
      rethrow;
    } finally {
      ref.read(registrationInProgressProvider.notifier).setInProgress(false);
    }
  }

  Future<void> signInWithGoogle() async {
    AppLogger.info('AuthNotifier.signInWithGoogle', 'Action started');
    state = const AsyncLoading();
    try {
      final user = await _repo.signInWithGoogle();
      state = AsyncData(user);
      AppLogger.info(
        'AuthNotifier.signInWithGoogle',
        'Action completed',
        extra: {'uid': user.id},
      );
    } catch (e, st) {
      AppLogger.error(
        'AuthNotifier.signInWithGoogle',
        'Action failed',
        error: e,
        stackTrace: st,
      );
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> linkGoogleAccount() async {
    AppLogger.info('AuthNotifier.linkGoogleAccount', 'Action started');
    state = const AsyncLoading();
    try {
      final user = await _repo.linkWithGoogle();
      state = AsyncData(user);
      AppLogger.info(
        'AuthNotifier.linkGoogleAccount',
        'Action completed',
        extra: {'uid': user.id},
      );
    } catch (e, st) {
      AppLogger.error(
        'AuthNotifier.linkGoogleAccount',
        'Action failed',
        error: e,
        stackTrace: st,
      );
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    AppLogger.info(
      'AuthNotifier.sendPasswordReset',
      'Action started',
      extra: {'email': email.trim().toLowerCase()},
    );
    state = const AsyncLoading();
    try {
      await _repo.sendPasswordResetEmail(email: email);
      state = const AsyncData(null);
      AppLogger.info('AuthNotifier.sendPasswordReset', 'Action completed');
    } catch (e, st) {
      AppLogger.error(
        'AuthNotifier.sendPasswordReset',
        'Action failed',
        error: e,
        stackTrace: st,
      );
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    AppLogger.info('AuthNotifier.signOut', 'Action started');
    state = const AsyncLoading();
    try {
      await _repo.signOut();
      state = const AsyncData(null);
      AppLogger.info('AuthNotifier.signOut', 'Action completed');
    } catch (e, st) {
      AppLogger.error(
        'AuthNotifier.signOut',
        'Action failed',
        error: e,
        stackTrace: st,
      );
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
