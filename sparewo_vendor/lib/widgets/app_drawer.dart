// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_vendor/routes/app_router.dart';
import '../providers/providers.dart';
import '../theme.dart';
import 'notification_badge.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final vendor = authState.vendor;
    final isAdmin = authState.isAdmin;
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    // FIX: Get the current route name once here for efficiency.
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      child: Column(
        children: [
          _buildHeader(context, vendor?.businessName ?? 'SpareWo Vendor',
              vendor?.email ?? ''),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildListTile(
                  context: context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  onTap: () => _navigateTo(context, AppRouter.dashboard),
                  selected: currentRoute == AppRouter.dashboard,
                ),
                _buildListTile(
                  context: context,
                  icon: Icons.inventory_2_outlined,
                  title: 'Products',
                  onTap: () => _navigateTo(context, AppRouter.products),
                  selected: currentRoute == AppRouter.products,
                ),
                _buildListTile(
                  context: context,
                  icon: Icons.shopping_cart_outlined,
                  title: 'Orders',
                  onTap: () => _navigateTo(context, AppRouter.orders),
                  selected: currentRoute == AppRouter.orders,
                ),
                _buildListTile(
                    context: context,
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () => _navigateTo(context, AppRouter.notifications),
                    selected: currentRoute == AppRouter.notifications,
                    trailing: unreadCountAsync.when(
                      data: (unread) => unread > 0
                          ? NotificationBadge(count: unread)
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => Icon(Icons.error_outline,
                          color: Theme.of(context).colorScheme.error, size: 20),
                    )),
                const Divider(),
                _buildListTile(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => _navigateTo(context, AppRouter.settings),
                  selected: currentRoute == AppRouter.settings,
                ),
                if (isAdmin) ...[
                  const Divider(),
                  _buildSection(context, 'Admin'), // FIX: Pass context
                  _buildListTile(
                    context: context,
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Admin Panel',
                    onTap: () => _navigateTo(context, AppRouter.adminPanel),
                    selected: currentRoute == AppRouter.adminPanel,
                  ),
                ],
                const Divider(),
                _buildListTile(
                  context: context,
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () => _logout(context, ref),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildVersionInfo(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String email) {
    return UserAccountsDrawerHeader(
      accountName: Text(name,
          style: Theme.of(context)
              .textTheme
              .headlineSmall!
              .copyWith(color: Colors.white)),
      accountEmail: Text(email,
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: Colors.white70)),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: TextStyle(
              fontSize: 40.0, color: Theme.of(context).colorScheme.primary),
        ),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context, // FIX: Pass context explicitly
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: selected ? FontWeight.bold : null,
        ),
      ),
      trailing: trailing,
      selected: selected,
      selectedTileColor: colorScheme.primary.withOpacity(0.1),
      onTap: onTap,
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    // FIX: Pass context
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'SpareWo Vendor v1.0.0',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.pop(context); // Close drawer
    if (ModalRoute.of(context)?.settings.name != route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        // FIX: Use named route for navigation after logout
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRouter.splash, (route) => false);
      }
    }
  }
}
