// lib/features/home/application/home_notification_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_client/features/my_car/application/car_provider.dart';
import 'package:sparewo_client/features/shared/services/notification_service.dart';

// This provider should be watched in the HomeScreen `build` or `initState`
final homeNotificationLogicProvider = FutureProvider<void>((ref) async {
  // 1. Wait for the user's car list to be loaded
  final cars = await ref.watch(carsProvider.future);
  final notificationService = ref.read(notificationServiceProvider);

  // 2. Logic: Add Car Nudge
  if (cars.isEmpty) {
    // If no cars, check if we should schedule the 10-day nudge
    await notificationService.checkAndScheduleAddCarNudge(0);
  } else {
    // 3. Logic: Insurance Expiry Reminder
    for (final car in cars) {
      if (car.insuranceExpiryDate != null) {
        final daysLeft = car.insuranceExpiryDate!
            .difference(DateTime.now())
            .inDays;

        // Exact requirement: Only if less than 8 days
        if (daysLeft >= 0 && daysLeft < 8) {
          await notificationService.scheduleDailyInsuranceReminder(
            carName: car.displayName,
            daysLeft: daysLeft,
          );
        }
      }
    }
  }
});
