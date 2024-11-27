import 'package:flutter/material.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/cart/checkout_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/support_screen.dart';
import '../screens/catalog/product_detail_screen.dart';
import '../screens/autohub/autohub_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String support = '/support';
  static const String productDetail = '/product-detail';
  static const String autohub = '/autohub';

  static final Map<String, WidgetBuilder> _routes = {
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    login: (_) => const LoginScreen(),
    signup: (_) => const SignUpScreen(),
    home: (_) => const HomeScreen(),
    cart: (_) => const CartScreen(),
    checkout: (_) => const CheckoutScreen(),
    profile: (_) => const UserProfileScreen(),
    settings: (_) => const SettingsScreen(),
    support: (_) => const SupportScreen(),
    autohub: (_) => const AutoHubScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Handle product detail route separately due to arguments
    if (settings.name == productDetail) {
      if (settings.arguments is Map<String, dynamic>) {
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            product: settings.arguments as Map<String, dynamic>,
          ),
        );
      }
      return _buildErrorRoute('Invalid product data');
    }

    // Handle registered routes
    final builder = _routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(builder: builder);
    }

    // Handle unknown routes
    return _buildErrorRoute('Page not found');
  }

  static Route<dynamic> _buildErrorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(message)),
      ),
    );
  }
}
