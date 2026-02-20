// lib/features/my_car/presentation/my_cars_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/auth/presentation/widgets/auth_guard_modal.dart';
import 'package:sparewo_client/features/my_car/application/car_provider.dart';
import 'package:sparewo_client/features/my_car/domain/car_model.dart';

class MyCarsScreen extends ConsumerWidget {
  const MyCarsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ResponsiveScreen(
      mobile: _MobileMyCarsScreen(),
      desktop: _DesktopMyCarsScreen(),
    );
  }
}

class _MobileMyCarsScreen extends ConsumerWidget {
  const _MobileMyCarsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carsAsync = ref.watch(carsProvider);
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Garage'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
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
              context.go('/home');
            }
          },
        ),
      ),
      body: carsAsync.when(
        data: (cars) {
          if (currentUser == null) return _buildGuestGaragePrompt(context);
          if (cars.isEmpty) return _buildEmptyGarage(context);

          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _GarageSummaryCard(cars: cars),
                    const SizedBox(height: 20),
                    ...cars.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _GarageCarCard(car: entry.value)
                            .animate()
                            .fadeIn(delay: (60 * entry.key).ms)
                            .slideY(begin: 0.06, end: 0),
                      );
                    }),
                    _buildAddCarButton(context),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _DesktopMyCarsScreen extends ConsumerWidget {
  const _DesktopMyCarsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carsAsync = ref.watch(carsProvider);
    final currentUser = ref.watch(currentUserProvider).asData?.value;

    return carsAsync.when(
      data: (cars) {
        return DesktopScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DesktopSection(
                title: 'My Garage',
                subtitle:
                    'Vehicle photos, service readiness, and insurance status.',
                child: currentUser == null
                    ? _buildGuestGaragePrompt(context, isDesktop: true)
                    : cars.isEmpty
                    ? _buildEmptyGarage(context)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GarageSummaryCard(cars: cars),
                          const SizedBox(height: 24),
                          GridView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 460,
                                  mainAxisSpacing: 20,
                                  crossAxisSpacing: 20,
                                  childAspectRatio: 0.92,
                                ),
                            itemCount: cars.length + 1,
                            itemBuilder: (context, index) {
                              if (index == cars.length) {
                                return _buildAddCarButton(context);
                              }
                              return _GarageCarCard(car: cars[index]);
                            },
                          ),
                        ],
                      ),
              ),
              const SiteFooter(),
              const SizedBox(height: 120),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _GarageSummaryCard extends StatelessWidget {
  final List<CarModel> cars;

  const _GarageSummaryCard({required this.cars});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryCount = cars.where((c) => c.isDefault).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF111A2B), const Color(0xFF1E2E4E)]
              : [const Color(0xFFFFE8D6), const Color(0xFFFFF6EC)],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.garage_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Garage Overview',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${cars.length} vehicle${cars.length == 1 ? '' : 's'} • $primaryCount primary',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary.withValues(alpha: isDark ? 0.9 : 0.8),
          ),
        ],
      ),
    );
  }
}

Widget _buildEmptyGarage(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustrated/Graphical Header
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.garage_rounded,
                  size: 100,
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.2 : 0.1,
                  ),
                ),
                Icon(
                      Icons.directions_car_filled_rounded,
                      size: 72,
                      color: AppColors.primary.withValues(alpha: 0.8),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: 2.seconds,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
              ],
            ),
          ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms),

          const SizedBox(height: 32),

          Text(
            'Your Digital Garage',
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 12),

          Text(
            'Keep track of your vehicle\'s health, service history, and insurance in one place. Add your first car to get started.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: theme.hintColor,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () => context.push('/add-car'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your Vehicle'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).scale(),
        ],
      ),
    ),
  );
}

Widget _buildGuestGaragePrompt(BuildContext context, {bool isDesktop = false}) {
  final theme = Theme.of(context);
  return Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppShadows.cardShadow,
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.garage_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Build your digital garage',
                textAlign: TextAlign.center,
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 8),
              Text(
                'Log in to save your vehicles, upload photos, and track service and insurance details in one place.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: theme.hintColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.6),
                    builder: (context) => AuthGuardModal(
                      title: 'Log in to use My Garage',
                      message:
                          'Create an account to save your vehicles and maintenance history.',
                      returnTo: GoRouterState.of(context).uri.toString(),
                    ),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Log in / Register'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildAddCarButton(BuildContext context) {
  final theme = Theme.of(context);
  return InkWell(
    onTap: () => context.push('/add-car'),
    borderRadius: BorderRadius.circular(20),
    child: Ink(
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.7)),
        color: theme.cardColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, color: theme.hintColor),
          const SizedBox(width: 12),
          Text(
            'Add Another Vehicle',
            style: AppTextStyles.button.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    ),
  );
}

class _GarageCarCard extends ConsumerStatefulWidget {
  final CarModel car;

  const _GarageCarCard({required this.car});

  @override
  ConsumerState<_GarageCarCard> createState() => _GarageCarCardState();
}

