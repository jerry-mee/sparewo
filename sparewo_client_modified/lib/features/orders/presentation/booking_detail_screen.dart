// lib/features/orders/presentation/booking_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/autohub/domain/service_booking_model.dart';
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';

/// Stream a single booking document by ID
final bookingByIdProvider =
    StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>((
      ref,
      id,
    ) {
      return FirebaseFirestore.instance
          .collection('service_bookings')
          .doc(id)
          .snapshots();
    });

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  final ServiceBooking? initialBooking;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    this.initialBooking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));
    final theme = Theme.of(context);

    ServiceBooking? booking;

    if (bookingAsync.hasError) {
      // FIX: AppLogger argument fix
      AppLogger.error(
        'BookingDetailScreen',
        'Stream error',
        error: bookingAsync.error,
        stackTrace: bookingAsync.stackTrace,
        extra: {'bookingId': bookingId},
      );
    }

    if (bookingAsync.hasValue && bookingAsync.value!.data() != null) {
      final snap = bookingAsync.value!;
      booking = ServiceBooking.fromJson(snap.data()!).copyWith(id: snap.id);
    } else {
      booking = initialBooking;
      if (booking == null && bookingAsync.hasValue) {
        // Document exists in stream but has no data?
        AppLogger.warn(
          'BookingDetailScreen',
          'Document snapshot has no data',
          extra: {'bookingId': bookingId},
        );
      }
    }

    return ResponsiveScreen(
      mobile: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Garage Booking'),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: theme.iconTheme.color,
            ),
            onPressed: () {
              final router = GoRouter.of(context);
              if (router.canPop()) {
                router.pop();
              } else {
                router.go('/orders');
              }
            },
          ),
        ),
        body: bookingAsync.hasError
            ? _buildErrorState()
            : (booking == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      child: _buildContent(context, booking, isDesktop: false),
                    )),
      ),
      desktop: DesktopScaffold(
        widthTier: DesktopWidthTier.standard,
        child: bookingAsync.hasError
            ? _buildErrorState()
            : (booking == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DesktopSection(
                            title: 'Garage Booking',
                            subtitle: 'Service request details',
                            padding: EdgeInsets.only(top: 28, bottom: 12),
                            child: SizedBox.shrink(),
                          ),
                          _buildContent(context, booking, isDesktop: true),
                          const SiteFooter(),
                          const SizedBox(height: 120),
                        ],
                      ),
                    )),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong loading this booking.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ServiceBooking booking, {
    required bool isDesktop,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusCard(context, booking.status),
        const SizedBox(height: 24),
        Text('Vehicle', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        _buildVehicleCard(context, booking),
        const SizedBox(height: 24),
        Text('Booking Details', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        _buildBookingInfoCard(context, booking),
        const SizedBox(height: 24),
        Text('Services', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        _buildServicesList(context, booking.services),
        const SizedBox(height: 24),
        if (booking.serviceDescription.isNotEmpty) ...[
          Text('Notes', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              booking.serviceDescription,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, String status) {
    Color color;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.blue;
        icon = Icons.check_circle_outline;
        label = 'Confirmed';
        break;
      case 'mechanic_assigned':
      case 'in_progress':
        color = Colors.orange;
        icon = Icons.build_circle_outlined;
        label = 'In progress';
        break;
      case 'completed':
        color = AppColors.success;
        icon = Icons.done_all;
        label = 'Completed';
        break;
      case 'cancelled':
        color = AppColors.error;
        icon = Icons.cancel_outlined;
        label = 'Cancelled';
        break;
      default:
        color = AppColors.warning;
        icon = Icons.access_time;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, ServiceBooking booking) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking.vehicleYear} ${booking.vehicleBrand} ${booking.vehicleModel}',
                  style: AppTextStyles.h4.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.bookingNumber ?? booking.id ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingInfoCard(BuildContext context, ServiceBooking booking) {
    final theme = Theme.of(context);
    final date = booking.pickupDate;
    final dateStr = DateFormat('EEE, dd MMM yyyy').format(date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            icon: Icons.calendar_today,
            label: 'Pickup date',
            value: '$dateStr • ${booking.pickupTime}',
          ),
          const Divider(height: 24),
          _infoRow(
            icon: Icons.location_on_outlined,
            label: 'Pickup location',
            value: booking.pickupLocation,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesList(BuildContext context, List<String> services) {
    final theme = Theme.of(context);

    if (services.isEmpty) {
      return Text(
        'No services listed',
        style: AppTextStyles.bodyMedium.copyWith(color: theme.hintColor),
      );
    }

    return Column(
      children: services.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.check, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(s, style: AppTextStyles.bodyMedium)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
