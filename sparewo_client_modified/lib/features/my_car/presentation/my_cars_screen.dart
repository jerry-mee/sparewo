// lib/features/my_car/presentation/my_cars_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';
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
                child: cars.isEmpty
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
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_outlined,
              size: 62,
              color: AppColors.primary,
            ),
          ).animate().scale(),
          const SizedBox(height: 24),
          Text('Your Garage is Empty', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'Add a vehicle with photos to unlock service tracking and reminders.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => context.push('/add-car'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
            child: const Text('Add First Vehicle'),
          ),
        ],
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

class _GarageCarCard extends ConsumerWidget {
  final CarModel car;

  const _GarageCarCard({required this.car});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final imageUrl = _primaryImageUrl(car);
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final nextInsurance = _formatInsurance(car.insuranceExpiryDate);
    final lastService = _formatService(car.lastServiceDate);
    final saving = ref.watch(carNotifierProvider).isLoading;

    return InkWell(
      onTap: () => context.push('/my-cars/detail/${car.id}', extra: car),
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.cardShadow,
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            _ImageFallback(theme: theme),
                        placeholder: (_, __) => _ImageFallback(theme: theme),
                      )
                    else
                      _ImageFallback(theme: theme),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.12),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _TopChip(
                        text: '${car.year}',
                        background: Colors.black.withValues(alpha: 0.45),
                        foreground: Colors.white,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _TopChip(
                        text: car.isDefault ? 'Primary' : 'Vehicle',
                        background: car.isDefault
                            ? AppColors.primary.withValues(alpha: 0.9)
                            : Colors.black.withValues(alpha: 0.45),
                        foreground: Colors.white,
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Text(
                        car.displayName,
                        style: AppTextStyles.h4.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (car.plateNumber?.trim().isNotEmpty ?? false)
                        ? car.plateNumber!.toUpperCase()
                        : 'No Plate Number',
                    style: AppTextStyles.labelLarge.copyWith(
                      letterSpacing: 0.6,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(icon: Icons.speed, text: _mileageLabel(car)),
                      _InfoPill(icon: Icons.verified_user, text: nextInsurance),
                      _InfoPill(icon: Icons.build, text: lastService),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        hasImage ? 'Photo verified' : 'No photo yet',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: hasImage ? AppColors.success : theme.hintColor,
                        ),
                      ),
                      const Spacer(),
                      if (!car.isDefault)
                        TextButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  await ref
                                      .read(carNotifierProvider.notifier)
                                      .setDefaultCar(car.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Primary vehicle updated.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            'Set Primary',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Primary',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _mileageLabel(CarModel car) {
    final mileage = car.mileage;
    if (mileage == null) return 'Mileage -';
    final formatter = NumberFormat('#,###');
    return '${formatter.format(mileage)} km';
  }

  String _formatInsurance(DateTime? date) {
    if (date == null) return 'Insurance -';
    final days = date.difference(DateTime.now()).inDays;
    if (days < 0) return 'Insurance expired';
    return 'Insurance $days days';
  }

  String _formatService(DateTime? date) {
    if (date == null) return 'Service -';
    return 'Service ${DateFormat('MMM y').format(date)}';
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: theme.textTheme.bodyMedium?.color,
              letterSpacing: 0.1,
            ),
          ),
        ],
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
