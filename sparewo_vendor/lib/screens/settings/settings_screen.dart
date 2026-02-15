// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_vendor/routes/app_router.dart';
import '../../models/vendor.dart';
import '../../providers/providers.dart';
import '../../theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FIX: The provider returns a boolean (isDarkMode), not a ThemeMode.
    final isDarkMode = ref.watch(themeNotifierProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final vendor = ref.watch(currentVendorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          if (vendor != null) _buildProfileCard(context, vendor),
          const SizedBox(height: 8),
          _buildSectionHeader(context, 'Preferences'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            // FIX: The icon should depend on the boolean state.
            secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            value: isDarkMode,
            onChanged: (value) {
              // FIX: The notifier has a 'toggleTheme' method, not 'setTheme'.
              themeNotifier.toggleTheme();
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notification Settings'),
            onTap: () {
              // This is a placeholder, no error here.
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: const Icon(Icons.store_outlined),
            title: const Text('Store Information'),
            onTap: () => Navigator.pushNamed(context, AppRouter.storeSettings),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            onTap: () {
              // This is a placeholder, no error here.
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: const Text('Support'),
            onTap: () {
              // This is a placeholder, no error here.
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About SpareWo'),
            onTap: () {
              // This is a placeholder, no error here.
            },
          ),
          const Divider(),
          ListTile(
            leading:
                Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Logout',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _logout(context, ref),
          ),
        ],
      ),
    );
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

    if (confirmed && context.mounted) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.splash,
          (route) => false,
        );
      }
    }
  }

  Widget _buildProfileCard(BuildContext context, Vendor vendor) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRouter.profile),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).cardColor,
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
              child: Text(
                vendor.businessName.isNotEmpty
                    ? vendor.businessName[0].toUpperCase()
                    : 'S',
                style: TextStyle(
                    fontSize: 24, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.businessName,
                    style: Theme.of(context).textTheme.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View and edit profile',
                    // FIX: Use the correct Material 3 TextTheme property.
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        // FIX: Use the correct Material 3 TextTheme property.
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
