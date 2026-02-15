// lib/features/profile/presentation/support_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScreen(
      mobile: Scaffold(
        appBar: AppBar(title: const Text('Help & Support')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              _buildSupportHero(context, isDesktop: false),
              const SizedBox(height: 32),
              _buildSupportOption(
                context: context,
                icon: Icons.phone_outlined,
                title: 'Call Us',
                subtitle: '0773 276 096',
                onTap: () => _launchUrl('tel:+256773276096'),
              ),
              const SizedBox(height: 16),
              _buildSupportOption(
                context: context,
                icon: Icons.email_outlined,
                title: 'Email Us',
                subtitle: 'garage@sparewo.ug',
                onTap: () => _launchUrl('mailto:garage@sparewo.ug'),
              ),
              const SizedBox(height: 16),
              _buildSupportOption(
                context: context,
                icon: Icons.chat_bubble_outline,
                title: 'WhatsApp',
                subtitle: 'Chat on WhatsApp',
                onTap: () => _launchUrl('https://wa.me/256773276096'),
              ),
            ],
          ),
        ),
      ),
      desktop: DesktopScaffold(
        widthTier: DesktopWidthTier.standard,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DesktopSection(
                title: 'Help & Support',
                subtitle: 'We are available Mon-Sat, 8am - 6pm',
                padding: const EdgeInsets.only(top: 28, bottom: 8),
                child: _buildSupportHero(context, isDesktop: true),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 2.2,
                children: [
                  _buildSupportOption(
                    context: context,
                    icon: Icons.phone_outlined,
                    title: 'Call Us',
                    subtitle: '0773 276 096',
                    onTap: () => _launchUrl('tel:+256773276096'),
                  ),
                  _buildSupportOption(
                    context: context,
                    icon: Icons.email_outlined,
                    title: 'Email Us',
                    subtitle: 'garage@sparewo.ug',
                    onTap: () => _launchUrl('mailto:garage@sparewo.ug'),
                  ),
                  _buildSupportOption(
                    context: context,
                    icon: Icons.chat_bubble_outline,
                    title: 'WhatsApp',
                    subtitle: 'Chat on WhatsApp',
                    onTap: () => _launchUrl('https://wa.me/256773276096'),
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

  Widget _buildSupportHero(BuildContext context, {required bool isDesktop}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.headset_mic_outlined,
            size: 56,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'How can we help you?',
          style: isDesktop ? AppTextStyles.desktopH2 : AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Our team is ready to assist with orders, services, and support.',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSupportOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: AppColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.iconTheme.color),
        ),
        title: Text(title, style: AppTextStyles.h4),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
