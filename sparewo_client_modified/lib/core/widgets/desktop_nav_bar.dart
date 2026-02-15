import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/cart/application/cart_provider.dart';
import 'package:sparewo_client/features/auth/presentation/widgets/auth_guard_modal.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sparewo_client/core/widgets/desktop_layout.dart';
import 'package:sparewo_client/features/catalog/application/product_provider.dart';
import 'package:sparewo_client/features/catalog/domain/product_model.dart';

class DesktopNavBar extends ConsumerStatefulWidget {
  final StatefulNavigationShell? navigationShell;

  const DesktopNavBar({super.key, this.navigationShell});

  @override
  ConsumerState<DesktopNavBar> createState() => _DesktopNavBarState();
}

class _DesktopNavBarState extends ConsumerState<DesktopNavBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchLink = LayerLink();
  final GlobalKey _searchKey = GlobalKey();
  OverlayEntry? _searchOverlay;
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _removeSearchOverlay();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        _removeSearchOverlay();
      } else if (_searchQuery.length >= 2) {
        _showSearchOverlay();
      }
    });
  }

  void _handleSearchChanged(String value) {
    final query = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      setState(() => _searchQuery = query);
      if (query.length >= 2 && _searchFocusNode.hasFocus) {
        _showSearchOverlay();
      } else {
        _removeSearchOverlay();
      }
    });
  }

  void _showSearchOverlay() {
    if (_searchOverlay != null) {
      _searchOverlay!.markNeedsBuild();
      return;
    }

    final overlay = Overlay.of(context);

    _searchOverlay = OverlayEntry(
      builder: (context) {
        if (_searchQuery.length < 2 || !_searchFocusNode.hasFocus) {
          return const SizedBox.shrink();
        }

        final width = _searchKey.currentContext?.size?.width ?? 560;
        return Positioned(
          width: width,
          child: CompositedTransformFollower(
            link: _searchLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 60),
            child: Material(
              color: Colors.transparent,
              child: Consumer(
                builder: (context, ref, _) {
                  final resultsAsync = ref.watch(
                    catalogProductsProvider((
                      category: null,
                      searchQuery: _searchQuery,
                    )),
                  );
                  return _buildSearchResults(context, resultsAsync);
                },
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_searchOverlay!);
  }

  void _removeSearchOverlay() {
    _searchOverlay?.remove();
    _searchOverlay = null;
  }

  Widget _buildSearchResults(
    BuildContext context,
    AsyncValue<List<ProductModel>> resultsAsync,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
        boxShadow: AppShadows.floatingShadow,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: resultsAsync.when(
        data: (items) {
          final results = items.take(6).toList();
          if (results.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No results found',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final product in results)
                InkWell(
                  onTap: () {
                    _searchFocusNode.unfocus();
                    _removeSearchOverlay();
                    context.push('/product/${product.id}');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.build_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.partName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                product.brand,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          product.formattedPrice,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  _searchFocusNode.unfocus();
                  _removeSearchOverlay();
                  context.go('/catalog?search=$_searchQuery');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View all results',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Search unavailable',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider).value;
    final cart = ref.watch(cartNotifierProvider).value;

    final logoAsset = isDark
        ? 'assets/logo/branding.png'
        : 'assets/logo/branding_dark.png';

    final navShell = widget.navigationShell;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: DesktopWebScale.navHeight,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(
              alpha: isDark ? 0.78 : 0.76,
            ),
          ),
          child: Center(
            child: Container(
              height: 68,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color:
                    (isDark
                            ? const Color(0xFF121A29)
                            : theme.scaffoldBackgroundColor)
                        .withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: theme.dividerColor.withValues(
                    alpha: isDark ? 0.12 : 0.2,
                  ),
                ),
                boxShadow: AppShadows.floatingShadow,
              ),
              child: DesktopLayout(
                tier: DesktopWidthTier.wide,
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => context.go('/home'),
                            child: Image.asset(logoAsset, height: 28),
                          ),
                          const SizedBox(width: 36),
                          _NavBarLink(
                            label: 'Home',
                            isActive: navShell?.currentIndex == 0,
                            onTap: () => navShell != null
                                ? navShell.goBranch(0)
                                : context.go('/home'),
                          ),
                          const SizedBox(width: 22),
                          _NavBarLink(
                            label: 'Catalog',
                            isActive: navShell?.currentIndex == 1,
                            onTap: () => navShell != null
                                ? navShell.goBranch(1)
                                : context.go('/catalog'),
                          ),
                          const SizedBox(width: 22),
                          _NavBarLink(
                            label: 'AutoHub',
                            isActive: navShell?.currentIndex == 2,
                            onTap: () => navShell != null
                                ? navShell.goBranch(2)
                                : context.go('/autohub'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: CompositedTransformTarget(
                            link: _searchLink,
                            child: Container(
                              key: _searchKey,
                              height: 46,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: theme.dividerColor.withValues(
                                    alpha: isDark ? 0.2 : 0.4,
                                  ),
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                onChanged: _handleSearchChanged,
                                onSubmitted: (value) {
                                  final query = value.trim();
                                  if (query.isNotEmpty) {
                                    _removeSearchOverlay();
                                    _searchFocusNode.unfocus();
                                    context.go('/catalog?search=$query');
                                  }
                                },
                                onTap: () {
                                  if (_searchQuery.length >= 2) {
                                    _showSearchOverlay();
                                  }
                                },
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  hintText: 'Search',
                                  hintStyle: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                        color: theme.hintColor.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: theme.hintColor.withValues(
                                      alpha: 0.7,
                                    ),
                                    size: 20,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _IconAction(
                            icon: Icons.settings_outlined,
                            tooltip: 'Settings',
                            onTap: () => context.push('/settings'),
                          ),
                          const SizedBox(width: 12),
                          _IconAction(
                            icon: Icons.directions_car_outlined,
                            tooltip: 'My Garage',
                            onTap: () {
                              AuthGuardModal.check(
                                context: context,
                                ref: ref,
                                title: 'Access Your Garage',
                                message:
                                    'Sign in to manage your vehicles and track services.',
                                onAuthenticated: () => context.push('/my-cars'),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Stack(
                            children: [
                              _IconAction(
                                icon: Icons.shopping_bag_outlined,
                                tooltip: 'Cart',
                                onTap: () => context.push('/cart'),
                              ),
                              if ((cart?.totalItems ?? 0) > 0)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child:
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          '${cart!.totalItems}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ).animate().scale(
                                        duration: 200.ms,
                                        curve: Curves.easeOutBack,
                                      ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          if (user != null)
                            PopupMenuButton<String>(
                              offset: const Offset(0, 48),
                              onSelected: (value) {
                                if (value == 'profile') {
                                  context.go('/profile');
                                } else if (value == 'settings') {
                                  context.go('/settings');
                                } else if (value == 'support') {
                                  context.go('/support');
                                } else if (value == 'about') {
                                  context.go('/about');
                                } else if (value == 'logout') {
                                  ref
                                      .read(authNotifierProvider.notifier)
                                      .signOut();
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'profile',
                                  child: Text('Profile'),
                                ),
                                PopupMenuItem(
                                  value: 'settings',
                                  child: Text('Settings'),
                                ),
                                PopupMenuItem(
                                  value: 'support',
                                  child: Text('Support'),
                                ),
                                PopupMenuItem(
                                  value: 'about',
                                  child: Text('About'),
                                ),
                                PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'logout',
                                  child: Text('Sign Out'),
                                ),
                              ],
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.2,
                                ),
                                backgroundImage: user.photoUrl != null
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                                child: user.photoUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        color: AppColors.primary,
                                        size: 18,
                                      )
                                    : null,
                              ),
                            )
                          else ...[
                            FilledButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  barrierColor: Colors.black.withValues(
                                    alpha: 0.6,
                                  ),
                                  builder: (context) => AuthGuardModal(
                                    title: 'Sign in to continue',
                                    message:
                                        'Create an account to access your garage, orders, and settings.',
                                    returnTo: GoRouterState.of(
                                      context,
                                    ).uri.toString(),
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 0,
                                ),
                                fixedSize: const Size.fromHeight(42),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: const Text('Sign In'),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              offset: const Offset(0, 48),
                              onSelected: (value) {
                                if (value == 'settings') {
                                  context.go('/settings');
                                } else if (value == 'support') {
                                  context.go('/support');
                                } else if (value == 'about') {
                                  context.go('/about');
                                } else if (value == 'signup') {
                                  context.go('/signup');
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'settings',
                                  child: Text('Settings'),
                                ),
                                PopupMenuItem(
                                  value: 'support',
                                  child: Text('Support'),
                                ),
                                PopupMenuItem(
                                  value: 'about',
                                  child: Text('About'),
                                ),
                                PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'signup',
                                  child: Text('Create Account'),
                                ),
                              ],
                              child: const Icon(Icons.more_horiz),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarLink extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarLink({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavBarLink> createState() => _NavBarLinkState();
}

class _NavBarLinkState extends State<_NavBarLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isActive
        ? AppColors.primary
        : (_isHovered ? theme.textTheme.bodyLarge?.color : theme.hintColor);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: 200.ms,
          style: AppTextStyles.labelLarge.copyWith(
            color: color,
            fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.label),
              const SizedBox(height: 4),
              // Underline indicator
              AnimatedContainer(
                duration: 250.ms,
                height: 2,
                width: widget.isActive ? 20 : 0,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: 200.ms,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isHovered
                  ? theme.iconTheme.color?.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.icon,
              color: _isHovered ? AppColors.primary : theme.iconTheme.color,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
