// lib/features/profile/presentation/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/theme/theme_mode_provider.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    AppLogger.ui('SettingsScreen', 'Viewed settings');
  }

  // --- Logic to check Linked Accounts ---
  bool get _isGoogleLinked {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'google.com');
  }

  // --- Logic to open System Settings ---
  Future<void> _openNotificationSettings() async {
    AppLogger.ui('Settings', 'Opened system notification settings');
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final bool isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final authState = ref.watch(currentUserProvider);
    final isLoggedIn = authState.asData?.value != null;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: theme.iconTheme.color,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          _buildSectionHeader(context, 'Appearance'),
          _buildSettingContainer(
            context,
            children: [
              SwitchListTile(
                title: Text(
                  'Dark Mode',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Switch between light and dark theme',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                value: isDark,
                activeColor: AppColors.primary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                onChanged: (value) {
                  ref.read(themeModeProvider.notifier).toggleDarkMode(value);
                  AppLogger.ui(
                    'SettingsScreen',
                    'Toggled dark mode',
                    details: 'Value: $value',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Notifications'),
          _buildSettingContainer(
            context,
            children: [
              _buildListTile(
                context,
                title: 'Push Notification Settings',
                subtitle: 'Manage system notification permissions',
                icon: Icons.notifications_active_outlined,
                onTap: _openNotificationSettings, // Wired up
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Security'),
          _buildSettingContainer(
            context,
            children: [
              _buildListTile(
                context,
                title: 'Change Password',
                icon: Icons.lock_outline,
                onTap: () async {
                  if (!isLoggedIn) {
                    _showError(context, 'Please sign in first');
                    return;
                  }
                  try {
                    await ref
                        .read(authNotifierProvider.notifier)
                        .sendPasswordResetEmail();
                    if (context.mounted)
                      _showSuccess(context, 'Password reset email sent');
                  } catch (e) {
                    if (context.mounted) _showError(context, e.toString());
                  }
                },
              ),
              Divider(
                height: 1,
                indent: 60,
                color: theme.dividerColor.withOpacity(0.5),
              ),
              // --- SMART GOOGLE LINKING LOGIC ---
              _buildListTile(
                context,
                title: _isGoogleLinked
                    ? 'Google Account Linked'
                    : 'Link Google Account',
                icon: Icons.link,
                enabled:
                    !_isGoogleLinked &&
                    isLoggedIn, // Disabled if already linked
                trailing: _isGoogleLinked
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : null,
                onTap: () async {
                  try {
                    await ref
                        .read(authNotifierProvider.notifier)
                        .linkGoogleAccount();
                    if (context.mounted) {
                      _showSuccess(
                        context,
                        'Google account linked successfully',
                      );
                      setState(() {}); // Refresh UI
                    }
                  } catch (e) {
                    if (context.mounted) _showError(context, e.toString());
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: Theme.of(context).hintColor,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingContainer(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: ListTile(
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(color: theme.hintColor),
              )
            : null,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        trailing:
            trailing ??
            Icon(Icons.chevron_right, size: 20, color: theme.hintColor),
        onTap: enabled ? onTap : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }
}
