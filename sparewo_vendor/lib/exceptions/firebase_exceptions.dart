class FirestoreException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const FirestoreException(
    this.message, {
    this.code,
    this.details,
  });

  @override
  String toString() {
    if (code != null) {
      return '$message (Code: $code)';
    }
    return message;
  }
}

class StorageException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const StorageException(
    this.message, {
    this.code,
    this.details,
  });

  @override
  String toString() {
    if (code != null) {
      return '$message (Code: $code)';
    }
    return message;
  }
}

class FirebaseMessagingException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const FirebaseMessagingException(
    this.message, {
    this.code,
    this.details,
  });

  @override
  String toString() {
    if (code != null) {
      return '$message (Code: $code)';
    }
    return message;
  }
}

class FirebaseAuthenticationException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const FirebaseAuthenticationException(
    this.message, {
    this.code,
    this.details,
  });

  @override
  String toString() {
    if (code != null) {
      return '$message (Code: $code)';
    }
    return message;
  }
}
