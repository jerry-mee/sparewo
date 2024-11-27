import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/onboarding_screen.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('🚀 SplashScreen initialized');
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    debugPrint('🔄 Starting navigation delay...');

    try {
      // Wait for auth provider to initialize
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      debugPrint('✅ AuthProvider accessed');

      // Add a small delay for smooth transition
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('✅ Navigation delay complete');

      if (!mounted) {
        debugPrint('❌ Widget not mounted after delay');
        return;
      }

      debugPrint('🔄 Navigating to OnboardingScreen...');
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            debugPrint('🏗️ Building OnboardingScreen');
            return const OnboardingScreen();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
      debugPrint('✅ Navigation completed');
    } catch (e, stackTrace) {
      debugPrint('❌ Error during navigation: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ Building SplashScreen');

    return Scaffold(
      backgroundColor: const Color(0xFF1A1B4B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo/splash_logo.png',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Error loading logo: $error');
                return const Icon(Icons.error_outline, size: 100);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              '© Est. 2016, SpareWo',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
