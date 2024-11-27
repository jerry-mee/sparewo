import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

@freezed
class Settings with _$Settings {
  const factory Settings({
    @Default(false) bool isDarkMode,
    @Default('English') String language,
    @Default(true) bool notificationsEnabled,
    @Default(true) bool soundEnabled,
    @Default(true) bool vibrationEnabled,
    @Default(true) bool orderNotifications,
    @Default(true) bool stockAlerts,
    @Default(true) bool promotionAlerts,
    @Default(100) int maxOrderNotifications,
    @Default("dd/MM/yyyy") String dateFormat,
    @Default("UGX") String currency,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
}
