import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  // Navigation feedback
  Future<void> navigatorPop(BuildContext context) async {
    await HapticFeedback.selectionClick();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  // Navigation feedback with custom route
  Future<void> navigateTo(BuildContext context, String route,
      {Object? arguments}) async {
    await HapticFeedback.selectionClick();
    if (context.mounted) {
      Navigator.of(context).pushNamed(route, arguments: arguments);
    }
  }

  // Bottom navigation feedback
  Future<void> bottomNavTap() async {
    await HapticFeedback.lightImpact();
  }

  // Success action feedback
  Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  // Error action feedback
  Future<void> error() async {
    await HapticFeedback.heavyImpact();
  }

  // Button tap feedback
  Future<void> buttonTap() async {
    await HapticFeedback.selectionClick();
  }

  // Form submission feedback
  Future<void> formSubmit() async {
    await HapticFeedback.mediumImpact();
  }

  // Cart action feedback
  Future<void> cartAction() async {
    await HapticFeedback.mediumImpact();
  }
}
