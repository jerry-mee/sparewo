// lib/features/profile/presentation/about_screen.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';
import 'package:sparewo_client/features/shared/widgets/legal_modal.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final theme = Theme.of(context);

    return ResponsiveScreen(
      mobile: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('About SpareWo')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 24),
                Text('SpareWo Client', style: AppTextStyles.h2),
                const SizedBox(height: 8),
                Text(
                  'Version $_version ($_buildNumber)',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'The easiest way to find authentic car parts and book professional services in Uganda.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: 48),
                _buildInfoRow(context, 'Terms of Service'),
                const Divider(),
                _buildInfoRow(context, 'Privacy Policy'),
                const Divider(),
                _buildInfoRow(context, 'Licenses'),
                const SizedBox(height: 48),
                Text(
                  '© $year SpareWo Ltd. All rights reserved.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      desktop: DesktopScaffold(
        widthTier: DesktopWidthTier.standard,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DesktopSection(
                title: 'About SpareWo',
                subtitle: 'Product information and legal resources',
                padding: EdgeInsets.only(top: 28, bottom: 8),
                child: SizedBox.shrink(),
              ),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.4),
                  ),
                  boxShadow: AppShadows.cardShadow,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogo(size: 110),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SpareWo Client',
                            style: AppTextStyles.desktopH2,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Version $_version ($_buildNumber)',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'The easiest way to find authentic car parts and book professional services in Uganda.',
                            style: AppTextStyles.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(context, 'Terms of Service'),
                          const Divider(),
                          _buildInfoRow(context, 'Privacy Policy'),
                          const Divider(),
                          _buildInfoRow(context, 'Licenses'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SiteFooter(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo({double size = 120}) {
    return Image.asset(
      'assets/logo/sparewo_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.directions_car, size: 80, color: AppColors.primary),
    );
  }

  Widget _buildInfoRow(BuildContext context, String title) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        if (title == 'Terms of Service') {
          LegalModal.showTermsAndConditions(context);
        } else if (title == 'Privacy Policy') {
          LegalModal.showPrivacyPolicy(context);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.bodyMedium),
            Icon(
              Icons.chevron_right,
              color: theme.iconTheme.color?.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
