// lib/models/settings.dart

class Settings {
  final bool isDarkMode;
  final String language;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool orderNotifications;
  final bool stockAlerts;
  final bool promotionAlerts;
  final int maxOrderNotifications;
  final String dateFormat;
  final String currency;

  const Settings({
    this.isDarkMode = false,
    this.language = 'English',
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.orderNotifications = true,
    this.stockAlerts = true,
    this.promotionAlerts = true,
    this.maxOrderNotifications = 100,
    this.dateFormat = "dd/MM/yyyy",
    this.currency = "UGX",
  });

  Settings copyWith({
    bool? isDarkMode,
    String? language,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? orderNotifications,
    bool? stockAlerts,
    bool? promotionAlerts,
    int? maxOrderNotifications,
    String? dateFormat,
    String? currency,
  }) {
    return Settings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      orderNotifications: orderNotifications ?? this.orderNotifications,
      stockAlerts: stockAlerts ?? this.stockAlerts,
      promotionAlerts: promotionAlerts ?? this.promotionAlerts,
      maxOrderNotifications:
          maxOrderNotifications ?? this.maxOrderNotifications,
      dateFormat: dateFormat ?? this.dateFormat,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'orderNotifications': orderNotifications,
      'stockAlerts': stockAlerts,
      'promotionAlerts': promotionAlerts,
      'maxOrderNotifications': maxOrderNotifications,
      'dateFormat': dateFormat,
      'currency': currency,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      isDarkMode: json['isDarkMode'] ?? false,
      language: json['language'] ?? 'English',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      orderNotifications: json['orderNotifications'] ?? true,
      stockAlerts: json['stockAlerts'] ?? true,
      promotionAlerts: json['promotionAlerts'] ?? true,
      maxOrderNotifications: json['maxOrderNotifications'] ?? 100,
      dateFormat: json['dateFormat'] ?? "dd/MM/yyyy",
      currency: json['currency'] ?? "UGX",
    );
  }
}
