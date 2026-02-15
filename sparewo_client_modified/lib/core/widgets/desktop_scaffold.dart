import 'package:flutter/material.dart';
import 'package:sparewo_client/core/widgets/desktop_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:sparewo_client/core/widgets/desktop_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
export 'package:sparewo_client/core/widgets/desktop_layout.dart';

class DesktopScaffold extends StatelessWidget {
  final Widget child;
  final DesktopWidthTier widthTier;
  final bool extendBehindNav;
  final double navHeight;
  final StatefulNavigationShell? navigationShell;
  final bool useLayout;
  final bool showWhatsApp;

  const DesktopScaffold({
    super.key,
    required this.child,
    this.widthTier = DesktopWidthTier.standard,
    this.extendBehindNav = false,
    this.navHeight = DesktopWebScale.navHeight,
    this.navigationShell,
    this.useLayout = true,
    this.showWhatsApp = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: extendBehindNav,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: extendBehindNav ? 0 : navHeight),
              child: useLayout
                  ? DesktopLayout(tier: widthTier, child: child)
                  : child,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DesktopNavBar(navigationShell: navigationShell),
          ),
          if (showWhatsApp)
            const Positioned(right: 32, bottom: 32, child: _WhatsAppButton()),
        ],
      ),
    );
  }
}

class _WhatsAppButton extends StatelessWidget {
  const _WhatsAppButton();

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse('https://wa.me/256773276096');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'WhatsApp (7am–9pm)',
      child: InkWell(
        onTap: _launchWhatsApp,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'WhatsApp',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
