class CustomAuthException implements Exception {
  final String message;
  final String? code;

  const CustomAuthException({
    required this.message,
    this.code,
  });

  @override
  String toString() => code != null ? '$message (Code: $code)' : message;
}

class GoogleAccountException implements Exception {
  final String message;

  const GoogleAccountException(this.message);

  @override
  String toString() => message;
}

class AuthValidationException implements Exception {
  final String message;
  final String? field;
  final String? code;

  const AuthValidationException({
    required this.message,
    this.field,
    this.code,
  });

  @override
  String toString() {
    if (field != null) {
      return '$message (Field: $field)';
    }
    return message;
  }
}

class AuthNetworkException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;

  const AuthNetworkException({
    required this.message,
    this.statusCode,
    this.endpoint,
  });

  @override
  String toString() {
    final buffer = StringBuffer(message);

    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }

    if (endpoint != null) {
      buffer.write(' [Endpoint: $endpoint]');
    }

    return buffer.toString();
  }
}

class AuthTokenException implements Exception {
  final String message;
  final String? tokenType;

  const AuthTokenException({
    required this.message,
    this.tokenType,
  });

  @override
  String toString() =>
      tokenType != null ? '$message (Token: $tokenType)' : message;
}
