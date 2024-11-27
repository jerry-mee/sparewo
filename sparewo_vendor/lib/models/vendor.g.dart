// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VendorImpl _$$VendorImplFromJson(Map<String, dynamic> json) => _$VendorImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      businessName: json['businessName'] as String,
      businessAddress: json['businessAddress'] as String,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      profileImage: json['profileImage'] as String?,
      businessHours: json['businessHours'] as Map<String, dynamic>?,
      settings: json['settings'] as Map<String, dynamic>?,
      isVerified: json['isVerified'] as bool? ?? false,
      status: $enumDecode(_$VendorStatusEnumMap, json['status']),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      completedOrders: (json['completedOrders'] as num?)?.toInt() ?? 0,
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      fcmToken: json['fcmToken'] as String?,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$VendorImplToJson(_$VendorImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'businessName': instance.businessName,
      'businessAddress': instance.businessAddress,
      'categories': instance.categories,
      'profileImage': instance.profileImage,
      'businessHours': instance.businessHours,
      'settings': instance.settings,
      'isVerified': instance.isVerified,
      'status': _$VendorStatusEnumMap[instance.status]!,
      'rating': instance.rating,
      'completedOrders': instance.completedOrders,
      'totalProducts': instance.totalProducts,
      'fcmToken': instance.fcmToken,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$VendorStatusEnumMap = {
  VendorStatus.pending: 'pending',
  VendorStatus.approved: 'approved',
  VendorStatus.suspended: 'suspended',
  VendorStatus.rejected: 'rejected',
};
