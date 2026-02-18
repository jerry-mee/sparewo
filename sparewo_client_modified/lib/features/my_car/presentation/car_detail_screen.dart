// lib/features/my_car/presentation/car_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/autohub/application/autohub_provider.dart';
import 'package:sparewo_client/features/my_car/application/car_provider.dart';
import 'package:sparewo_client/features/my_car/domain/car_model.dart';

final carServiceHistoryProvider =
    StreamProvider.family<List<Map<String, dynamic>>, CarModel>((ref, car) {
      final user = ref.watch(currentUserProvider).asData?.value;
      if (user == null) return Stream.value([]);

      return FirebaseFirestore.instance
          .collection('service_bookings')
          .where('userId', isEqualTo: user.id)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .where((doc) {
                  final data = doc.data();
                  final bPlate = data['vehiclePlate'] as String?;

                  if (bPlate != null &&
                      car.plateNumber != null &&
                      car.plateNumber!.trim().isNotEmpty) {
                    return bPlate.toLowerCase().trim() ==
                        car.plateNumber!.toLowerCase().trim();
                  }

                  final bMake = data['vehicleBrand'] as String?;
                  final bModel = data['vehicleModel'] as String?;
                  final bYear = (data['vehicleYear'] as num?)?.toInt();

                  return bMake == car.make &&
                      bModel == car.model &&
                      bYear == car.year;
                })
                .map((doc) => doc.data())
                .toList();
          });
    });

class CarDetailScreen extends ConsumerWidget {
  final String carId;
  final CarModel? initialCar;

