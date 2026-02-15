import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class LoadingService {
  static final LoadingService _instance = LoadingService._internal();
  factory LoadingService() => _instance;

  LoadingService._internal() {
    _configureLoading();
  }

  void _configureLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle =
          EasyLoadingStyle.custom // Use custom to set your own colors
      ..indicatorSize = 45.0
      ..radius = 10.0
      // FIXED: Use specific colors that work on both light and dark backgrounds
      ..progressColor = Colors.white
      ..backgroundColor =
          const Color(0xFF1A1B4B).withOpacity(0.9) // Dark blue, good contrast
      ..indicatorColor = Colors.white
      ..textColor = Colors.white
      ..maskColor = Colors.black.withOpacity(0.5)
      ..userInteractions = false
      ..dismissOnTap = false;
  }

  Future<void> show({String? message}) async {
    await EasyLoading.show(
      status: message ?? 'Please wait...',
      maskType: EasyLoadingMaskType.black,
    );
  }

  Future<void> showSuccess(String message) async {
    await EasyLoading.showSuccess(
      message,
      duration: const Duration(seconds: 2),
      maskType: EasyLoadingMaskType.black,
    );
  }

  Future<void> showError(String message) async {
    await EasyLoading.showError(
      message,
      duration: const Duration(seconds: 3),
      maskType: EasyLoadingMaskType.black,
    );
  }

  Future<void> showInfo(String message) async {
    await EasyLoading.showInfo(
      message,
      duration: const Duration(seconds: 2),
      maskType: EasyLoadingMaskType.black,
    );
  }

  Future<void> showProgress(double progress) async {
    await EasyLoading.showProgress(
      progress,
      status: '${(progress * 100).toStringAsFixed(0)}%',
    );
  }

  Future<void> dismiss() async {
    await EasyLoading.dismiss();
  }
}
