// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SettingsImpl _$$SettingsImplFromJson(Map<String, dynamic> json) =>
    _$SettingsImpl(
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      language: json['language'] as String? ?? 'English',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      orderNotifications: json['orderNotifications'] as bool? ?? true,
      stockAlerts: json['stockAlerts'] as bool? ?? true,
      promotionAlerts: json['promotionAlerts'] as bool? ?? true,
      maxOrderNotifications:
          (json['maxOrderNotifications'] as num?)?.toInt() ?? 100,
      dateFormat: json['dateFormat'] as String? ?? "dd/MM/yyyy",
      currency: json['currency'] as String? ?? "UGX",
    );

Map<String, dynamic> _$$SettingsImplToJson(_$SettingsImpl instance) =>
    <String, dynamic>{
      'isDarkMode': instance.isDarkMode,
      'language': instance.language,
      'notificationsEnabled': instance.notificationsEnabled,
      'soundEnabled': instance.soundEnabled,
      'vibrationEnabled': instance.vibrationEnabled,
      'orderNotifications': instance.orderNotifications,
      'stockAlerts': instance.stockAlerts,
      'promotionAlerts': instance.promotionAlerts,
      'maxOrderNotifications': instance.maxOrderNotifications,
      'dateFormat': instance.dateFormat,
      'currency': instance.currency,
    };