  const CarDetailScreen({super.key, required this.carId, this.initialCar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveScreen(
      mobile: _buildMobile(context, ref),
      desktop: _buildDesktop(context, ref),
    );
  }

  Widget _buildDesktop(BuildContext context, WidgetRef ref) {
    final carAsync = ref.watch(carByIdProvider(carId));

    return DesktopScaffold(
      widthTier: DesktopWidthTier.standard,
      child: carAsync.when(
        data: (car) {
          final data = car ?? initialCar;
          if (data == null) return const Center(child: Text('Car not found'));
          final gallery = _imageGallery(data);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DesktopSection(
                title: data.displayName,
                subtitle: (data.plateNumber ?? 'No Number Plate').toUpperCase(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroVehicleCard(
                      car: data,
                      imageUrl: _primaryImageUrl(data),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              _VehicleDetailsCard(
                                car: data,
                                onEdit: () => _openCarEditor(context, data),
                              ),
                              if (gallery.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _VehicleGalleryCard(gallery: gallery),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _buildStatsCard(context, data),
                              const SizedBox(height: 16),
                              _buildActions(context, ref, data),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SiteFooter(),
              const SizedBox(height: 120),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildMobile(BuildContext context, WidgetRef ref) {
    final carAsync = ref.watch(carByIdProvider(carId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              final current = carAsync.asData?.value ?? initialCar;
              if (current != null) _openCarEditor(context, current);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: carAsync.when(
        data: (car) {
          final data = car ?? initialCar;
          if (data == null) return const Center(child: Text('Car not found'));
          final gallery = _imageGallery(data);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              _HeroVehicleCard(
                car: data,
                imageUrl: _primaryImageUrl(data),
                compact: true,
              ).animate().fadeIn(duration: 250.ms),
              const SizedBox(height: 16),
              _buildStatsCard(
                context,
                data,
              ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: 16),
              _VehicleDetailsCard(
                car: data,
                onEdit: () => _openCarEditor(context, data),
              ).animate().fadeIn(delay: 180.ms),
              if (gallery.isNotEmpty) ...[
                const SizedBox(height: 16),
                _VehicleGalleryCard(gallery: gallery),
              ],
              const SizedBox(height: 16),
              _buildActions(context, ref, data).animate().fadeIn(delay: 220.ms),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, CarModel data) {
    final metrics = [
      (
        icon: Icons.speed_rounded,
        label: 'Mileage',
        value: data.mileage != null ? '${_number(data.mileage!)} km' : '-',
        highlight: false,
      ),
      (
        icon: Icons.shield_rounded,
        label: 'Insurance',
        value: _formatExpiry(data.insuranceExpiryDate),
        highlight: _isExpiring(data.insuranceExpiryDate),
      ),
      (
        icon: Icons.build_circle_outlined,
        label: 'Last Service',
        value: _formatDate(data.lastServiceDate),
        highlight: false,
      ),
      (
        icon: Icons.calendar_month_outlined,
        label: 'Vehicle Year',
        value: '${data.year}',
        highlight: false,
      ),
    ];

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.cardShadow,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: metrics.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isNarrow ? 1.75 : 2.25,
            ),
            itemBuilder: (context, index) {
              final metric = metrics[index];
              final color = metric.highlight
                  ? AppColors.warning
                  : AppColors.primary;

              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 8 : 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.36,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(metric.icon, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: metric.highlight
                                  ? AppColors.warning
                                  : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metric.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, CarModel data) {
    return Column(
      children: [
        _ActionTile(
          title: 'Book a service',
          subtitle: 'Schedule maintenance for this car',
          icon: Icons.calendar_today,
          onTap: () {
            ref
                .read(bookingFlowNotifierProvider.notifier)
                .setVehicle(data.make, data.model, data.year);
            context.push('/autohub/booking');
          },
        ),
        if (!data.isDefault) ...[
          const SizedBox(height: 16),
          _ActionTile(
            title: 'Set as primary vehicle',
            subtitle: 'Use this car as your default across the app',
            icon: Icons.star_rounded,
            onTap: () async {
              await ref
                  .read(carNotifierProvider.notifier)
                  .setDefaultCar(data.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Primary vehicle updated.')),
                );
              }
            },
          ),
        ],
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, _) {
            final historyAsync = ref.watch(carServiceHistoryProvider(data));

            return historyAsync.when(
              data: (history) => _ServiceHistoryTile(
                manualDate: data.lastServiceDate,
                bookings: history,
              ),
              loading: () => _ActionTile(
                title: 'Service History',
                subtitle: 'Loading service records...',
                icon: Icons.history,
                onTap: () {},
              ),
              error: (_, __) => _ActionTile(
                title: 'Service History',
                subtitle: 'Could not load service records',
                icon: Icons.history,
                onTap: () {},
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatExpiry(DateTime? date) {
    if (date == null) return '-';
    final days = date.difference(DateTime.now()).inDays;
    if (days < 0) return 'Expired';
    return '$days days';
  }

  bool _isExpiring(DateTime? date) {
    if (date == null) return false;
    return date.difference(DateTime.now()).inDays < 30;
  }

  List<String> _imageGallery(CarModel car) {
    final images = <String>[];

    void addIfValid(String? value) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty && !images.contains(trimmed)) {
        images.add(trimmed);
      }
    }

    addIfValid(car.frontImageUrl);
    addIfValid(car.sideImageUrl);
    return images;
  }

  String? _primaryImageUrl(CarModel car) {
    final images = _imageGallery(car);
    if (images.isEmpty) return null;
    return images.first;
  }

  String _number(int value) => NumberFormat('#,###').format(value);

  void _openCarEditor(BuildContext context, CarModel car) {
    context.push('/add-car', extra: car);
  }
}

class _HeroVehicleCard extends StatelessWidget {
  final CarModel car;
  final String? imageUrl;
  final bool compact;

  const _HeroVehicleCard({
    required this.car,
    required this.imageUrl,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      height: compact ? 270 : 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _HeroFallback(theme: theme),
              placeholder: (_, __) => _HeroFallback(theme: theme),
            )
          else
            _HeroFallback(theme: theme),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: _HeroChip(
              icon: Icons.badge_outlined,
              text: (car.plateNumber?.trim().isNotEmpty ?? false)
                  ? car.plateNumber!.toUpperCase()
                  : 'No Number Plate',
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: _HeroChip(
              icon: Icons.verified_rounded,
              text: car.isDefault ? 'Primary' : 'Active',
              color: car.isDefault ? AppColors.primary : AppColors.success,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  car.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${car.make} • ${car.model} • ${car.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  final ThemeData theme;

  const _HeroFallback({required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0E1524), Color(0xFF1D2C49)]
              : const [Color(0xFFFFEBD8), Color(0xFFFFFAF3)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.directions_car_filled_rounded,
          size: 110,
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _HeroChip({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final fg = color ?? Colors.white;
    final bg = color == null
        ? Colors.black.withValues(alpha: 0.35)
        : color!.withValues(alpha: 0.9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleDetailsCard extends StatelessWidget {
  final CarModel car;
  final VoidCallback onEdit;

  const _VehicleDetailsCard({required this.car, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mileage = car.mileage != null
        ? '${NumberFormat('#,###').format(car.mileage)} km'
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.cardShadow,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Vehicle Details', style: AppTextStyles.h4),
              const Spacer(),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Make', value: car.make),
          _DetailRow(label: 'Model', value: car.model),
          _DetailRow(label: 'Year', value: '${car.year}'),
          _DetailRow(label: 'Plate', value: car.plateNumber),
          _DetailRow(label: 'VIN', value: car.vin),
          _DetailRow(label: 'Colour', value: car.color),
          _DetailRow(label: 'Transmission', value: car.transmission),
          _DetailRow(label: 'Engine Size', value: car.engineType),
          _DetailRow(label: 'Mileage', value: mileage),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clean = value?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: theme.hintColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (clean != null && clean.isNotEmpty) ? clean : '-',
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleGalleryCard extends StatelessWidget {
  final List<String> gallery;

  const _VehicleGalleryCard({required this.gallery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.cardShadow,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vehicle Photos', style: AppTextStyles.h4),
          const SizedBox(height: 4),
          Text(
            'Tap to view full screen',
            style: AppTextStyles.bodySmall.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: gallery.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => _VehiclePhotoViewerDialog(
                            images: gallery,
                            initialIndex: index,
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: gallery[index],
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                          placeholder: (_, __) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VehiclePhotoViewerDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _VehiclePhotoViewerDialog({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_VehiclePhotoViewerDialog> createState() =>
      _VehiclePhotoViewerDialogState();
}

class _VehiclePhotoViewerDialogState extends State<_VehiclePhotoViewerDialog> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Photo ${_index + 1} of ${widget.images.length}',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
        body: PageView.builder(
          controller: _controller,
          itemCount: widget.images.length,
          onPageChanged: (value) => setState(() => _index = value),
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: widget.images[index],
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 56,
                  ),
                  placeholder: (_, __) =>
                      const CircularProgressIndicator(color: Colors.white70),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ServiceHistoryTile extends StatelessWidget {
  final DateTime? manualDate;
  final List<Map<String, dynamic>> bookings;

  const _ServiceHistoryTile({required this.manualDate, required this.bookings});

  @override
  Widget build(BuildContext context) {
    int totalCount = bookings.length;
    String lastDateStr = 'No history';

    DateTime? latest = manualDate;
    if (bookings.isNotEmpty) {
      final lastBooking = (bookings.first['createdAt'] as Timestamp?)?.toDate();
      if (lastBooking != null &&
          (latest == null || lastBooking.isAfter(latest))) {
        latest = lastBooking;
      }
    }

    if (latest != null) {
      lastDateStr = 'Last: ${DateFormat('dd MMM yyyy').format(latest)}';
      if (manualDate != null && bookings.isEmpty) totalCount = 1;
    }

    return _ActionTile(
      title: 'Service History',
      subtitle: '$totalCount digital records • $lastDateStr',
      icon: Icons.history,
      onTap: () => _showHistoryModal(context, bookings, manualDate),
    );
  }

  void _showHistoryModal(
    BuildContext ctx,
    List<Map<String, dynamic>> bookings,
    DateTime? manual,
  ) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Service History', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            if (manual != null)
              ListTile(
                leading: const Icon(Icons.edit_note, color: Colors.grey),
                title: const Text('Manual Entry (from setup)'),
                subtitle: Text(DateFormat('dd MMMM yyyy').format(manual)),
                contentPadding: EdgeInsets.zero,
              ),
            if (bookings.isEmpty && manual == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No service history found.'),
              ),
            ...bookings.map((b) {
              final date =
                  (b['pickupDate'] as Timestamp?)?.toDate() ?? DateTime.now();
              final services =
                  (b['services'] as List?)?.join(', ') ?? 'Service';
              final status = (b['status'] ?? '').toString().toUpperCase();

              return ListTile(
                leading: const Icon(Icons.verified, color: AppColors.primary),
                title: Text(services),
                subtitle: Text(DateFormat('dd MMM yyyy').format(date)),
                contentPadding: EdgeInsets.zero,
                trailing: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.cardShadow,
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h4.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}
