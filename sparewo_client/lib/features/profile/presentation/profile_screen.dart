// lib/features/profile/presentation/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sparewo_client/features/auth/domain/user_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    AppLogger.ui('ProfileScreen', 'Viewed profile');
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false, // Allows content to flow behind bottom nav
        child: userAsync.when(
          data: (user) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Profile', style: AppTextStyles.h2),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () => context.push('/settings'),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.cardColor,
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: theme.dividerColor.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: user == null
                      ? _buildGuestProfile(context)
                      : _buildUserProfile(context, ref, user),
                ),

                // --- FIXED PADDING ---
                // Aggressive bottom padding to clear Navigation Bar (80px) + Safety Margin
                const SliverPadding(padding: EdgeInsets.only(bottom: 160)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Error loading profile', style: AppTextStyles.h3),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestProfile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.neutral200.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              size: 80,
              color: AppColors.neutral500,
            ),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 32),
          Text('Guest Account', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          Text(
            'Sign in to access your orders, vehicles, and saved items.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          FilledButton(
            onPressed: () => context.push('/login'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Sign In / Register'),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildUserProfile(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Avatar
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name.substring(0, 1).toUpperCase()
                        : 'U',
                    style: AppTextStyles.displaySmall.copyWith(
                      color: Colors.white,
                      fontSize: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(user.name, style: AppTextStyles.h2),
              Text(
                user.email,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ).animate().fadeIn().scale(),

          const SizedBox(height: 40),

          _buildMenuSection(
            context,
            title: 'My Activity',
            items: [
              _MenuItem(
                icon: Icons.shopping_bag_outlined,
                title: 'My Orders',
                onTap: () => context.push('/orders'),
              ),
              _MenuItem(
                icon: Icons.directions_car_outlined,
                title: 'My Vehicles',
                onTap: () => context.push('/my-cars'),
              ),
              _MenuItem(
                icon: Icons.favorite_border,
                title: 'Wishlist',
                onTap: () => context.push('/wishlist'),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms).slideX(),

          const SizedBox(height: 24),

          _buildMenuSection(
            context,
            title: 'Account',
            items: [
              _MenuItem(
                icon: Icons.location_on_outlined,
                title: 'Delivery Addresses',
                onTap: () => context.push('/addresses'),
              ),
              _MenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () => context.push('/support'),
              ),
              _MenuItem(
                icon: Icons.info_outline,
                title: 'About SpareWo',
                onTap: () => context.push('/about'),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms).slideX(),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                AppLogger.auth('Logout', user.email);
                await ref.read(authNotifierProvider.notifier).signOut();
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: Text(
                'Sign Out',
                style: AppTextStyles.button.copyWith(color: AppColors.error),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.error.withOpacity(0.08),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.cardShadow,
            border: isDark
                ? Border.all(color: Colors.white.withOpacity(0.05))
                : Border.all(color: Colors.black.withOpacity(0.03)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: item.onTap,
                      borderRadius: BorderRadius.vertical(
                        top: index == 0
                            ? const Radius.circular(24)
                            : Radius.zero,
                        bottom: isLast
                            ? const Radius.circular(24)
                            : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.icon,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item.title,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: theme.hintColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 70,
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuItem({required this.icon, required this.title, required this.onTap});
}
