import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension SafeNavigation on BuildContext {
  void goBackOr(String fallbackRoute) {
    if (canPop()) {
      pop();
      return;
    }
    go(fallbackRoute);
  }
}
