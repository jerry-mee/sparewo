// lib/services/error_interceptor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ui_notification_service.dart';
import '../services/logger_service.dart';
import '../widgets/error_message_widget.dart';

class ErrorInterceptor {
  static final ErrorInterceptor _instance = ErrorInterceptor._internal();
  factory ErrorInterceptor() => _instance;
  ErrorInterceptor._internal();

  final LoggerService _logger = LoggerService.instance;
  final UINotificationService _uiNotificationService = UINotificationService();

  // Setup global error handling
  void setupErrorHandling() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _logger.error(
        'Flutter Error',
        error: details.exception,
        stackTrace: details.stack,
      );

      // Log to console in debug mode
      if (details.stack != null) {
        FlutterError.dumpErrorToConsole(details);
      }
    };
  }

  // Handle async errors
  void handleAsyncError(dynamic error, StackTrace? stackTrace) {
    _logger.error('Async Error', error: error, stackTrace: stackTrace);

    final message = _getReadableErrorMessage(error);
    _uiNotificationService.showError(message);
  }

  // Convert technical errors to user-friendly messages
  String _getReadableErrorMessage(dynamic error) {
    final errorString = error.toString();

    // Firebase errors
    if (errorString.contains('permission-denied') ||
        errorString.contains('PERMISSION_DENIED')) {
      return 'You do not have permission to perform this action.';
    }

    if (errorString.contains('network-request-failed') ||
        errorString.contains('Failed host lookup')) {
      return 'Network error. Please check your internet connection.';
    }

    if (errorString.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }

    if (errorString.contains('user-not-found')) {
      return 'Account not found. Please check your credentials.';
    }

    if (errorString.contains('wrong-password') ||
        errorString.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }

    if (errorString.contains('email-already-in-use')) {
      return 'This email is already registered.';
    }

    // Firestore errors
    if (errorString.contains('failed-precondition')) {
      return 'Operation failed. Please try again.';
    }

    if (errorString.contains('unavailable')) {
      return 'Service temporarily unavailable. Please try again.';
    }

    // Vehicle data errors
    if (errorString.contains('car_models') ||
        errorString.contains('car_brand')) {
      return 'Failed to load vehicle data. Please try again.';
    }

    // Default message
    return 'An unexpected error occurred. Please try again.';
  }
}

// Error boundary widget to catch widget errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stack)? errorBuilder;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    _error = null;
    _stackTrace = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }

      return Material(
        child: Center(
          child: ErrorMessageWidget(
            message: ErrorInterceptor()._getReadableErrorMessage(_error),
            isInline: false,
            onRetry: () {
              setState(() {
                _error = null;
                _stackTrace = null;
              });
            },
          ),
        ),
      );
    }

    return ErrorListener(
      onError: (error, stackTrace) {
        setState(() {
          _error = error;
          _stackTrace = stackTrace;
        });
      },
      child: widget.child,
    );
  }
}

// Error listener widget
class ErrorListener extends StatefulWidget {
  final Widget child;
  final void Function(Object error, StackTrace? stackTrace) onError;

  const ErrorListener({
    Key? key,
    required this.child,
    required this.onError,
  }) : super(key: key);

  @override
  State<ErrorListener> createState() => _ErrorListenerState();
}

class _ErrorListenerState extends State<ErrorListener> {
  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      widget.onError(details.exception, details.stack);
      return const SizedBox.shrink();
    };

    return widget.child;
  }
}

// Provider-aware error handler mixin
mixin ErrorHandlerMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  void handleError(dynamic error, [StackTrace? stackTrace]) {
    ErrorInterceptor().handleAsyncError(error, stackTrace);
  }

  Future<void> runWithErrorHandling(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (e, s) {
      handleError(e, s);
    }
  }
}
