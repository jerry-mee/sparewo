// lib/features/shared/services/notification_service.dart
import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
  }
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get foregroundStream =>
      _foregroundMessageController.stream;

  // Preferences Keys
  static const String _prefKeyHideAddCar = 'notification_hide_add_car_nudge';
  static const String _prefKeyLastNudgeDate = 'notification_last_nudge_date';

  Future<void> init() async {
    // Initialize Timezones for scheduling
    tz.initializeTimeZones();

    // Setup Firebase Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request Permissions (Android 13+)
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    // Request Permissions (iOS/Firebase)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      AppLogger.warn(
        'NotificationService',
        'User declined notification permissions',
      );
    }

    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleLocalNotificationTap(response.payload);
      },
    );

    // Create Notification Channel (Android)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'sparewo_updates',
      'SpareWo Updates',
      description: 'Order status and booking updates',
      importance: Importance.max,
      ledColor: AppColors.primary,
      playSound: true,
    );

    final platform = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await platform?.createNotificationChannel(channel);

    // Listen to Foreground FCM Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info(
        'NotificationService',
        'Received Foreground Message',
        extra: {'title': message.notification?.title, 'data': message.data},
      );

      _foregroundMessageController.add(message);
      _showRemoteNotification(message);
    });
  }

  /// Displays a notification coming from FCM (Remote)
  void _showRemoteNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        // Removed const because AppColors.primary is not a constant
        NotificationDetails(
          android: AndroidNotificationDetails(
            'sparewo_updates',
            'SpareWo Updates',
            icon: '@mipmap/ic_launcher',
            color: AppColors.primary,
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: const BigTextStyleInformation(''),
          ),
        ),
        payload: _encodePayload(message.data),
      );
    }
  }

  /// Generic method to show a local notification immediately
  /// Added to satisfy AutoHubProvider calls
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Removed const because AppColors.primary is not a constant
    final androidDetails = AndroidNotificationDetails(
      'sparewo_updates',
      'SpareWo Updates',
      channelDescription: 'General updates',
      importance: Importance.max,
      priority: Priority.high,
      color: AppColors.primary,
      styleInformation: BigTextStyleInformation(body),
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  // --- 1. Booking Success Notification (Polite & Beautiful) ---
  Future<void> showBookingReceived({
    required String bookingNumber,
    required String vehicleName,
  }) async {
    // Removed const because AppColors.primary is not a constant
    final androidDetails = AndroidNotificationDetails(
      'sparewo_updates',
      'SpareWo Updates',
      channelDescription: 'Booking and Order updates',
      importance: Importance.max,
      priority: Priority.high,
      color: AppColors.primary,
      styleInformation: BigTextStyleInformation(
        'We have successfully received your booking request for the $vehicleName. A member of our team is reviewing it and will assign a mechanic shortly.',
        contentTitle: 'Booking Request Received',
        summaryText: 'AutoHub Service',
      ),
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecond,
      'Booking Request Received',
      'We have received your request for $vehicleName. Reference: $bookingNumber',
      details,
      payload: '{"type": "booking", "id": "$bookingNumber"}',
    );
  }

  // --- 2. Daily Insurance Reminder (Dismissible, Morning) ---
  Future<void> scheduleDailyInsuranceReminder({
    required String carName,
    required int daysLeft,
  }) async {
    // Only schedule if < 8 days
    if (daysLeft > 8 || daysLeft < 0) return;

    final now = tz.TZDateTime.now(tz.local);
    // Schedule for 8:00 AM
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      8,
      0,
    );

    // If 8 AM passed, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Removed const because AppColors.warning is not a constant
    final androidDetails = AndroidNotificationDetails(
      'sparewo_reminders',
      'Reminders',
      channelDescription: 'Insurance and Service reminders',
      importance: Importance.high,
      priority: Priority.high,
      color: AppColors.warning,
      styleInformation: BigTextStyleInformation(
        'Your insurance for $carName expires in exactly $daysLeft days. Tap here to renew it now and avoid penalties.',
        contentTitle: 'Insurance Expiry Warning',
      ),
    );

    // Use a unique ID based on car name hash to prevent duplicates
    await _localNotifications.zonedSchedule(
      ('ins_$carName').hashCode,
      'Insurance Expiring Soon',
      'Your $carName insurance expires in $daysLeft days.',
      scheduledDate,
      NotificationDetails(android: androidDetails),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '{"type": "insurance", "car": "$carName"}',
    );
  }

  // --- 3. Add Car Nudge (Every 10 days, polite) ---
  Future<void> checkAndScheduleAddCarNudge(int userCarCount) async {
    // If user already has cars, don't nudge
    if (userCarCount > 0) return;

    final prefs = await SharedPreferences.getInstance();
    // Check if user opted out "Don't ask me again"
    final bool hideNudge = prefs.getBool(_prefKeyHideAddCar) ?? false;
    if (hideNudge) return;

    // Check last nudge date (Frequency 10 days)
    final String? lastNudgeStr = prefs.getString(_prefKeyLastNudgeDate);
    if (lastNudgeStr != null) {
      final lastNudge = DateTime.parse(lastNudgeStr);
      final difference = DateTime.now().difference(lastNudge).inDays;
      if (difference < 10) return; // Wait until 10 days pass
    }

    // Schedule Nudge for tomorrow morning at 10 AM
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      10,
      0,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Removed const because AppColors.primary is not a constant
    final androidDetails = AndroidNotificationDetails(
      'sparewo_tips',
      'Tips & Setup',
      channelDescription: 'Profile setup reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: AppColors.primary,
      styleInformation: BigTextStyleInformation(
        'Adding your car to your profile unlocks tailored discounts and keeps your service history organized. It only takes 30 seconds!',
        contentTitle: 'Get the most out of SpareWo',
      ),
    );

    await _localNotifications.zonedSchedule(
      999, // Fixed ID for the nudge
      'Add your vehicle?',
      'Unlock tailored discounts by adding your car.',
      scheduledDate,
      NotificationDetails(android: androidDetails),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '{"type": "add_car_nudge"}',
    );

    // Update last nudge date immediately so we don't spam logic
    await prefs.setString(
      _prefKeyLastNudgeDate,
      DateTime.now().toIso8601String(),
    );
  }

  // Called when user selects "Don't ask me again" in the UI
  Future<void> disableAddCarNudge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyHideAddCar, true);
    // Cancel any pending nudge
    await _localNotifications.cancel(999);
  }

  // --- Navigation & Payload Handling ---

  void _handleLocalNotificationTap(String? payload) {
    if (payload == null) return;
    AppLogger.ui('Notification', 'Tapped', details: payload);
    // Note: Actual navigation happens via router listener or interaction callback
  }

  // Check if app was launched from notification (Cold boot or Background)
  Future<void> setupInteractedMessage(GoRouter router) async {
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(initialMessage.data, router);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message.data, router);
    });
  }

  void _handleNavigation(Map<String, dynamic> data, GoRouter router) {
    final type = data['type'];
    final id = data['id'];

    if (type == 'order' && id != null) {
      router.push('/order/$id');
    } else if (type == 'booking' && id != null) {
      router.push('/booking/$id'); // Ensure booking detail route exists
    } else if (type == 'add_car_nudge') {
      // Pass a query param to trigger the "Don't ask again" dialog
      router.push('/add-car?nudge=true');
    }
  }

  String _encodePayload(Map<String, dynamic> data) {
    return data.toString();
  }

  void dispose() {
    _foregroundMessageController.close();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
