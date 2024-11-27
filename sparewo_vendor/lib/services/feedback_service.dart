import 'package:flutter/services.dart';
import 'dart:async';

class FeedbackService {
  static const Duration _lightImpact = Duration(milliseconds: 10);
  static const Duration _mediumImpact = Duration(milliseconds: 40);
  static const Duration _heavyImpact = Duration(milliseconds: 100);

  Future<void> buttonTap() async {
    await HapticFeedback.selectionClick();
  }

  Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(_heavyImpact);
    await HapticFeedback.heavyImpact();
  }

  Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(_mediumImpact);
    await HapticFeedback.mediumImpact();
  }

  Future<void> warning() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(_lightImpact);
    await HapticFeedback.lightImpact();
  }

  Future<void> impactLight() async {
    await HapticFeedback.lightImpact();
  }

  Future<void> impactMedium() async {
    await HapticFeedback.mediumImpact();
  }

  Future<void> impactHeavy() async {
    await HapticFeedback.heavyImpact();
  }
}
