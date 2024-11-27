import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  NavigatorState? get navigator => navigatorKey.currentState;
  ScaffoldMessengerState? get messenger => scaffoldKey.currentState;

  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigator!.pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic> replaceTo(String routeName, {Object? arguments}) {
    return navigator!.pushReplacementNamed(routeName, arguments: arguments);
  }

  Future<dynamic> navigateToAndClearStack(String routeName,
      {Object? arguments}) {
    return navigator!.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  void pop<T>([T? result]) {
    return navigator!.pop(result);
  }

  void popUntil(String routeName) {
    navigator!.popUntil(ModalRoute.withName(routeName));
  }

  void showErrorSnackBar(String message) {
    _showSnackBar(
      message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    );
  }

  void showSuccessSnackBar(String message) {
    _showSnackBar(
      message,
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    );
  }

  void showInfoSnackBar(String message) {
    _showSnackBar(
      message,
      backgroundColor: Colors.blue,
      duration: const Duration(seconds: 2),
    );
  }

  void _showSnackBar(
    String message, {
    Color backgroundColor = Colors.black,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (messenger == null) return;

    messenger!.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<bool?> showConfirmationDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    if (navigator == null) return false;

    return showDialog<bool>(
      context: navigator!.context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : Colors.blue,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<void> showLoadingDialog({String message = 'Loading...'}) async {
    if (navigator == null) return;

    return showDialog(
      context: navigator!.context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void hideLoading() {
    if (navigator?.canPop() ?? false) {
      navigator!.pop();
    }
  }
}
