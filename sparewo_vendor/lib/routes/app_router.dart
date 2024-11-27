import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/products/product_management_screen.dart';
import '../screens/products/add_edit_product_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/orders/order_details_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/notifications/notifications_screen.dart';

class AppRouter {
  // Define route names as static constants
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String products = '/products';
  static const String addProduct = '/products/add';
  static const String editProduct = '/products/edit';
  static const String productDetail = '/products/detail';
  static const String orders = '/orders';
  static const String orderDetails = '/orders/detail';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String editProfile = '/profile/edit';
  static const String help = '/help';
  static const String support = '/support';
  static const String about = '/about';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name;

    if (name == splash) {
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    }

    if (name == onboarding) {
      return MaterialPageRoute(builder: (_) => const OnboardingScreen());
    }

    if (name == login) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }

    if (name == signup) {
      return MaterialPageRoute(builder: (_) => const SignupScreen());
    }

    if (name == dashboard) {
      return MaterialPageRoute(builder: (_) => const DashboardScreen());
    }

    if (name == products) {
      return MaterialPageRoute(
        builder: (_) => const ProductManagementScreen(),
      );
    }

    if (name == addProduct) {
      return MaterialPageRoute(builder: (_) => const AddEditProductScreen());
    }

    if (name == editProduct) {
      final product = settings.arguments as Product;
      return MaterialPageRoute(
        builder: (_) => AddEditProductScreen(product: product),
      );
    }

    if (name == productDetail) {
      final product = settings.arguments as Product;
      return MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      );
    }

    if (name == orders) {
      return MaterialPageRoute(builder: (_) => const OrdersScreen());
    }

    if (name == orderDetails) {
      final order = settings.arguments as VendorOrder;
      return MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(order: order),
      );
    }

    if (name == settings) {
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    }

    if (name == notifications) {
      return MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      );
    }

    if (name == editProfile) {
      return MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      );
    }

    if (name == help) {
      return MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('Help Center')),
        ),
      );
    }

    if (name == support) {
      return MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('Support')),
        ),
      );
    }

    if (name == about) {
      return MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('About')),
        ),
      );
    }

    // Default route for unknown routes
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text('Route ${settings.name} not found'),
        ),
      ),
    );
  }

  // Prevent instantiation
  const AppRouter._();
}
