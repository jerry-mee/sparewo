// lib/features/shared/services/notification_service.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:sparewo_client/core/notifications/fcm_background_handler.dart';

// Removed local background handler as it is now in core/notifications/fcm_background_handler.dart

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get foregroundStream =>
      _foregroundMessageController.stream;

  String? _currentUserId;
  StreamSubscription? _firestoreNotifSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  GoRouter? _router;
  bool _hasLoggedApnsPending = false;

  // Preferences Keys
  static const String _prefKeyHideAddCar = 'notification_hide_add_car_nudge';
  static const String _prefKeyLastNudgeDate = 'notification_last_nudge_date';

  Future<void> init() async {
    if (kIsWeb) {
      AppLogger.info('NotificationService', 'Skipping init on web');
      return;
    }

    // Initialize Timezones for scheduling
    tz.initializeTimeZones();

    // Setup Firebase Background Handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await updateToken();
    _tokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen((
      token,
    ) {
      AppLogger.info(
        'NotificationService',
        'FCM token refreshed',
        extra: {'tokenPresent': token.isNotEmpty},
      );
      if (_currentUserId != null) {
        saveTokenToFirestore(_currentUserId!, token);
      }
    });

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
    const AndroidNotificationChannel updatesChannel =
        AndroidNotificationChannel(
          'sparewo_updates',
          'SpareWo Updates',
          description: 'Order status and booking updates',
          importance: Importance.max,
          ledColor: AppColors.primary,
          playSound: true,
        );
    const AndroidNotificationChannel remindersChannel =
        AndroidNotificationChannel(
          'sparewo_reminders',
          'Reminders',
          description: 'Insurance and service reminders',
          importance: Importance.high,
          playSound: true,
        );
    const AndroidNotificationChannel tipsChannel = AndroidNotificationChannel(
      'sparewo_tips',
      'Tips & Setup',
      description: 'Setup and feature nudges',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    final platform = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await platform?.createNotificationChannel(updatesChannel);
    await platform?.createNotificationChannel(remindersChannel);
    await platform?.createNotificationChannel(tipsChannel);

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

  void startFirestoreNotificationListener(String userId) {
    _firestoreNotifSubscription?.cancel();
    _currentUserId = userId;

    _firestoreNotifSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data();
                if (data != null) {
                  // Convert Firestore doc to a RemoteMessage-like structure for the UI
                  final title = data['title'] ?? 'SpareWo Update';
                  final body = data['message'] ?? '';
                  final safeData = _toJsonSafeMap(data);
                  final payloadData = _notificationPayloadFromDoc(safeData);

                  // Broadcast to foreground stream for in-app UI.
                  // System-level delivery is handled by FCM push fanout from Cloud Functions.
                  _foregroundMessageController.add(
                    RemoteMessage(
                      notification: RemoteNotification(
                        title: title,
                        body: body,
                      ),
                      data: Map<String, String>.from(
                        payloadData.map(
                          (key, value) => MapEntry(key, value.toString()),
                        ),
                      ),
                    ),
                  );
                }
              }
            }
          },
          onError: (error, stack) {
            if (error is FirebaseException &&
                (error.code == 'permission-denied' ||
                    error.code == 'unauthenticated')) {
              AppLogger.warn(
                'NotificationService',
                'Notifications listener stopped due to auth state change',
                extra: {'userId': userId, 'code': error.code},
              );
              stopFirestoreNotificationListener();
              return;
            }
            AppLogger.error(
              'NotificationService',
              'Firestore notifications listener failed',
              error: error,
              stackTrace: stack,
              extra: {'userId': userId},
            );
          },
        );
  }

  void stopFirestoreNotificationListener() {
    _firestoreNotifSubscription?.cancel();
    _firestoreNotifSubscription = null;
    _currentUserId = null;
  }

  Future<void> updateToken([String? userId]) async {
    if (userId != null) _currentUserId = userId;

    try {
      if (Platform.isIOS) {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null || apnsToken.isEmpty) {
          if (!_hasLoggedApnsPending) {
            AppLogger.info(
              'NotificationService',
              'APNS token not ready yet; waiting for iOS registration callback',
            );
            _hasLoggedApnsPending = true;
          }
          return;
        }
        _hasLoggedApnsPending = false;
      }

      final token = await _firebaseMessaging.getToken();
      if (token != null && token.isNotEmpty) {
        _hasLoggedApnsPending = false;
        AppLogger.info(
          'NotificationService',
          'Initial FCM token fetched',
          extra: {'tokenPresent': true},
        );

        if (userId != null) {
          await saveTokenToFirestore(userId, token);
        }
      }
    } catch (error, stackTrace) {
      final message = error.toString();
      final isApnsRace =
          Platform.isIOS && message.contains('apns-token-not-set');
      if (isApnsRace) {
        if (!_hasLoggedApnsPending) {
          AppLogger.info(
            'NotificationService',
            'APNS token not set yet; token fetch will retry on refresh',
          );
          _hasLoggedApnsPending = true;
        }
        return;
      }

      AppLogger.error(
        'NotificationService',
        'Failed to fetch FCM token',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> saveTokenToFirestore(String userId, String token) async {
    try {
      final tokenRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc(token);

      await tokenRef.set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
        'lastUsed': FieldValue.serverTimestamp(),
      });

      AppLogger.info('NotificationService', 'FCM token saved to Firestore');
    } catch (e) {
      AppLogger.error(
        'NotificationService',
        'Failed to save FCM token',
        error: e,
      );
    }
  }

  /// Displays a notification coming from FCM (Remote)
  void _showRemoteNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'sparewo_updates',
            'SpareWo Updates',
            icon: '@mipmap/ic_launcher',
            color: AppColors.primary,
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(),
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

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  // --- 1. Booking Success Notification (Polite & Beautiful) ---
  Future<void> showBookingReceived({
    required String bookingNumber,
    required String vehicleName,
    String? bookingId,
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

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      'Booking Request Received',
      'We have received your request for $vehicleName. Reference: $bookingNumber',
      details,
      payload: jsonEncode({
        'type': 'booking',
        'id': bookingId ?? bookingNumber,
      }),
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
    const androidDetails = AndroidNotificationDetails(
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
      const NotificationDetails(android: androidDetails),
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
    final router = _router;
    if (router == null) return;
    final decoded = _decodePayload(payload);
    if (decoded == null) return;
    _handleNavigation(decoded, router);
  }

  // Check if app was launched from notification (Cold boot or Background)
  Future<void> setupInteractedMessage(GoRouter router) async {
    _router = router;
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
    final type = data['type']?.toString();
    final id = data['id']?.toString();
    final link = data['link']?.toString();

    if (link != null && link.isNotEmpty && link.startsWith('/')) {
      _navigateSafely(router, link);
      return;
    }

    if (type == 'order' && id != null) {
      _navigateSafely(router, '/order/$id');
    } else if (type == 'booking' && id != null) {
      _navigateSafely(router, '/booking/$id');
    } else if (type == 'add_car_nudge') {
      _navigateSafely(router, '/add-car?nudge=true');
    }
  }

  void _navigateSafely(GoRouter router, String location) {
    final current = router.routeInformationProvider.value.uri.toString();
    if (current == location) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        router.go(location);
      } catch (error, stackTrace) {
        AppLogger.error(
          'NotificationService',
          'Navigation from notification failed',
          error: error,
          stackTrace: stackTrace,
          extra: {'location': location},
        );
      }
    });
  }

  String _encodePayload(Map<String, dynamic> data) {
    return jsonEncode(_toJsonSafeMap(data));
  }

  Map<String, dynamic>? _decodePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _notificationPayloadFromDoc(Map<String, dynamic> data) {
    final payload = <String, dynamic>{...data};
    payload['title'] = payload['title']?.toString() ?? 'SpareWo Update';
    payload['message'] = payload['message']?.toString() ?? '';

    final link = payload['link']?.toString();
    if (link != null && link.startsWith('/booking/')) {
      payload['type'] = 'booking';
      payload['id'] = link.split('/').last;
    } else if (link != null && link.startsWith('/order/')) {
      payload['type'] = 'order';
      payload['id'] = link.split('/').last;
    }

    return payload;
  }

  Map<String, dynamic> _toJsonSafeMap(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _toJsonSafeValue(value)));
  }

  dynamic _toJsonSafeValue(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map(
        (key, nestedValue) =>
            MapEntry(key.toString(), _toJsonSafeValue(nestedValue)),
      );
    }
    if (value is Iterable) {
      return value.map(_toJsonSafeValue).toList(growable: false);
    }
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    return value.toString();
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _firestoreNotifSubscription?.cancel();
    _foregroundMessageController.close();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
