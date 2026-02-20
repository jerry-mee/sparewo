import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_client/core/widgets/scaffold_with_nav_bar.dart';
import 'package:sparewo_client/features/auth/presentation/splash_screen.dart';
import 'package:sparewo_client/features/auth/presentation/welcome_screen.dart';
import 'package:sparewo_client/features/auth/presentation/signup_screen.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/auth/presentation/login_screen.dart';
import 'package:sparewo_client/features/auth/presentation/email_verification_screen.dart';
import 'package:sparewo_client/features/home/presentation/home_screen.dart';
import 'package:sparewo_client/features/catalog/presentation/catalog_screen.dart';
import 'package:sparewo_client/features/catalog/presentation/product_detail_screen.dart';
import 'package:sparewo_client/features/cart/presentation/cart_screen.dart';
import 'package:sparewo_client/features/cart/presentation/checkout_screen.dart';
import 'package:sparewo_client/features/cart/domain/checkout_buy_now_args.dart';
import 'package:sparewo_client/features/autohub/presentation/autohub_intro_screen.dart';
import 'package:sparewo_client/features/autohub/presentation/autohub_conversational.dart';
import 'package:sparewo_client/features/profile/presentation/profile_screen.dart';
import 'package:sparewo_client/features/my_car/presentation/my_cars_screen.dart';
import 'package:sparewo_client/features/my_car/presentation/add_car_screen.dart';
import 'package:sparewo_client/features/my_car/presentation/car_detail_screen.dart';
import 'package:sparewo_client/features/orders/presentation/orders_screen.dart';
import 'package:sparewo_client/features/orders/presentation/order_detail_screen.dart';
import 'package:sparewo_client/features/addresses/presentation/addresses_screen.dart';
import 'package:sparewo_client/features/wishlist/presentation/wishlist_screen.dart';
import 'package:sparewo_client/features/profile/presentation/settings_screen.dart';
import 'package:sparewo_client/features/profile/presentation/support_screen.dart';
import 'package:sparewo_client/features/profile/presentation/about_screen.dart';
import 'package:sparewo_client/features/notifications/presentation/notifications_screen.dart';
// Added Imports
import 'package:sparewo_client/features/autohub/domain/service_booking_model.dart';
import 'package:sparewo_client/features/orders/presentation/booking_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final hasSeenWelcomeProvider = NotifierProvider<HasSeenWelcomeNotifier, bool>(
  HasSeenWelcomeNotifier.new,
);

class HasSeenWelcomeNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void completeWelcome() => state = true;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshStream(
    ref.read(authRepositoryProvider).authStateChanges,
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final returnTo = state.uri.queryParameters['returnTo'];
          final partial = state.uri.queryParameters['partial'] == '1';
          return EmailVerificationScreen(
            email: email,
            returnTo: returnTo,
            isPartialOnboarding: partial,
          );
        },
      ),

      // ShellRoute for screens with the bottom navigation bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/catalog',
                builder: (context, state) {
                  final category = state.uri.queryParameters['category'];
                  final search = state.uri.queryParameters['search'];
                  return CatalogScreen(category: category, search: search);
                },
                routes: [
                  GoRoute(
                    path: 'product/:id',
                    builder: (context, state) {
                      final productId = state.pathParameters['id']!;
                      return ProductDetailScreen(productId: productId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/autohub',
                builder: (context, state) => const AutoHubIntroScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Top-level routes
      GoRoute(
        path: '/product/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ProductDetailScreen(productId: productId);
        },
      ),
      GoRoute(
        path: '/cart',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final buyNowArgs = state.extra is CheckoutBuyNowArgs
              ? state.extra as CheckoutBuyNowArgs
              : null;
          return CheckoutScreen(buyNowArgs: buyNowArgs);
        },
      ),
      GoRoute(
        path: '/my-cars',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyCarsScreen(),
      ),
      GoRoute(
        path: '/my-cars/detail/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final carId = state.pathParameters['id']!;
          return CarDetailScreen(carId: carId);
        },
      ),
      GoRoute(
        path: '/add-car',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final carToEdit = state.extra as dynamic;
          return AddCarScreen(carToEdit: carToEdit);
        },
      ),
      GoRoute(
        path: '/autohub/booking',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AutoHubConversationalScreen(),
      ),

      // Profile Sub-routes
      GoRoute(
        path: '/orders',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/order/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          // FIX: Successfully cast to Map to prevent 'undefined class' errors
          final orderMap = state.extra as Map<String, dynamic>?;
          return OrderDetailScreen(orderId: orderId, initialOrder: orderMap);
        },
      ),
      // NEW: Booking detail route
      GoRoute(
        path: '/booking/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final bookingId = state.pathParameters['id']!;
          final initialBooking = state.extra as ServiceBooking?;
          return BookingDetailScreen(
            bookingId: bookingId,
            initialBooking: initialBooking,
          );
        },
      ),
      GoRoute(
        path: '/addresses',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/wishlist',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/support',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/about',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateChangesProvider);
      final hasSeenWelcome = ref.read(hasSeenWelcomeProvider);
      final user = authState.hasValue ? authState.value : null;
      final location = state.matchedLocation;
      final isAuthRoute =
          location == '/welcome' ||
          location == '/login' ||
          location == '/signup' ||
          location.startsWith('/verify-email');

      // Only gate redirects on Firebase auth stream readiness.
      // Profile loading can lag and is not part of GoRouter refreshListenable.
      final isLoading = authState.isLoading;

      final isLoggedIn = user != null;

      // -----------------------------------------------------------------------
      // 1. Loading State
      // -----------------------------------------------------------------------
      if (isLoading) {
        // Avoid route thrash during transient auth transitions
        // (e.g. incomplete-login signIn -> signOut checks).
        return null;
      }

      // -----------------------------------------------------------------------
      // 2. Web Entry Point (Skip Splash/Welcome)
      // -----------------------------------------------------------------------
      if (kIsWeb && location == '/splash') {
        // On Web, we want instant entry.
        // If logged in -> Home (or let router handle it)
        // If guest -> Home
        return '/home';
      }

      // -----------------------------------------------------------------------
      // 3. Mobile Entry Point (Splash -> Welcome -> Login/Home)
      // -----------------------------------------------------------------------
      if (!kIsWeb && location == '/splash') {
        // If user hasn't seen onboarding, show it
        if (!hasSeenWelcome) {
          return '/welcome';
        }
        // After onboarding, unauthenticated users continue to signup/login flow.
        // Do not skip directly to Home, otherwise onboarding "Get Started" feels bypassed.
        return isLoggedIn ? '/home' : '/signup';
      }

      // -----------------------------------------------------------------------
      // 4. Protected Routes vs Public Routes
      // -----------------------------------------------------------------------
      // -----------------------------------------------------------------------
      // 5. Logged In Logic
      // -----------------------------------------------------------------------
      if (isLoggedIn) {
        // If user is logged in but on an auth screen (login/signup), send to Home
        if (isAuthRoute) {
          return '/home';
        }
        return null; // Proceed as requested
      }

      // -----------------------------------------------------------------------
      // 6. Guest Logic (Not Logged In)
      // -----------------------------------------------------------------------
      if (!isLoggedIn) {
        // If on an Auth route, allow it
        if (isAuthRoute) {
          return null;
        }

        final requiresAuth =
            location == '/orders' ||
            location.startsWith('/order/') ||
            location.startsWith('/booking/') ||
            location == '/my-cars' ||
            location.startsWith('/my-cars/') ||
            location == '/addresses' ||
            location == '/wishlist' ||
            location == '/add-car' ||
            location.startsWith('/add-car');

        if (requiresAuth) {
          final encodedReturnTo = Uri.encodeComponent(state.uri.toString());
          return '/login?returnTo=$encodedReturnTo&reason=auth_required';
        }

        // Default: Allow public access (Home, Catalog, Cart, AutoHub Intro)
        return null;
      }

      return null;
    },
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
