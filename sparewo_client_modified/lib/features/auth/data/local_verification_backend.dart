import 'package:sparewo_client/features/auth/data/verification_backend.dart';
import 'package:sparewo_client/features/auth/data/verification_session_store.dart';

class LocalVerificationBackend implements VerificationBackend {
  const LocalVerificationBackend(this._store);

  final VerificationSessionStore _store;

  @override
  Future<void> generateCode({
    required String email,
    required String password,
    required String name,
    required bool existingAccount,
  }) async {
    final existing = await _store.load(email);
    if (existing == null) {
      throw UnimplementedError('Local backend requires repository orchestration.');
    }
  }

  @override
  Future<void> resendCode({required String email}) async {
    final existing = await _store.load(email);
    if (existing == null) {
      throw UnimplementedError('Local backend requires repository orchestration.');
    }
  }

  @override
  Future<bool> verifyCode({required String email, required String code}) async {
    final existing = await _store.load(email);
    if (existing == null) return false;
    return existing.code == code;
  }
}
