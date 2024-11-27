// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VendorNotificationImpl _$$VendorNotificationImplFromJson(
        Map<String, dynamic> json) =>
    _$VendorNotificationImpl(
      id: json['id'] as String,
      vendorId: json['vendorId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      data: json['data'] as Map<String, dynamic>,
      isRead: json['isRead'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
    );

Map<String, dynamic> _$$VendorNotificationImplToJson(
        _$VendorNotificationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorId': instance.vendorId,
      'title': instance.title,
      'message': instance.message,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'data': instance.data,
      'isRead': instance.isRead,
      'imageUrl': instance.imageUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'readAt': instance.readAt?.toIso8601String(),
    };

const _$NotificationTypeEnumMap = {
  NotificationType.newOrder: 'newOrder',
  NotificationType.orderUpdate: 'orderUpdate',
  NotificationType.stockAlert: 'stockAlert',
  NotificationType.accountUpdate: 'accountUpdate',
  NotificationType.promotion: 'promotion',
  NotificationType.system: 'system',
};
