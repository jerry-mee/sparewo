// lib/features/auth/presentation/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
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
