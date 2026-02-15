// lib/features/auth/presentation/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/core/router/app_router.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Minimum splash display time for branding
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Note: GoRouter's redirect logic usually handles this automatically based on the stream,
    // but we check here to force navigation after the delay if the router hasn't already moved us.
    final authState = ref.read(authStateChangesProvider);
    final hasSeenWelcome = ref.read(hasSeenWelcomeProvider);

    // If Riverpod is still initializing the auth stream, wait a bit
    if (authState.isLoading || authState.isRefreshing) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted) return;

    // Check current state
    // We check the actual value inside the AsyncValue
    final user = authState.value;
    final isLoggedIn = user != null;

    if (isLoggedIn) {
      context.go('/home');
    } else if (!hasSeenWelcome) {
      context.go('/welcome');
    } else {
      context.go('/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final splash = Scaffold(
      // Navy blue background matching the brand
      backgroundColor: const Color(0xFF1A1B4B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo/splash_logo.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if asset is missing, styled for the dark background
                return const Icon(
                  Icons.directions_car,
                  size: 100,
                  color: Colors.white,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              '© Est. 2016, SpareWo',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    return ResponsiveScreen(mobile: splash, desktop: splash);
  }
}
