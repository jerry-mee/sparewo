// lib/features/my_car/presentation/car_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/autohub/application/autohub_provider.dart';
import 'package:sparewo_client/features/my_car/application/car_provider.dart';
import 'package:sparewo_client/features/my_car/domain/car_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Provider to fetch bookings specifically for this car
final carServiceHistoryProvider =
    StreamProvider.family<List<Map<String, dynamic>>, CarModel>((ref, car) {
      final user = ref.watch(currentUserProvider).asData?.value;
      if (user == null) return Stream.value([]);

      // Query by User ID
      return FirebaseFirestore.instance
          .collection('service_bookings')
          .where('userId', isEqualTo: user.id)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            // Client-side filter to find bookings for THIS specific car
            // Matches if Plate matches OR (Make+Model+Year match)
            return snapshot.docs
                .where((doc) {
                  final data = doc.data();
                  final bPlate = data['vehiclePlate'] as String?;

                  if (bPlate != null && car.plateNumber != null) {
                    return bPlate.toLowerCase() ==
                        car.plateNumber!.toLowerCase();
                  }

                  final bMake = data['vehicleBrand'] as String?;
                  final bModel = data['vehicleModel'] as String?;
                  final bYear = data['vehicleYear'] as int?;

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
    final carAsync = ref.watch(carByIdProvider(carId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: theme.iconTheme.color,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: theme.iconTheme.color),
            onPressed: () {
              final car = carAsync.asData?.value ?? initialCar;
              if (car != null) context.push('/add-car', extra: car);
            },
          ),
        ],
      ),
      body: carAsync.when(
        data: (car) {
          final data = car ?? initialCar;
          if (data == null) return const Center(child: Text('Car not found'));
          return _buildCarContent(context, ref, data, isDark);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildCarContent(
    BuildContext context,
    WidgetRef ref,
    CarModel car,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          // 1. Title & Status
          Column(
            children: [
              Text(
                car.displayName,
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (car.plateNumber != null)
                Text(
                  car.plateNumber!.toUpperCase(),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Theme.of(context).hintColor,
                    letterSpacing: 1.2,
                  ),
                ),
            ],
          ).animate().fadeIn().slideY(begin: -0.2, end: 0),

          const SizedBox(height: 40),

          // 2. Hero Image (Use uploaded image if available, else Icon)
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (car.frontImageUrl != null)
                  Container(
                    width: 280,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      image: DecorationImage(
                        image: NetworkImage(car.frontImageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.15),
                              blurRadius: 80,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.directions_car_filled,
                        size: 180,
                        color: isDark
                            ? Colors.white.withOpacity(0.9)
                            : const Color(0xFF1E293B),
                      ),
                    ],
                  ),
              ],
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 40),

          // 3. Stats Grid
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.cardShadow,
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(
                  icon: Icons.speed,
                  value: '${car.mileage ?? "-"}',
                  unit: 'km',
                  label: 'Mileage',
                  context: context,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).dividerColor,
                ),
                _StatItem(
                  icon: Icons.security,
                  value: _formatExpiry(car.insuranceExpiryDate),
                  unit: '',
                  label: 'Insurance',
                  context: context,
                  isWarning: _isExpiring(car.insuranceExpiryDate),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).dividerColor,
                ),
                _StatItem(
                  icon: Icons.build_circle_outlined,
                  value: _formatDate(car.lastServiceDate),
                  unit: '',
                  label: 'Last Service',
                  context: context,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 32),

          // 4. Action Cards
          Column(
            children: [
              _ActionTile(
                title: 'Book Service',
                subtitle: 'Schedule maintenance for this car',
                icon: Icons.calendar_today,
                onTap: () {
                  // Pre-fill booking flow
                  ref
                      .read(bookingFlowNotifierProvider.notifier)
                      .setVehicle(car.make, car.model, car.year);
                  context.push('/autohub/booking');
                },
                context: context,
              ),
              const SizedBox(height: 16),

              // Service History Logic
              Consumer(
                builder: (context, ref, _) {
                  final historyAsync = ref.watch(
                    carServiceHistoryProvider(car),
                  );

                  return historyAsync.when(
                    data: (history) => _ServiceHistoryTile(
                      manualDate: car.lastServiceDate,
                      bookings: history,
                      context: context,
                    ),
                    loading: () => _ActionTile(
                      title: 'Service History',
                      subtitle: 'Loading...',
                      icon: Icons.history,
                      onTap: () {},
                      context: context,
                    ),
                    error: (_, __) => _ActionTile(
                      title: 'Service History',
                      subtitle: 'Error loading history',
                      icon: Icons.history,
                      onTap: () {},
                      context: context,
                    ),
                  );
                },
              ),
            ],
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('MMM yyyy').format(date);
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
}

class _ServiceHistoryTile extends StatelessWidget {
  final DateTime? manualDate;
  final List<Map<String, dynamic>> bookings;
  final BuildContext context;

  const _ServiceHistoryTile({
    required this.manualDate,
    required this.bookings,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    // Combine Manual Entry + Synced Bookings
    int totalCount = bookings.length;
    String lastDateStr = "No history";

    // Determine the absolute latest date
    DateTime? latest = manualDate;
    if (bookings.isNotEmpty) {
      final lastBooking = (bookings.first['createdAt'] as Timestamp?)?.toDate();
      if (lastBooking != null) {
        if (latest == null || lastBooking.isAfter(latest)) {
          latest = lastBooking;
        }
      }
    }

    if (latest != null) {
      lastDateStr = "Last: ${DateFormat('dd MMM yyyy').format(latest)}";
      if (manualDate != null && bookings.isEmpty) totalCount = 1;
      // If we have both, assume manual might overlap or be distinct,
      // but for "Count", just showing bookings count + 1 if manual exists is vague.
      // Better: Just show "X online records"
    }

    return _ActionTile(
      title: 'Service History',
      subtitle: '$totalCount digital records • $lastDateStr',
      icon: Icons.history,
      onTap: () {
        // Show modal or navigate to a dedicated history list
        _showHistoryModal(context, bookings, manualDate);
      },
      context: context,
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
                child: Text("No service history found."),
              ),
            ...bookings.map((b) {
              final date =
                  (b['pickupDate'] as Timestamp?)?.toDate() ?? DateTime.now();
              return ListTile(
                leading: const Icon(Icons.verified, color: AppColors.primary),
                title: Text((b['services'] as List?)?.join(', ') ?? 'Service'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(date)),
                contentPadding: EdgeInsets.zero,
                trailing: Text(
                  (b['status'] ?? '').toString().toUpperCase(),
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final BuildContext context;
  final bool isWarning;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.context,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: isWarning ? AppColors.warning : AppColors.primary,
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: value,
              style: AppTextStyles.h4.copyWith(
                fontSize: 16,
                color: isWarning
                    ? AppColors.warning
                    : theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
              children: [
                if (unit.isNotEmpty)
                  TextSpan(
                    text: '\n$unit',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.hintColor,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final BuildContext context;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.context,
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
          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
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
