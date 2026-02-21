abstract class VerificationBackend {
  Future<void> generateCode({
    required String email,
    required String password,
    required String name,
    required bool existingAccount,
  });

  Future<void> resendCode({required String email});

  Future<bool> verifyCode({
    required String email,
    required String code,
  });
}