class _GarageCarCardState extends ConsumerState<_GarageCarCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    final imageUrl = _primaryImageUrl(widget.car);
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final saving = ref.watch(carNotifierProvider).isLoading;

    if (isDesktop) {
      return _buildDesktopCard(context, theme, hasImage, imageUrl, saving);
    }

    return _buildMobileCard(context, theme, hasImage, imageUrl, saving);
  }

  Widget _buildMobileCard(
    BuildContext context,
    ThemeData theme,
    bool hasImage,
    String? imageUrl,
    bool saving,
  ) {
    return InkWell(
      onTap: () =>
          context.push('/my-cars/detail/${widget.car.id}', extra: widget.car),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 240.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            if (hasImage)
              CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _ImageFallback(theme: theme),
                placeholder: (_, __) => _ImageFallback(theme: theme),
              )
            else
              _ImageFallback(theme: theme),

            // Immersive Gradient Overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Top Status Badges
            Positioned(
              top: 14,
              left: 14,
              child: _TopChip(
                text: widget.car.isDefault ? 'PRIMARY' : 'VEHICLE',
                background: widget.car.isDefault
                    ? AppColors.primary
                    : Colors.black.withValues(alpha: 0.5),
                foreground: Colors.white,
              ),
            ),

            // Car Info (Bottom)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.car.displayName,
                    style: AppTextStyles.h3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InfoIconPill(
                        icon: Icons.speed_rounded,
                        text: _mileageLabel(widget.car),
                      ),
                      const SizedBox(width: 8),
                      _InfoIconPill(
                        icon: Icons.shield_rounded,
                        text: _formatInsurance(widget.car.insuranceExpiryDate),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Edit/Quick Action floating button
            Positioned(
              bottom: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopCard(
    BuildContext context,
    ThemeData theme,
    bool hasImage,
    String? imageUrl,
    bool saving,
  ) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () =>
            context.push('/my-cars/detail/${widget.car.id}', extra: widget.car),
        child: AnimatedContainer(
          duration: 300.ms,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _isHovered
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : theme.dividerColor.withValues(alpha: 0.3),
              width: _isHovered ? 2 : 1.2,
            ),
            boxShadow: _isHovered
                ? AppShadows.floatingShadow
                : AppShadows.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // High-Def Image Area
              Expanded(
                flex: 7,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            _ImageFallback(theme: theme),
                        placeholder: (_, __) => _ImageFallback(theme: theme),
                      )
                    else
                      _ImageFallback(theme: theme),

                    // Racing Style Overlay
                    AnimatedOpacity(
                      duration: 300.ms,
                      opacity: _isHovered ? 0.3 : 0.6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.9),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 16,
                      right: 16,
                      child: _TopChip(
                        text: widget.car.isDefault ? 'PRIMARY' : 'GAREGE',
                        background: widget.car.isDefault
                            ? AppColors.primary
                            : Colors.black.withValues(alpha: 0.7),
                        foreground: Colors.white,
                      ),
                    ),

                    Positioned(
                      bottom: 16,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.car.displayName.toUpperCase(),
                            style: AppTextStyles.desktopH3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              letterSpacing: -0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.car.plateNumber?.toUpperCase() ?? 'NO PLATE',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Details Area
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _DesktopInfoRow(
                            label: 'MILEAGE',
                            value: _mileageLabel(widget.car),
                            icon: Icons.speed_rounded,
                          ),
                          const SizedBox(height: 8),
                          _DesktopInfoRow(
                            label: 'INSURANCE',
                            value: _formatInsurance(
                              widget.car.insuranceExpiryDate,
                            ),
                            icon: Icons.shield_rounded,
                          ),
                        ],
                      ),

                      // Circle Action Button
                      AnimatedContainer(
                        duration: 300.ms,
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          color: _isHovered
                              ? AppColors.primary
                              : theme.scaffoldBackgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isHovered
                                ? AppColors.primary
                                : theme.dividerColor,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: _isHovered
                              ? Colors.white
                              : theme.iconTheme.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _mileageLabel(CarModel car) {
    final mileage = car.mileage;
    if (mileage == null) return '-';
    final formatter = NumberFormat('#,###');
    return '${formatter.format(mileage)} km';
  }

  String _formatInsurance(DateTime? date) {
    if (date == null) return '-';
    final days = date.difference(DateTime.now()).inDays;
    if (days < 0) return 'Expired';
    return '$days days';
  }
}

class _InfoIconPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoIconPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DesktopInfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.hintColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 9,
                color: theme.hintColor,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final ThemeData theme;

  const _ImageFallback({required this.theme});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.cardColor, theme.scaffoldBackgroundColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.directions_car_filled,
          size: 80,
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _TopChip extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _TopChip({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(color: foreground),
      ),
    );
  }
}

String? _primaryImageUrl(CarModel car) {
  final front = car.frontImageUrl?.trim();
  if (front != null && front.isNotEmpty) return front;

  final side = car.sideImageUrl?.trim();
  if (side != null && side.isNotEmpty) return side;

  return null;
}
