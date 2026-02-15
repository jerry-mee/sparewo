// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:sparewo_vendor/models/vendor_product.dart';
import 'package:sparewo_vendor/screens/settings/profile_screen.dart';
import 'package:sparewo_vendor/screens/settings/store_settings_screen.dart';
import '../models/order.dart';
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
import '../screens/email_verification_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/settings/support_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/notifications/notifications_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String products = '/products';
  static const String addEditProduct = '/products/add_edit';
  static const String productDetail = '/products/detail';
  static const String orders = '/orders';
  static const String orderDetails = '/orders/detail';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String storeSettings = '/settings/store';
  static const String adminPanel = '/admin';
  static const String help = '/help';
  static const String support = '/support';
  static const String about = '/about';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case emailVerification:
        return MaterialPageRoute(
            builder: (_) => const EmailVerificationScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case products:
        return MaterialPageRoute(
            builder: (_) => const ProductManagementScreen());
      case addEditProduct:
        final product = routeSettings.arguments as VendorProduct?;
        return MaterialPageRoute(
            builder: (_) => AddEditProductScreen(product: product));
      case productDetail:
        final product = routeSettings.arguments as VendorProduct;
        return MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product));
      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      case orderDetails:
        final order = routeSettings.arguments as VendorOrder;
        return MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(order: order));
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case storeSettings:
        return MaterialPageRoute(builder: (_) => const StoreSettingsScreen());
      case support:
        return MaterialPageRoute(builder: (_) => const SupportScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route ${routeSettings.name} not found')),
          ),
        );
    }
  }

  const AppRouter._();
}
