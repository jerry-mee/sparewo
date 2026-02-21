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
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';
import 'package:sparewo_client/features/auth/presentation/widgets/auth_guard_modal.dart';

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

    return ResponsiveScreen(
      mobile: Scaffold(
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
          physics: const ClampingScrollPhysics(),
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
                  activeThumbColor: AppColors.primary,
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

            _buildSectionHeader(context, isLoggedIn ? 'Security' : 'Account'),
            if (isLoggedIn)
              _buildSettingContainer(
                context,
                children: [
                  _buildListTile(
                    context,
                    title: 'Change Password',
                    icon: Icons.lock_outline,
                    onTap: () async {
                      try {
                        final email = ref
                            .read(currentUserProvider)
                            .asData
                            ?.value
                            ?.email;
                        if (email == null) throw Exception('Email not found');
                        await ref
                            .read(authNotifierProvider.notifier)
                            .sendPasswordResetEmail(email: email);
                        if (context.mounted) {
                          _showSuccess(context, 'Password reset email sent');
                        }
                      } catch (e) {
                        if (context.mounted) _showError(context, e.toString());
                      }
                    },
                  ),
                  Divider(
                    height: 1,
                    indent: 60,
                    color: theme.dividerColor.withValues(alpha: 0.5),
                  ),
                  _buildListTile(
                    context,
                    title: _isGoogleLinked
                        ? 'Google Account Linked'
                        : 'Link Google Account',
                    icon: Icons.link,
                    enabled: !_isGoogleLinked,
                    trailing: _isGoogleLinked
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                          )
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
                          setState(() {});
                        }
                      } catch (e) {
                        if (context.mounted) _showError(context, e.toString());
                      }
                    },
                  ),
                ],
              )
            else
              _buildGuestSecurityPrompt(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
      desktop: DesktopScaffold(
        widthTier: DesktopWidthTier.standard,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DesktopSection(
                title: 'Settings',
                subtitle: 'Appearance, notifications, and security controls',
                padding: EdgeInsets.only(top: 28, bottom: 12),
                child: SizedBox.shrink(),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildDesktopGroup(context, 'Appearance', [
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
                        activeThumbColor: AppColors.primary,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        onChanged: (value) {
                          ref
                              .read(themeModeProvider.notifier)
                              .toggleDarkMode(value);
                        },
                      ),
                    ]),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildDesktopGroup(context, 'Notifications', [
                          _buildListTile(
                            context,
                            title: 'Push Notification Settings',
                            subtitle: 'Manage system notification permissions',
                            icon: Icons.notifications_active_outlined,
                            onTap: _openNotificationSettings,
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildDesktopGroup(
                          context,
                          isLoggedIn ? 'Security' : 'Account',
                          isLoggedIn
                              ? [
                                  _buildListTile(
                                    context,
                                    title: 'Change Password',
                                    icon: Icons.lock_outline,
                                    onTap: () async {
                                      try {
                                        final email = ref
                                            .read(currentUserProvider)
                                            .asData
                                            ?.value
                                            ?.email;
                                        if (email == null) {
                                          throw Exception('Email not found');
                                        }
                                        await ref
                                            .read(authNotifierProvider.notifier)
                                            .sendPasswordResetEmail(
                                              email: email,
                                            );
                                        if (context.mounted) {
                                          _showSuccess(
                                            context,
                                            'Password reset email sent',
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          _showError(context, e.toString());
                                        }
                                      }
                                    },
                                  ),
                                  Divider(
                                    height: 1,
                                    indent: 60,
                                    color: theme.dividerColor.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  _buildListTile(
                                    context,
                                    title: _isGoogleLinked
                                        ? 'Google Account Linked'
                                        : 'Link Google Account',
                                    icon: Icons.link,
                                    enabled: !_isGoogleLinked,
                                    trailing: _isGoogleLinked
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: AppColors.success,
                                          )
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
                                          setState(() {});
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          _showError(context, e.toString());
                                        }
                                      }
                                    },
                                  ),
                                ]
                              : [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      16,
                                    ),
                                    child: _buildGuestSecurityPrompt(
                                      context,
                                      embedded: true,
                                    ),
                                  ),
                                ],
                        ),
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
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDesktopGroup(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.cardShadow,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              title.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: theme.hintColor,
                letterSpacing: 1.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildGuestSecurityPrompt(
    BuildContext context, {
    bool embedded = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: embedded
            ? theme.scaffoldBackgroundColor
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Unlock account security options',
                  style: AppTextStyles.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Log in to manage password recovery and connected sign-in providers.',
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.hintColor,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              AuthGuardModal.check(
                context: context,
                ref: ref,
                title: 'Log in for account controls',
                message:
                    'Sign in to access security settings and connected accounts.',
                onAuthenticated: () {},
              );
            },
            icon: const Icon(Icons.login),
            label: const Text('Log in / Register'),
          ),
        ],
      ),
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
