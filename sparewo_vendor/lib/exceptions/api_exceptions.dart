class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? errors;
  final String? errorCode;
  final dynamic originalError;

  const ApiException({
    required this.message,
    required this.statusCode,
    this.errors,
    this.errorCode,
    this.originalError,
  });

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      final errorMessages = errors!.values.join(', ');
      return '$message ($errorMessages)';
    }
    return message;
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 422;
  bool get isServerError => statusCode >= 500;
  bool get isNetworkError => statusCode == 0;
  bool get isTimeout => statusCode == 408;

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'statusCode': statusCode,
      'errors': errors,
      'errorCode': errorCode,
    };
  }
}

class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;
  final String? errorCode;

  const ValidationException({
    required this.message,
    this.errors,
    this.errorCode,
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
      'errorCode': errorCode,
    };
  }
}

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const NetworkException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() =>
      statusCode != null ? '$message (Status: $statusCode)' : message;

  bool get isTimeout => statusCode == 408;
  bool get isNoInternet => statusCode == 0;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'statusCode': statusCode,
    };
  }
}

class AuthException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  const AuthException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => code != null ? '$message (Code: $code)' : message;

  bool get isInvalidCredentials => code == 'invalid-credentials';
  bool get isEmailNotVerified => code == 'email-not-verified';
  bool get isAccountDisabled => code == 'account-disabled';
  bool get isTokenExpired => code == 'token-expired';

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'code': code,
      'details': details,
    };
  }
}

class CacheException implements Exception {
  final String message;
  final String? key;
  final dynamic originalError;

  const CacheException({
    required this.message,
    this.key,
    this.originalError,
  });

  @override
  String toString() => key != null ? '$message (Key: $key)' : message;

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'key': key,
    };
  }
}
