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
import 'package:sparewo_client/core/router/shared_preferences_provider.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
// Added Imports
import 'package:sparewo_client/features/autohub/domain/service_booking_model.dart';
import 'package:sparewo_client/features/orders/presentation/booking_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
GoRouter? _routerInstance;

final hasSeenWelcomeProvider = NotifierProvider<HasSeenWelcomeNotifier, bool>(
  HasSeenWelcomeNotifier.new,
);

class HasSeenWelcomeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool('hasSeenWelcome') ?? false;
  }

  void completeWelcome() {
    state = true;
    ref.read(sharedPreferencesProvider).setBool('hasSeenWelcome', true);
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  if (_routerInstance != null) {
    return _routerInstance!;
  }

  final refresh = GoRouterRefreshNotifier();
  ref.listen(authStateChangesProvider, (_, __) => refresh.trigger());
  ref.listen(currentUserProvider, (_, __) => refresh.trigger());
  ref.listen(registrationInProgressProvider, (_, __) => refresh.trigger());
  ref.listen(hasSeenWelcomeProvider, (_, __) => refresh.trigger());
  ref.onDispose(() {
    refresh.dispose();
    _routerInstance?.dispose();
    _routerInstance = null;
  });

  _routerInstance = GoRouter(
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
      final isRegistering = ref.read(registrationInProgressProvider);
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
      String redirectWithLog(String target, String reason) {
        AppLogger.debug(
          'RouterRedirect',
          reason,
          extra: {'from': location, 'to': target, 'uid': user?.uid},
        );
        return target;
      }

      // -----------------------------------------------------------------------
      // 1. Loading State
      // -----------------------------------------------------------------------
      if (isLoading) {
        // Avoid route thrash during transient auth transitions
        // (e.g. incomplete-login signIn -> signOut checks).
        return null;
      }

      if (isRegistering) {
        return null;
      }

      // -----------------------------------------------------------------------
      // 2. Web Entry Point (Skip Splash/Welcome)
      // -----------------------------------------------------------------------
      if (kIsWeb && location == '/splash') {
        // On Web, we want instant entry.
        // If logged in -> Home (or let router handle it)
        // If guest -> Home
        return redirectWithLog('/home', 'Web splash redirect');
      }

      // -----------------------------------------------------------------------
      // 3. Mobile Entry Point (Splash -> Welcome -> Login/Home)
      // -----------------------------------------------------------------------
      if (!kIsWeb && location == '/splash') {
        // If user hasn't seen onboarding, show it
        if (!hasSeenWelcome) {
          return redirectWithLog(
            '/welcome',
            'First launch onboarding redirect',
          );
        }
        // After onboarding, unauthenticated users continue to signup/login flow.
        // Do not skip directly to Home, otherwise onboarding "Get Started" feels bypassed.
        return redirectWithLog(
          isLoggedIn ? '/home' : '/signup',
          'Mobile splash redirect',
        );
      }

      // -----------------------------------------------------------------------
      // 4. Protected Routes vs Public Routes
      // -----------------------------------------------------------------------
      // -----------------------------------------------------------------------
      // 5. Logged In Logic
      // -----------------------------------------------------------------------
      if (isLoggedIn) {
        final profileState = ref.read(currentUserProvider);
        if (profileState.isLoading) {
          return null;
        }
        final profile = profileState.asData?.value;
        // During auth transitions, profile stream can momentarily be null/stale.
        // Suppress verification redirects until profile has caught up to auth user.
        if (profile == null || profile.id != user.uid) {
          return null;
        }
        final isVerified = profile.isEmailVerified == true;
        if (!isVerified && !location.startsWith('/verify-email')) {
          final encodedEmail = Uri.encodeComponent(user.email ?? '');
          return redirectWithLog(
            '/verify-email?email=$encodedEmail&partial=1',
            'Unverified user blocked from non-verification routes',
          );
        }
        if (isVerified && location.startsWith('/verify-email')) {
          return redirectWithLog(
            '/home',
            'Verified user redirected away from verification route',
          );
        }
        // If user is logged in and verified but on a non-verification auth route,
        // send to Home. Unverified users must remain on /verify-email.
        if (isVerified &&
            isAuthRoute &&
            !location.startsWith('/verify-email')) {
          return redirectWithLog(
            '/home',
            'Authenticated user redirected away from auth route',
          );
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
          return redirectWithLog(
            '/login?returnTo=$encodedReturnTo&reason=auth_required',
            'Guest redirected to login for protected route',
          );
        }

        // Default: Allow public access (Home, Catalog, Cart, AutoHub Intro)
        return null;
      }

      return null;
    },
  );
  return _routerInstance!;
});

class GoRouterRefreshNotifier extends ChangeNotifier {
  void trigger() => notifyListeners();
}
