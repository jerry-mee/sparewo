// lib/features/my_car/presentation/my_cars_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Added
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/my_car/application/car_provider.dart';
import 'package:sparewo_client/features/my_car/domain/car_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MyCarsScreen extends ConsumerWidget {
  const MyCarsScreen({super.key});

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
            if (context.canPop())
              context.pop();
            else
              context.go('/home');
          },
        ),
      ),
      body: carsAsync.when(
        data: (cars) {
          if (cars.isEmpty) return _buildEmptyGarage(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Text(
                  'Select a vehicle to manage',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  itemCount: cars.length + 1,
                  itemBuilder: (context, index) {
                    if (index == cars.length) {
                      return _buildAddCarButton(context);
                    }
                    return _CarHeroCard(car: cars[index])
                        .animate()
                        .fadeIn(delay: (100 * index).ms)
                        .slideY(begin: 0.1, end: 0);
                  },
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

  Widget _buildEmptyGarage(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: AppColors.primary,
            ),
          ).animate().scale(),
          const SizedBox(height: 24),
          Text('Your Garage is Empty', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'Add a vehicle to track services and insurance.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.push('/add-car'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Add First Vehicle'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCarButton(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.push('/add-car'),
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.dividerColor,
            width: 1.5,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(20),
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
}

class _CarHeroCard extends StatelessWidget {
  final CarModel car;
  const _CarHeroCard({required this.car});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasCustomImage =
        car.frontImageUrl != null && car.frontImageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push('/my-cars/detail/${car.id}', extra: car),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 120, // Increased height for image impact
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.cardShadow,
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.5),
            width: hasCustomImage ? 0 : 1,
          ),
          // If we have an image, use it as background
          image: hasCustomImage
              ? DecorationImage(
                  image: CachedNetworkImageProvider(car.frontImageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Dark Gradient Overlay for text readability on images
            if (hasCustomImage)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),

            // If no image, use the default gradient background
            if (!hasCustomImage)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [theme.cardColor, theme.scaffoldBackgroundColor],
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon Box (Only show if no custom image, or make it smaller)
                  if (!hasCustomImage) ...[
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.directions_car_filled,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          car.displayName,
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.bold,
                            // If has image, force white text
                            color: hasCustomImage
                                ? Colors.white
                                : theme.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (car.plateNumber ?? 'No Plate').toUpperCase(),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: hasCustomImage
                                ? Colors.white70
                                : theme.hintColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildTag(
                              context,
                              '${car.year}',
                              forceLight: hasCustomImage,
                            ),
                            const SizedBox(width: 8),
                            _buildTag(
                              context,
                              'Active',
                              color: AppColors.success,
                              forceLight: hasCustomImage,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.chevron_right,
                    color: hasCustomImage ? Colors.white70 : theme.hintColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(
    BuildContext context,
    String text, {
    Color? color,
    bool forceLight = false,
  }) {
    final theme = Theme.of(context);
    final effectiveColor =
        color ?? (forceLight ? Colors.white70 : theme.hintColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: forceLight ? Border.all(color: Colors.white24) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: effectiveColor,
        ),
      ),
    );
  }
}
