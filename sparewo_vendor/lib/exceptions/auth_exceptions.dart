class AuthException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? metadata;

  const AuthException({
    required this.message,
    this.code,
    this.metadata,
  });

  @override
  String toString() => code != null ? '$message (Code: $code)' : message;

  // Common error codes
  bool get isUserNotFound => code == 'user-not-found';
  bool get isWrongPassword => code == 'wrong-password';
  bool get isInvalidEmail => code == 'invalid-email';
  bool get isUserDisabled => code == 'user-disabled';
  bool get isEmailAlreadyInUse => code == 'email-already-in-use';
  bool get isOperationNotAllowed => code == 'operation-not-allowed';
  bool get isWeakPassword => code == 'weak-password';
  bool get isTokenExpired => code == 'token-expired';
  bool get isNetworkError => code == 'network-error';
}

class GoogleAuthException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? metadata;

  const GoogleAuthException({
    required this.message,
    this.code,
    this.metadata,
  });

  @override
  String toString() => code != null ? '$message (Code: $code)' : message;

  bool get isCancelled => code == 'sign_in_cancelled';
  bool get isAccountExists =>
      code == 'account-exists-with-different-credential';
  bool get isNetworkError => code == 'network_error';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;
  final String? code;

  const ValidationException({
    required this.message,
    this.errors,
    this.code,
  });

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      final errorMessages = errors!.values.expand((e) => e).join(', ');
      return '$message ($errorMessages)';
    }
    return message;
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'errors': errors,
      'code': code,
    };
  }
}

class SignUpException extends AuthException {
  final Map<String, dynamic>? validationErrors;

  const SignUpException({
    required super.message,
    super.code,
    this.validationErrors,
    super.metadata,
  });

  bool get hasValidationErrors =>
      validationErrors != null && validationErrors!.isNotEmpty;
}

class SignInException extends AuthException {
  final int? attempts;
  final DateTime? lastAttempt;

  const SignInException({
    required super.message,
    super.code,
    this.attempts,
    this.lastAttempt,
    super.metadata,
  });

  bool get isLocked => attempts != null && attempts! >= 5;
}

class TokenException extends AuthException {
  final DateTime? expiry;
  final bool isRefreshTokenExpired;

  const TokenException({
    required super.message,
    super.code,
    this.expiry,
    this.isRefreshTokenExpired = false,
    super.metadata,
  });

  bool get canRefresh => !isRefreshTokenExpired;
}

class SessionException extends AuthException {
  final DateTime? lastActivity;
  final String? deviceId;

  const SessionException({
    required super.message,
    super.code,
    this.lastActivity,
    this.deviceId,
    super.metadata,
  });
}
