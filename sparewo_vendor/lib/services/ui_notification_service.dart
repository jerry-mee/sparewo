// /Users/jeremy/Development/sparewo/sparewo_vendor/lib/services/ui_notification_service.dart
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/feedback_service.dart';
import '../services/logger_service.dart';

class UINotificationService {
  static final UINotificationService _instance =
      UINotificationService._internal();
  factory UINotificationService() => _instance;
  UINotificationService._internal();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final FeedbackService _feedbackService = FeedbackService();
  final LoggerService _logger = LoggerService.instance;

  String? _lastMessage;
  DateTime? _lastNotificationTime;
  static const Duration _minNotificationInterval = Duration(seconds: 3);

  void _showSnackBar({
    required String message,
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
    SnackBarAction? action,
  }) {
    final now = DateTime.now();
    if (_lastMessage == message &&
        _lastNotificationTime != null &&
        now.difference(_lastNotificationTime!) < _minNotificationInterval) {
      _logger.info('Debouncing duplicate notification: $message');
      return;
    }
    _lastMessage = message;
    _lastNotificationTime = now;

    final messenger = messengerKey.currentState;
    if (messenger == null) {
      _logger.error(
          'ScaffoldMessengerKey is not attached to a MaterialApp. Could not show SnackBar.');
      return;
    }

    messenger.clearSnackBars();

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      action: action ??
          SnackBarAction(
            label: 'DISMISS',
            textColor: textColor,
            onPressed: () => messenger.hideCurrentSnackBar(),
          ),
    );

    messenger.showSnackBar(snackBar);
  }

  void showSuccess(String message) {
    _feedbackService
        .success()
        .catchError((e) => _logger.warning('Feedback service error: $e'));
    final context = messengerKey.currentContext;
    if (context == null) return;

    _showSnackBar(
      message: message,
      backgroundColor:
          Theme.of(context).extension<AppColorsExtension>()!.success,
      textColor: Colors.white,
      icon: Icons.check_circle_outline,
    );
  }

  void showError(String message) {
    _feedbackService
        .error()
        .catchError((e) => _logger.warning('Feedback service error: $e'));
    final context = messengerKey.currentContext;
    if (context == null) return;

    _showSnackBar(
      message: message,
      backgroundColor: Theme.of(context).colorScheme.error,
      textColor: Theme.of(context).colorScheme.onError,
      icon: Icons.error_outline,
    );
  }

  void showWarning(String message) {
    _feedbackService
        .warning()
        .catchError((e) => _logger.warning('Feedback service error: $e'));
    final context = messengerKey.currentContext;
    if (context == null) return;

    _showSnackBar(
      message: message,
      backgroundColor:
          Theme.of(context).extension<AppColorsExtension>()!.pending,
      textColor: Colors.black,
      icon: Icons.warning_amber_rounded,
    );
  }

  void showInfo(String message) {
    _feedbackService
        .buttonTap()
        .catchError((e) => _logger.warning('Feedback service error: $e'));
    final context = messengerKey.currentContext;
    if (context == null) return;

    _showSnackBar(
      message: message,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      textColor: Colors.white,
      icon: Icons.info_outline,
    );
  }
}
