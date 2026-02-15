// lib/features/autohub/presentation/autohub_intro_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/widgets/desktop_layout.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';

class AutoHubIntroScreen extends ConsumerWidget {
  const AutoHubIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ResponsiveScreen(
      mobile: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildMobileHeader(context, theme),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildHeroImage(height: 320),
                      const SizedBox(height: 32),
                      _buildHeadline(context, center: true, isDesktop: false),
                      const SizedBox(height: 16),
                      _buildBodyCopy(context, center: true),
                      const SizedBox(height: 40),
                      _buildQuickFeaturesRow(context),
                      const SizedBox(height: 48),
                      _buildPrimaryCta(context, fullWidth: true),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      desktop: SingleChildScrollView(
        child: DesktopLayout(
          tier: DesktopWidthTier.wide,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DesktopSection(
                title: 'SpareWo AutoHub',
                subtitle: 'Book trusted mechanics at your doorstep',
                padding: EdgeInsets.only(top: 28, bottom: 16),
                child: SizedBox.shrink(),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: _buildHeroImage(height: 430)),
                  const SizedBox(width: 36),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeadline(context, center: false, isDesktop: true),
                        const SizedBox(height: 12),
                        _buildBodyCopy(context, center: false),
                        const SizedBox(height: 24),
                        _buildQuickFeaturesRow(context),
                        const SizedBox(height: 28),
                        _buildPrimaryCta(context, fullWidth: false),
                      ],
                    ),
                  ),
                ],
              ),
              const SiteFooter(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: Icon(Icons.close, color: theme.iconTheme.color),
            style: IconButton.styleFrom(
              backgroundColor: theme.cardColor,
              padding: const EdgeInsets.all(8),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Premium Care',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage({required double height}) {
    return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppShadows.cardShadow,
            image: const DecorationImage(
              image: AssetImage('assets/images/Request Service.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildHeadline(
    BuildContext context, {
    required bool center,
    required bool isDesktop,
  }) {
    return Text(
      'Expert Care,\nRight to You.',
      style: AppTextStyles.displaySmall.copyWith(
        fontSize: isDesktop ? 56 : null,
        fontWeight: FontWeight.w900,
        height: 1.1,
      ),
      textAlign: center ? TextAlign.center : TextAlign.left,
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildBodyCopy(BuildContext context, {required bool center}) {
    final theme = Theme.of(context);
    return Text(
      'Skip the garage visits. We pick up, service, and deliver your vehicle so you can keep moving.',
      style: AppTextStyles.bodyLarge.copyWith(
        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
        height: 1.5,
      ),
      textAlign: center ? TextAlign.center : TextAlign.left,
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildQuickFeaturesRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickFeature(context, Icons.speed, 'Fast', delay: 400),
        _buildDivider(context, delay: 450),
        _buildQuickFeature(context, Icons.security, 'Secure', delay: 500),
        _buildDivider(context, delay: 550),
        _buildQuickFeature(context, Icons.verified, 'Vetted', delay: 600),
      ],
    );
  }

  Widget _buildPrimaryCta(BuildContext context, {required bool fullWidth}) {
    return SizedBox(
      width: fullWidth ? double.infinity : 220,
      child: FilledButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push('/autohub/booking');
        },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size(0, 58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 8,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Start Request'), SizedBox(width: 8)],
        ),
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildQuickFeature(
    BuildContext context,
    IconData icon,
    String label, {
    required int delay,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            shape: BoxShape.circle,
            boxShadow: AppShadows.buttonShadow
                .map(
                  (s) => BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                )
                .toList(),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    ).animate().fadeIn(delay: delay.ms).scale();
  }

  Widget _buildDivider(BuildContext context, {required int delay}) {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
    ).animate().fadeIn(delay: delay.ms);
  }
}
