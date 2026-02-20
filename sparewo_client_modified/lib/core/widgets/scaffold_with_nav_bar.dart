// lib/core/widgets/scaffold_with_nav_bar.dart
import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIOS = theme.platform == TargetPlatform.iOS;
    final isAuthenticated =
        ref.watch(authStateChangesProvider).asData?.value != null;

    // Hide nav bar on specific high-focus screens
    if (location.startsWith('/product/') ||
        location == '/checkout' ||
        location == '/cart' ||
        location == '/autohub/booking') {
      return navigationShell;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          return DesktopScaffold(
            navigationShell: navigationShell,
            useLayout: false,
            child: navigationShell,
          );
        }

        // ---------------------------------------------------------------------
        // MOBILE LAYOUT (Bottom Nav)
        // ---------------------------------------------------------------------
        final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
        final horizontalInset = isIOS ? 18.0 : 14.0;
        final floatingBottom = bottomInset > 0
            ? bottomInset + (isIOS ? 6.0 : 4.0)
            : (isIOS ? 12.0 : 10.0);
        final cornerRadius = isIOS ? 999.0 : 999.0;
        final dockHeight = isIOS ? 74.0 : 70.0;
        final iconColor = isDark
            ? const Color(0xFFAFB7C6)
            : const Color(0xFF7B879A);

        return Scaffold(
          // Critical: extendsBody allows content to scroll BEHIND the bottom bar
          extendBody: true,
          body: navigationShell,
          bottomNavigationBar: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalInset,
              0,
              horizontalInset,
              floatingBottom,
            ),
            child: SizedBox(
              height: dockHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cornerRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1D2C49).withValues(alpha: 0.82)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(cornerRadius),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.14)
                            : Colors.black.withValues(alpha: 0.08),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDockItem(
                          icon: Icons.home_outlined,
                          selectedIcon: Icons.home_rounded,
                          isActive: navigationShell.currentIndex == 0,
                          inactiveColor: iconColor,
                          onTap: () =>
                              _onItemTapped(context, 0, isAuthenticated),
                        ),
                        _buildDockItem(
                          icon: Icons.grid_view_outlined,
                          selectedIcon: Icons.grid_view_rounded,
                          isActive: navigationShell.currentIndex == 1,
                          inactiveColor: iconColor,
                          onTap: () =>
                              _onItemTapped(context, 1, isAuthenticated),
                        ),
                        _buildDockItem(
                          icon: Icons.garage_outlined,
                          selectedIcon: Icons.garage_rounded,
                          isActive: navigationShell.currentIndex == 2,
                          inactiveColor: iconColor,
                          onTap: () =>
                              _onItemTapped(context, 2, isAuthenticated),
                        ),
                        _buildDockItem(
                          icon: isAuthenticated
                              ? Icons.person_outline
                              : Icons.settings_outlined,
                          selectedIcon: isAuthenticated
                              ? Icons.person_rounded
                              : Icons.settings_rounded,
                          isActive: navigationShell.currentIndex == 3,
                          inactiveColor: iconColor,
                          onTap: () =>
                              _onItemTapped(context, 3, isAuthenticated),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDockItem({
    required IconData icon,
    required IconData selectedIcon,
    required bool isActive,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 76,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 38,
              width: isActive ? 66 : 44,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Icon(
                isActive ? selectedIcon : icon,
                color: isActive ? AppColors.primary : inactiveColor,
                size: isActive ? 24 : 23,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index, bool isAuthenticated) {
    HapticFeedback.selectionClick();

    // Guests should access app settings from the last tab instead of profile.
    if (!isAuthenticated && index == 3) {
      context.go('/settings');
      return;
    }

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
