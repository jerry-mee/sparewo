// lib/features/shared/providers/email_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_client/features/shared/services/email_service.dart';

// 1. Service Provider
final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService();
});

// 2. Email Notifier
final emailNotifierProvider = AsyncNotifierProvider<EmailNotifier, void>(
  EmailNotifier.new,
);

class EmailNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  Future<bool> sendOrderConfirmation({
    required String to,
    required String orderNumber,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String deliveryDate,
  }) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(emailServiceProvider);
      final result = await service.sendOrderConfirmation(
        to: to,
        orderNumber: orderNumber,
        customerName: customerName,
        items: items,
        totalAmount: totalAmount,
        deliveryDate: deliveryDate,
      );

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> sendServiceBookingConfirmation({
    required String to,
    required String customerName,
    required String bookingNumber,
    required List<String> services,
    required String carDetails,
    required String dateTime,
    required String location,
    String? notes,
  }) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(emailServiceProvider);
      final result = await service.sendServiceBookingConfirmation(
        to: to,
        customerName: customerName,
        bookingNumber: bookingNumber,
        services: services,
        carDetails: carDetails,
        dateTime: dateTime,
        location: location,
        notes: notes,
      );

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> sendServiceBookingAdminCopy({
    required String bookingNumber,
    required List<String> services,
    required String carDetails,
    required String dateTime,
    required String location,
    required String customerEmail,
    required String customerName,
    String? notes,
  }) async {
    // We don't set global loading state for admin copies to avoid blocking UI
    try {
      final service = ref.read(emailServiceProvider);
      return await service.sendServiceBookingAdminCopy(
        bookingNumber: bookingNumber,
        services: services,
        carDetails: carDetails,
        dateTime: dateTime,
        location: location,
        customerEmail: customerEmail,
        customerName: customerName,
        notes: notes,
      );
    } catch (e) {
      // Log error but don't fail the flow
      print("Failed to send admin email: $e");
      return false;
    }
  }

  Future<bool> sendWelcomeEmail({
    required String to,
    required String customerName,
  }) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(emailServiceProvider);
      final result = await service.sendWelcomeEmail(
        to: to,
        customerName: customerName,
      );

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
