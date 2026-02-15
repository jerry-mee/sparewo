// lib/core/widgets/scaffold_with_nav_bar.dart
import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Hide nav bar on specific high-focus screens
    if (location.startsWith('/product/') ||
        location == '/checkout' ||
        location == '/cart' ||
        location == '/autohub/booking') {
      return navigationShell;
    }

    return Scaffold(
      // Critical: extendsBody allows content to scroll BEHIND the bottom bar
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: ClipRRect(
          // Large rounded corners matching the "District Noir" style
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            // The blur effect
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                // Semi-transparent background color
                color: isDark
                    ? const Color(0xFF1d2c49).withOpacity(0.75)
                    : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: NavigationBar(
                height: 70,
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) => _onItemTapped(context, index),
                backgroundColor: Colors.transparent,
                indicatorColor: AppColors.primary.withOpacity(0.15),
                elevation: 0,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                destinations: [
                  _buildNavDestination(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'Home',
                    isActive: navigationShell.currentIndex == 0,
                  ),
                  _buildNavDestination(
                    icon: Icons.grid_view_outlined,
                    selectedIcon: Icons.grid_view_rounded,
                    label: 'Catalog',
                    isActive: navigationShell.currentIndex == 1,
                  ),
                  _buildNavDestination(
                    icon: Icons.build_outlined,
                    selectedIcon: Icons.build_rounded,
                    label: 'AutoHub',
                    isActive: navigationShell.currentIndex == 2,
                  ),
                  _buildNavDestination(
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person_rounded,
                    label: 'Profile',
                    isActive: navigationShell.currentIndex == 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isActive,
  }) {
    return NavigationDestination(
      icon: Icon(icon, color: Colors.grey, size: 26),
      selectedIcon: Icon(selectedIcon, color: AppColors.primary, size: 28),
      label: label,
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
