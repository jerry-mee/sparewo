// lib/features/autohub/application/autohub_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/autohub/data/autohub_repository.dart';
import 'package:sparewo_client/features/autohub/domain/service_booking_model.dart';
import 'package:sparewo_client/features/shared/providers/email_provider.dart';
import 'package:sparewo_client/features/shared/services/notification_service.dart';
import 'package:uuid/uuid.dart';

// --- Repository Provider ---
final autoHubRepositoryProvider = Provider<AutoHubRepository>((ref) {
  return AutoHubRepository(firestore: FirebaseFirestore.instance);
});

// --- Time Slots Provider ---
final availableTimeSlotsProvider =
    FutureProvider.family<List<TimeSlot>, DateTime>((ref, date) async {
      final repository = ref.watch(autoHubRepositoryProvider);
      return repository.getAvailableTimeSlots(date);
    });

// --- State Class ---
class BookingState {
  final String? brand;
  final String? model;
  final int? year;
  final List<String> services;
  final String? description;
  final DateTime? pickupDate;
  final String? pickupTime;
  final String? pickupLocation;
  final bool isLoading;

  BookingState({
    this.brand,
    this.model,
    this.year,
    this.services = const [],
    this.description,
    this.pickupDate,
    this.pickupTime,
    this.pickupLocation,
    this.isLoading = false,
  });

  BookingState copyWith({
    String? brand,
    String? model,
    int? year,
    List<String>? services,
    String? description,
    DateTime? pickupDate,
    String? pickupTime,
    String? pickupLocation,
    bool? isLoading,
  }) {
    return BookingState(
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      services: services ?? this.services,
      description: description ?? this.description,
      pickupDate: pickupDate ?? this.pickupDate,
      pickupTime: pickupTime ?? this.pickupTime,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final bookingFlowNotifierProvider =
    NotifierProvider<BookingFlowNotifier, BookingState>(
      BookingFlowNotifier.new,
    );

class BookingFlowNotifier extends Notifier<BookingState> {
  @override
  BookingState build() => BookingState();

  void setVehicle(String brand, String model, int year) {
    state = state.copyWith(brand: brand, model: model, year: year);
  }

  void toggleService(String service) {
    final list = List<String>.from(state.services);
    if (list.contains(service)) {
      list.remove(service);
    } else {
      list.add(service);
    }
    state = state.copyWith(services: list);
  }

  void setServiceDescription(String desc) {
    state = state.copyWith(description: desc);
  }

  void setPickupDateTime(DateTime date, String time) {
    state = state.copyWith(pickupDate: date, pickupTime: time);
  }

  void setPickupLocation(String location) {
    state = state.copyWith(pickupLocation: location);
  }

  Future<ServiceBooking?> submitBooking() async {
    state = state.copyWith(isLoading: true);

    try {
      final user = ref.read(currentUserProvider).asData?.value;
      if (user == null) {
        AppLogger.warn('submitBooking.noUser', 'User not logged in');
        throw Exception('User not logged in');
      }

      // Generate IDs
      final bookingId = FirebaseFirestore.instance
          .collection('service_bookings')
          .doc()
          .id;
      final bookingNumber =
          'SW-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}-${const Uuid().v4().substring(0, 4).toUpperCase()}';

      AppLogger.info(
        'submitBooking.start',
        'Creating new booking',
        extra: {
          'userId': user.id,
          'bookingId': bookingId,
          'bookingNumber': bookingNumber,
          'brand': state.brand,
          'model': state.model,
          'year': state.year,
          'services': state.services,
          'pickupDate': state.pickupDate?.toIso8601String(),
          'pickupTime': state.pickupTime,
          'pickupLocation': state.pickupLocation,
        },
      );

      // Map state to your Freezed Model
      final newBooking = ServiceBooking(
        id: bookingId,
        userId: user.id,
        userName: user.name,
        userEmail: user.email ?? '',
        userPhone: user.phone ?? '',
        vehicleBrand: state.brand ?? '',
        vehicleModel: state.model ?? '',
        vehicleYear: state.year ?? DateTime.now().year,
        services: state.services,
        serviceDescription: state.description ?? '',
        pickupDate: state.pickupDate ?? DateTime.now(),
        pickupTime: state.pickupTime ?? '',
        pickupLocation: state.pickupLocation ?? '',
        bookingNumber: bookingNumber,
        status: 'pending', // Correct usage as String
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save via Repository
      final repository = ref.read(autoHubRepositoryProvider);
      await repository.createBooking(newBooking);

      AppLogger.info(
        'submitBooking.success',
        'Booking stored + emails queued',
        extra: {'bookingId': bookingId, 'bookingNumber': bookingNumber},
      );

      // --- Trigger Emails ---
      final dateStr =
          "${state.pickupDate?.day}/${state.pickupDate?.month}/${state.pickupDate?.year} at ${state.pickupTime}";
      final vehicleStr = "${state.year} ${state.brand} ${state.model}";

      if (user.email != null) {
        await ref
            .read(emailNotifierProvider.notifier)
            .sendServiceBookingConfirmation(
              to: user.email!,
              customerName: user.name,
              bookingNumber: bookingNumber,
              services: state.services,
              carDetails: vehicleStr,
              dateTime: dateStr,
              location: state.pickupLocation ?? 'Unknown',
              notes: state.description,
            );
      }

      await ref
          .read(emailNotifierProvider.notifier)
          .sendServiceBookingAdminCopy(
            bookingNumber: bookingNumber,
            services: state.services,
            carDetails: vehicleStr,
            dateTime: dateStr,
            location: state.pickupLocation ?? 'Unknown',
            customerEmail: user.email ?? 'No Email',
            customerName: user.name,
            notes: state.description,
          );

      // --- Trigger Local Notification ---
      // This call now works because we added showLocalNotification to the Service
      ref
          .read(notificationServiceProvider)
          .showLocalNotification(
            id: bookingId.hashCode,
            title: 'Booking Placed',
            body:
                'Your service for $vehicleStr has been booked successfully. Ref: $bookingNumber',
          );

      // Reset state
      state = BookingState();
      return newBooking;
    } catch (e, st) {
      AppLogger.error(
        'submitBooking.error',
        e.toString(),
        stackTrace: st,
        extra: {
          'brand': state.brand,
          'model': state.model,
          'year': state.year,
          'services': state.services,
          'pickupDate': state.pickupDate?.toIso8601String(),
          'pickupTime': state.pickupTime,
          'pickupLocation': state.pickupLocation,
        },
      );
      state = state.copyWith(isLoading: false);
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
