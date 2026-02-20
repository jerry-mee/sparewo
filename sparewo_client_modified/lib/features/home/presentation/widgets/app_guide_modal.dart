// lib/features/home/presentation/widgets/app_guide_modal.dart
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';

class AppGuideModal extends StatefulWidget {
  const AppGuideModal({super.key});

  @override
  State<AppGuideModal> createState() => _AppGuideModalState();
}

class _AppGuideModalState extends State<AppGuideModal> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String _onboardingKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return 'hasSeenOnboarding';
    return 'hasSeenOnboarding_$uid';
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey(), true);
    // Keep legacy key aligned for older checks.
    await prefs.setBool('hasSeenOnboarding', true);
  }

  void _onNext() {
    if (_currentPage >= 3) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _onClose() async {
    await _completeOnboarding();
    if (!mounted) return;
    context.pop();
  }

  Future<void> _onSetupCar() async {
    await _completeOnboarding();
    if (!mounted) return;
    context.pop();
    context.push('/add-car');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final pages = <_AppGuideSlide>[
      const _AppGuideSlide(
        animationAsset: 'assets/animations/maintenance_navy_orange.json',
        title: 'Order genuine parts with SpareWo',
        body:
            'Use the Parts Catalogue to find the right high-quality parts for your car. Order through SpareWo, and we arrange a professional fitting for you.',
      ),
      const _AppGuideSlide(
        animationAsset: 'assets/animations/worker_mechanic_sparewo_brand.json',
        title: 'AutoHub handles your garage visits',
        body:
            'Book a visit in AutoHub, and we\'ll take care of the rest. We organise the work on your car and return it to you safely.',
      ),
      const _AppGuideSlide(
        animationAsset: 'assets/animations/car_motorly_navy.json',
        title: 'My Car keeps your car organised',
        body:
            'Add your car in My Car to store servicing, mileage and insurance details so you never miss an important date.',
      ),
      const _AppGuideSlide(
        animationAsset: 'assets/animations/driving_sparewo_brand.json',
        title: 'Drive smarter with SpareWo',
        body:
            'Get SpareWo discounts, reminders and simple car care tips tailored to your car.',
      ),
    ];

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          // Fixed: Flexible height constraint instead of hard fixed height
          constraints: BoxConstraints(
            maxHeight: size.height * 0.85,
            minHeight: 400,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: AppShadows.floatingShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Shrink to fit if content is small
            children: [
              // Top Bar (Skip)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentPage < pages.length - 1)
                      TextButton(
                        onPressed: _onClose,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: theme.hintColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    if (index == pages.length - 1) {
                      // Custom layout for the final slide with buttons
                      return _AppGuideSlide(
                        animationAsset:
                            'assets/animations/driving_sparewo_brand.json',
                        title: 'Drive smarter with SpareWo',
                        body:
                            'Get SpareWo discounts, reminders and simple car care tips tailored to your car.',
                        primaryAction: FilledButton(
                          onPressed: _onSetupCar,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: AppColors.primary.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          child: const Text('Tell us about your car'),
                        ),
                        secondaryAction: TextButton(
                          onPressed: _onClose,
                          child: Text(
                            'Do this later',
                            style: TextStyle(color: theme.hintColor),
                          ),
                        ),
                      );
                    }
                    return pages[index];
                  },
                ),
              ),

              // Bottom Dots + Next Button (Only for first 3 slides)
              if (_currentPage < pages.length - 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: _currentPage == index ? 32 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? AppColors.primary
                                  : theme.dividerColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Next Button
                      FilledButton(
                        onPressed: _onNext,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Spacer for the last slide so content isn't flush with bottom
                const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppGuideSlide extends StatelessWidget {
  final String animationAsset;
  final String title;
  final String body;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  const _AppGuideSlide({
    required this.animationAsset,
    required this.title,
    required this.body,
    this.primaryAction,
    this.secondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation Section
          Expanded(
            flex: 4,
            child: Lottie.asset(
              animationAsset,
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
          const SizedBox(height: 24),

          // Text Content Section - Scrollable to prevent overflow
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 26,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: theme.hintColor,
                      height: 1.5,
                      fontSize: 16,
                    ),
                  ),

                  // Actions for last slide
                  if (primaryAction != null) ...[
                    const SizedBox(height: 32),
                    primaryAction!,
                  ],
                  if (secondaryAction != null) ...[
                    const SizedBox(height: 16),
                    secondaryAction!,
                  ],
                  const SizedBox(height: 16), // Bottom safety
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
