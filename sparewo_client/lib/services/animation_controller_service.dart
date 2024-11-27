// lib/services/animation_controller_service.dart

import 'package:flutter/material.dart';

class AnimationControllerService {
  static final AnimationControllerService _instance =
      AnimationControllerService._internal();

  factory AnimationControllerService() => _instance;

  AnimationControllerService._internal();

  // Navigation transitions
  AnimationController createFadeTransitionController({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return AnimationController(
      vsync: vsync,
      duration: duration,
    );
  }

  // Scale animations for buttons and cards
  AnimationController createScaleController({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return AnimationController(
      vsync: vsync,
      duration: duration,
    );
  }

  // Slide animations
  AnimationController createSlideController({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return AnimationController(
      vsync: vsync,
      duration: duration,
    );
  }

  // Create standard animations
  Animation<double> createFadeAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }

  Animation<double> createScaleAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));
  }

  Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0.0, 0.2),
    Offset end = const Offset(0.0, 0.0),
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ));
  }

  // Button press animation
  void animateButtonPress(AnimationController controller) async {
    await controller.forward();
    await controller.reverse();
  }

  // Tab selection animation
  void animateTabSelection(AnimationController controller) async {
    await controller.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await controller.reverse();
  }

  // Section reveal animation
  Future<void> animateSectionReveal(AnimationController controller) async {
    await controller.forward();
  }

  // Card hover animation
  void animateCardHover(AnimationController controller, bool isHovered) async {
    if (isHovered) {
      await controller.forward();
    } else {
      await controller.reverse();
    }
  }

  // Helper method to dispose multiple controllers
  void disposeControllers(List<AnimationController> controllers) {
    for (var controller in controllers) {
      controller.dispose();
    }
  }
}
