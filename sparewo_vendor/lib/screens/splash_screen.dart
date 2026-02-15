// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_vendor/routes/app_router.dart';
import '../constants/enums.dart';
import '../providers/providers.dart';
import '../theme.dart';
import 'dart:async';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay the auth check to ensure providers are ready
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(authNotifierProvider.notifier).checkCurrentUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthStatus>(authNotifierProvider.select((s) => s.status),
        (previous, next) {
      // Avoid duplicate navigation
      if (previous == next ||
          next == AuthStatus.initial ||
          next == AuthStatus.loading) return;

      Timer(const Duration(milliseconds: 200), () {
        if (!mounted) return;

        String? routeName;
        switch (next) {
          case AuthStatus.authenticated:
            routeName = AppRouter.dashboard;
            break;
          case AuthStatus.unverified:
            routeName = AppRouter.emailVerification;
            break;
          case AuthStatus.unauthenticated:
          case AuthStatus.onboardingRequired:
          case AuthStatus.error:
          case AuthStatus.needsReauthentication:
            routeName = AppRouter.login;
            break;
          default:
            break;
        }

        if (routeName != null) {
          Navigator.pushNamedAndRemoveUntil(
              context, routeName, (route) => false);
        }
      });
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo/splash_logo.png',
                width: 150,
                errorBuilder: (_, __, ___) => const Icon(Icons.car_repair,
                    size: 100, color: Colors.white)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
          ],
        ),
      ),
    );
  }
}
