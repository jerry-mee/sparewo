// lib/features/autohub/domain/service_booking_model.dart
// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparewo_client/core/utils/timestamp_converter.dart';

part 'service_booking_model.freezed.dart';
part 'service_booking_model.g.dart';

@freezed
abstract class ServiceBooking with _$ServiceBooking {
  const factory ServiceBooking({
    String? id,
    required String userId,
    required String userEmail,
    required String userName,
    String? userPhone,
    required String vehicleBrand,
    required String vehicleModel,
    required int vehicleYear,
    required List<String> services,
    required String serviceDescription,
    @TimestampConverter() required DateTime pickupDate,
    required String pickupTime,
    required String pickupLocation,
    @Default('pending') String status,
    String? bookingNumber,
    String? notes,
    @NullableTimestampConverter() DateTime? createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _ServiceBooking;

  factory ServiceBooking.fromJson(Map<String, dynamic> json) =>
      _$ServiceBookingFromJson(json);
}

// Enums and Classes
enum ServiceType {
  oilChange('Oil Change', 'Engine oil and filter replacement'),
  brakeService('Brake Service', 'Brake pads, discs, and fluid check'),
  tireRotation('Tire Service', 'Tire rotation, balancing, and alignment'),
  generalInspection('General Inspection', 'Complete vehicle health check'),
  engineDiagnostic(
    'Engine Diagnostic',
    'Computer diagnostic and troubleshooting',
  ),
  transmission('Transmission Service', 'Transmission fluid and filter change'),
  suspension('Suspension Repair', 'Shocks, struts, and alignment'),
  electrical('Electrical System', 'Battery, alternator, and wiring'),
  airConditioning('AC Service', 'AC inspection and refrigerant recharge'),
  other('Other Service', 'Custom service request');

  final String displayName;
  final String description;
  const ServiceType(this.displayName, this.description);
}

class TimeSlot {
  final String time;
  final String display;
  final bool isAvailable;

  const TimeSlot({
    required this.time,
    required this.display,
    this.isAvailable = true,
  });

  static List<TimeSlot> getAvailableSlots() {
    return [
      const TimeSlot(time: '08:00', display: '8:00 AM'),
      const TimeSlot(time: '09:00', display: '9:00 AM'),
      const TimeSlot(time: '10:00', display: '10:00 AM'),
      const TimeSlot(time: '11:00', display: '11:00 AM'),
      const TimeSlot(time: '12:00', display: '12:00 PM'),
      const TimeSlot(time: '14:00', display: '2:00 PM'),
      const TimeSlot(time: '15:00', display: '3:00 PM'),
      const TimeSlot(time: '16:00', display: '4:00 PM'),
      const TimeSlot(time: '17:00', display: '5:00 PM'),
    ];
  }
}
