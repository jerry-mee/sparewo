import 'package:flutter/foundation.dart';

class ErrorHandler {
  static void handleCriticalError(dynamic error, StackTrace stackTrace) {
    debugPrint('Critical Error: $error');
    debugPrint('Stack trace: $stackTrace');

    // Add crash reporting service integration here if needed
    // Example: Crashlytics.recordError(error, stackTrace);
  }
}
