// lib/exceptions/firebase_exceptions.dart

/// A base class for custom Firebase-related exceptions.
class FirebaseException implements Exception {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  const FirebaseException(
    this.message, {
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'FirebaseException: $message'
        '${error != null ? '\nOriginal error: $error' : ''}'
        '${stackTrace != null ? '\n$stackTrace' : ''}';
  }
}

/// Thrown when a Firebase core initialization fails.
class FirebaseInitializationException extends FirebaseException {
  const FirebaseInitializationException(
    super.message, {
    super.error,
    super.stackTrace,
  });
}

/// Thrown when a Firestore operation fails.
class FirestoreException extends FirebaseException {
  const FirestoreException(
    super.message, {
    super.error,
    super.stackTrace,
  });
}

/// Thrown when a Firebase Storage operation fails.
class StorageException extends FirebaseException {
  const StorageException(
    super.message, {
    super.error,
    super.stackTrace,
  });
}
