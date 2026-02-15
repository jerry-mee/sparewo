// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServiceBooking _$ServiceBookingFromJson(Map<String, dynamic> json) =>
    _ServiceBooking(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      userEmail: json['userEmail'] as String,
      userName: json['userName'] as String,
      userPhone: json['userPhone'] as String?,
      vehicleBrand: json['vehicleBrand'] as String,
      vehicleModel: json['vehicleModel'] as String,
      vehicleYear: (json['vehicleYear'] as num).toInt(),
      services: (json['services'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      serviceDescription: json['serviceDescription'] as String,
      pickupDate: const TimestampConverter().fromJson(
        json['pickupDate'] as Object,
      ),
      pickupTime: json['pickupTime'] as String,
      pickupLocation: json['pickupLocation'] as String,
      status: json['status'] as String? ?? 'pending',
      bookingNumber: json['bookingNumber'] as String?,
      notes: json['notes'] as String?,
      createdAt: const NullableTimestampConverter().fromJson(json['createdAt']),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$ServiceBookingToJson(
  _ServiceBooking instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'userEmail': instance.userEmail,
  'userName': instance.userName,
  'userPhone': instance.userPhone,
  'vehicleBrand': instance.vehicleBrand,
  'vehicleModel': instance.vehicleModel,
  'vehicleYear': instance.vehicleYear,
  'services': instance.services,
  'serviceDescription': instance.serviceDescription,
  'pickupDate': const TimestampConverter().toJson(instance.pickupDate),
  'pickupTime': instance.pickupTime,
  'pickupLocation': instance.pickupLocation,
  'status': instance.status,
  'bookingNumber': instance.bookingNumber,
  'notes': instance.notes,
  'createdAt': const NullableTimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
};
