// lib/features/auth/presentation/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/router/app_router.dart';
import 'package:sparewo_client/core/widgets/desktop_layout.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Brand background for immersive feel
    const backgroundColor = Color(0xFF1A1B4B);

    return ResponsiveScreen(
      mobile: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Image.asset(
                  'assets/logo/splash_logo.png',
                  height: 120,
                ).animate().fadeIn(duration: 800.ms).scale(),
                const SizedBox(height: 40),
                Text(
                  'Your Car Deserves\nThe Best Care',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displaySmall.copyWith(
                    color: Colors.white,
                    height: 1.2,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 16),
                Text(
                  'Genuine parts and professional services\ndelivered to your garage.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 500.ms),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      ref
                          .read(hasSeenWelcomeProvider.notifier)
                          .completeWelcome();
                      context.go('/signup');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 8,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
      desktop: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: DesktopLayout(
            tier: DesktopWidthTier.wide,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: AppShadows.cardShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/logo/splash_logo.png',
                            height: 90,
                          ).animate().fadeIn(duration: 800.ms).scale(),
                          const SizedBox(height: 28),
                          Text(
                            'Your Car Deserves\nThe Best Care',
                            style: AppTextStyles.desktopH1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Genuine parts and professional services delivered to your garage.',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              FilledButton(
                                onPressed: () {
                                  ref
                                      .read(hasSeenWelcomeProvider.notifier)
                                      .completeWelcome();
                                  context.go('/signup');
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('Get Started'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/banner_home.webp',
                          fit: BoxFit.cover,
                          height: 420,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
