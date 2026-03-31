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
  Timer? _firestoreListenerRetryTimer;
  int _firestoreListenerRetryAttempts = 0;
  GoRouter? _router;
  bool _hasLoggedApnsPending = false;
  Timer? _tokenRetryTimer;
  int _tokenRetryAttempts = 0;
  bool _localNotificationsInitialized = false;
  bool _pushTokenRegistered = false;
  String? _subscribedTopicUserId;
  final Set<String> _seenNotificationIdsThisSession = <String>{};
  bool _tokenRetryHardStopped = false;
  bool _hasLoggedTokenPersistPermissionBlock = false;
  bool _hasLoggedFirestoreListenerPermissionBlock = false;
  static const List<String> _notificationRecipientFields = <String>[
    'recipientId',
    'recipientUid',
    'userId',
  ];

  static const Duration _tokenRetryInterval = Duration(seconds: 8);
  static const Duration _firestoreListenerRetryInterval = Duration(seconds: 12);
  static const int _tokenRetryLogInterval = 3;
  static const int _tokenRetryHardCap = 6;
  static const int _firestoreListenerRetryHardCap = 10;
  static const int _notificationFieldRetryCap = 5;
  static const String _userTopicPrefix = "user_";
  static const Duration _fallbackRecencyWindow = Duration(minutes: 2);
  static const String _diagnosticsCollection = 'system_diagnostics_events';

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

    try {
      await _firebaseMessaging.setAutoInitEnabled(true);
    } catch (e) {
      AppLogger.warn(
        'NotificationService',
        'Failed to enable FCM auto init: $e',
      );
    }

    // Initial check of user preferences
    final prefs = await SharedPreferences.getInstance();
    final bool pushEnabled = prefs.getBool('notif_push_enabled') ?? true;

    if (!pushEnabled) {
      AppLogger.info(
        'NotificationService',
        'Push notifications disabled via in-app settings',
      );
      await updateToken(); // Still update token for backend synchronization if needed
      return;
    }

    // Initialize Local Notifications early so foreground fallback can always render.
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
    _localNotificationsInitialized = true;

    // Request Permissions (Android 13+)
    if (Platform.isAndroid) {
      try {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      } catch (e) {
        AppLogger.warn(
          'NotificationService',
          'Android permission request failed: $e',
        );
      }
    }

    // Request Permissions (iOS/Firebase)
    try {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        AppLogger.warn(
          'NotificationService',
          'User declined notification permissions',
          extra: {'status': settings.authorizationStatus.name},
        );
      }
    } catch (e) {
      AppLogger.warn(
        'NotificationService',
        'FCM permission request failed',
        extra: {'error': e.toString()},
      );
    }

    if (Platform.isIOS || Platform.isMacOS) {
      try {
        final darwinPlatform = _localNotifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        await darwinPlatform?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        AppLogger.warn(
          'NotificationService',
          'Darwin local notification permission request failed',
          extra: {'error': e.toString()},
        );
      }
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
        unawaited(updateToken(_currentUserId));
      }
    });
    _scheduleTokenRetryIfNeeded(reason: 'init');

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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      unawaited(
        _recordPushTelemetry(
          event: 'push_received_foreground',
          severity: 'info',
          data: {
            'messageId': message.messageId,
            'type': message.data['type'],
            'hasNotification': message.notification != null,
          },
        ),
      );
      AppLogger.info(
        'NotificationService',
        'Received Foreground Message',
        extra: {'title': message.notification?.title, 'data': message.data},
      );
      final notificationId = message.data['notificationId']?.toString();
      if (notificationId != null && notificationId.isNotEmpty) {
        _seenNotificationIdsThisSession.add(notificationId);
      }

      _foregroundMessageController.add(message);

      // Check in-app preferences before showing local toast/notification
      final prefs = await SharedPreferences.getInstance();
      final bool pushEnabled = prefs.getBool('notif_push_enabled') ?? true;
      if (!pushEnabled) return;

      // Type-based filtering
      final type = message.data['type']?.toString();
      if (type == 'order' || type == 'booking') {
        final ordersEnabled = prefs.getBool('notif_orders_enabled') ?? true;
        if (!ordersEnabled) return;
      } else if (type == 'promo' || type == 'offer') {
        final offersEnabled = prefs.getBool('notif_offers_enabled') ?? true;
        if (!offersEnabled) return;
      }

      await _showRemoteNotification(message);
    });
  }

  void startFirestoreNotificationListener(String userId) {
    _firestoreNotifSubscription?.cancel();
    _firestoreListenerRetryTimer?.cancel();
    if (_currentUserId != userId) {
      _firestoreListenerRetryAttempts = 0;
    }
    _currentUserId = userId;
    _seenNotificationIdsThisSession.clear();
    unawaited(_syncTopicSubscription(userId));
    final previousUnread = <String, bool>{};
    bool consumedInitialSnapshot = false;

    _firestoreNotifSubscription = _safeNotificationSnapshotStream(userId).listen(
      (docs) {
        _firestoreListenerRetryAttempts = 0;
        final currentUnreadById = <String, Map<String, dynamic>>{};
        for (final doc in docs) {
          final notificationId = doc['id']?.toString();
          if (notificationId == null || notificationId.isEmpty) continue;
          if (_isNotificationUnread(doc)) {
            currentUnreadById[notificationId] = doc;
          }
        }

        if (!consumedInitialSnapshot) {
          consumedInitialSnapshot = true;
          previousUnread
            ..clear()
            ..addAll({
              for (final entry in currentUnreadById.entries) entry.key: true,
            });
          return;
        }

        for (final entry in currentUnreadById.entries) {
          final notificationId = entry.key;
          final isPreviouslyUnread = previousUnread[notificationId] == true;
          if (isPreviouslyUnread) continue;

          final data = entry.value;
          final title = data['title'] ?? 'SpareWo Update';
          final body = data['message'] ?? '';
          final payloadData = _notificationPayloadFromDoc(
            data,
            notificationId: notificationId,
          );

          _foregroundMessageController.add(
            RemoteMessage(
              notification: RemoteNotification(title: title, body: body),
              data: Map<String, String>.from(
                payloadData.map(
                  (key, value) => MapEntry(key, value.toString()),
                ),
              ),
            ),
          );

          unawaited(
            _showFirestoreFallbackNotificationIfNeeded(
              notificationId: notificationId,
              title: title.toString(),
              body: body.toString(),
              payloadData: payloadData,
              createdAt: data['createdAt'],
            ),
          );
        }

        previousUnread
          ..clear()
          ..addAll({
            for (final entry in currentUnreadById.entries) entry.key: true,
          });
      },
      onError: (error, stack) {
        if (error is FirebaseException &&
            (error.code == 'permission-denied' ||
                error.code == 'unauthenticated')) {
          if (!_hasLoggedFirestoreListenerPermissionBlock) {
            AppLogger.warn(
              'NotificationService',
              'Notifications listener blocked; scheduling bounded retry window',
              extra: {'userId': userId, 'code': error.code},
            );
            _hasLoggedFirestoreListenerPermissionBlock = true;
          } else {
            AppLogger.debug(
              'NotificationService',
              'Notifications listener still blocked; retrying quietly',
              extra: {'userId': userId, 'code': error.code},
            );
          }
          _firestoreNotifSubscription?.cancel();
          _firestoreNotifSubscription = null;
          _scheduleFirestoreListenerRetry(userId, reason: error.code);
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
    _firestoreListenerRetryTimer?.cancel();
    _firestoreNotifSubscription?.cancel();
    _firestoreNotifSubscription = null;
    _firestoreListenerRetryAttempts = 0;
    _hasLoggedFirestoreListenerPermissionBlock = false;
    _currentUserId = null;
    _pushTokenRegistered = false;
    _seenNotificationIdsThisSession.clear();
    _resetTokenRetryState();
    unawaited(_clearTopicSubscription());
  }

  void _scheduleFirestoreListenerRetry(
    String userId, {
    required String reason,
  }) {
    if (_currentUserId != userId) return;
    if (_firestoreListenerRetryAttempts >= _firestoreListenerRetryHardCap) {
      AppLogger.warn(
        'NotificationService',
        'Notifications listener retries exhausted; keeping safe fallback state',
        extra: {
          'userId': userId,
          'attempts': _firestoreListenerRetryAttempts,
          'reason': reason,
        },
      );
      return;
    }
    _firestoreListenerRetryTimer?.cancel();
    _firestoreListenerRetryTimer = Timer(_firestoreListenerRetryInterval, () {
      if (_currentUserId != userId) return;
      if (_firestoreNotifSubscription != null) return;
      _firestoreListenerRetryAttempts += 1;
      AppLogger.info(
        'NotificationService',
        'Retrying Firestore notifications listener',
        extra: {
          'userId': userId,
          'reason': reason,
          'attempt': _firestoreListenerRetryAttempts,
        },
      );
      startFirestoreNotificationListener(userId);
    });
  }

  Future<void> updateToken([String? userId]) async {
    if (userId != null) _currentUserId = userId;

    try {
      if (Platform.isIOS) {
        final settings = await _firebaseMessaging.getNotificationSettings();
        final status = settings.authorizationStatus;
        if (status == AuthorizationStatus.denied) {
          _pushTokenRegistered = false;
          AppLogger.warn(
            'NotificationService',
            'iOS notifications are denied at system level',
          );
          return;
        }

        final apnsToken = await _firebaseMessaging.getAPNSToken();
        final hasApnsToken = apnsToken != null && apnsToken.isNotEmpty;
        if (!hasApnsToken) {
          if (!_hasLoggedApnsPending) {
            AppLogger.info(
              'NotificationService',
              'APNS token not ready yet; waiting for iOS registration callback',
            );
            _hasLoggedApnsPending = true;
          }
          _scheduleTokenRetryIfNeeded(reason: 'apns_pending');
        } else {
          _hasLoggedApnsPending = false;
        }
      }

      final token = await _firebaseMessaging.getToken();
      if (token != null && token.isNotEmpty) {
        _hasLoggedApnsPending = false;
        AppLogger.info(
          'NotificationService',
          'FCM token fetched',
          extra: {'tokenPresent': true, 'uid': _currentUserId},
        );

        if (_currentUserId != null) {
          await _syncTopicSubscription(_currentUserId!);
          final persisted = await saveTokenToFirestore(_currentUserId!, token);
          _pushTokenRegistered = persisted;
          if (persisted) {
            _resetTokenRetryState();
            return;
          }
          _scheduleTokenRetryIfNeeded(reason: 'token_persist_failed');
          return;
        }
        _pushTokenRegistered = false;
      } else {
        _pushTokenRegistered = false;
        _scheduleTokenRetryIfNeeded(reason: 'token_empty');
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
        _scheduleTokenRetryIfNeeded(reason: 'apns_race');
        return;
      }

      _pushTokenRegistered = false;
      AppLogger.error(
        'NotificationService',
        'Failed to fetch FCM token',
        error: error,
        stackTrace: stackTrace,
      );
      _scheduleTokenRetryIfNeeded(reason: 'token_error');
    }
  }

  Future<bool> saveTokenToFirestore(String userId, String token) async {
    try {
      final userTokenRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc(token);
      final legacyTokenRef = FirebaseFirestore.instance
          .collection('clients')
          .doc(userId)
          .collection('tokens')
          .doc(token);

      final tokenPayload = {
        'token': token,
        'platform': Platform.operatingSystem,
        'lastUsed': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await userTokenRef.set(tokenPayload, SetOptions(merge: true));
      try {
        await legacyTokenRef.set(tokenPayload, SetOptions(merge: true));
      } catch (legacyError) {
        AppLogger.warn(
          'NotificationService',
          'Legacy client token write failed (non-blocking)',
          extra: {'uid': userId, 'error': legacyError.toString()},
        );
      }

      AppLogger.info(
        'NotificationService',
        'FCM token saved to Firestore',
        extra: {
          'uid': userId,
          'platform': Platform.operatingSystem,
          'tokenLength': token.length,
        },
      );
      unawaited(
        _recordPushTelemetry(
          event: 'fcm_token_saved',
          severity: 'info',
          data: {'uid': userId, 'tokenLength': token.length},
        ),
      );
      _hasLoggedTokenPersistPermissionBlock = false;
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        if (!_hasLoggedTokenPersistPermissionBlock) {
          AppLogger.warn(
            'NotificationService',
            'FCM token write blocked by backend policy; entering bounded retry window',
            extra: {'uid': userId, 'code': e.code},
          );
          _hasLoggedTokenPersistPermissionBlock = true;
        } else {
          AppLogger.debug(
            'NotificationService',
            'FCM token write still blocked; retrying quietly',
            extra: {'uid': userId, 'code': e.code},
          );
        }
        unawaited(
          _recordPushTelemetry(
            event: 'fcm_token_save_blocked',
            severity: 'warn',
            data: {'uid': userId, 'code': e.code},
          ),
        );
        return false;
      }
      AppLogger.error(
        'NotificationService',
        'Failed to save FCM token',
        error: e,
      );
      return false;
    } catch (e) {
      AppLogger.error(
        'NotificationService',
        'Failed to save FCM token',
        error: e,
      );
      return false;
    }
  }

  /// Displays a notification coming from FCM (Remote)
  Future<void> _showRemoteNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      final explicitBadge = int.tryParse(
        message.data['badge']?.toString() ?? '',
      );
      await _showLocalSystemNotification(
        title: notification.title ?? 'SpareWo Update',
        body: notification.body ?? '',
        data: Map<String, dynamic>.from(message.data),
        explicitBadge: explicitBadge,
        notificationIdSeed: notification.hashCode,
      );
    }
  }

  Future<void> _showFirestoreFallbackNotificationIfNeeded({
    required String notificationId,
    required String title,
    required String body,
    required Map<String, dynamic> payloadData,
    required dynamic createdAt,
  }) async {
    if (!_localNotificationsInitialized) return;
    if (_pushTokenRegistered) return;
    if (_seenNotificationIdsThisSession.contains(notificationId)) return;
    if (!_isRecentEnoughForFallback(createdAt)) return;

    final prefs = await SharedPreferences.getInstance();
    final pushEnabled = prefs.getBool('notif_push_enabled') ?? true;
    if (!pushEnabled) return;

    final type = payloadData['type']?.toString();
    if (type == 'order' || type == 'booking') {
      final ordersEnabled = prefs.getBool('notif_orders_enabled') ?? true;
      if (!ordersEnabled) return;
    } else if (type == 'promo' || type == 'offer') {
      final offersEnabled = prefs.getBool('notif_offers_enabled') ?? true;
      if (!offersEnabled) return;
    }

    _seenNotificationIdsThisSession.add(notificationId);
    await _showLocalSystemNotification(
      title: title,
      body: body,
      data: payloadData,
    );
  }

  bool _isRecentEnoughForFallback(dynamic rawCreatedAt) {
    final createdAt = _asDateTime(rawCreatedAt);
    if (createdAt == null) return true;
    return DateTime.now().difference(createdAt).abs() <= _fallbackRecencyWindow;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<void> _showLocalSystemNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    int? explicitBadge,
    int? notificationIdSeed,
  }) async {
    final badgeCount = explicitBadge ?? await _fetchUnreadNotificationCount();
    final androidDetails = AndroidNotificationDetails(
      'sparewo_updates',
      'SpareWo Updates',
      icon: '@mipmap/ic_launcher',
      color: AppColors.primary,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
      number: badgeCount,
    );

    final darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: badgeCount,
    );

    final stableId =
        notificationIdSeed ??
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    try {
      await _localNotifications.show(
        stableId,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: darwinDetails),
        payload: _encodePayload(data),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'NotificationService',
        'Failed to render local system notification',
        error: error,
        stackTrace: stackTrace,
        extra: {'title': title, 'dataKeys': data.keys.toList()},
      );
    }
  }

  Future<int?> _fetchUnreadNotificationCount() async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return null;
    try {
      final unreadIds = <String>{};
      for (final field in _notificationRecipientFields) {
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('notifications')
              .where(field, isEqualTo: uid)
              .get();
          for (final doc in snapshot.docs) {
            final data = doc.data();
            if (_isNotificationUnread(data)) {
              unreadIds.add(doc.id);
            }
          }
        } on FirebaseException catch (error) {
          if (error.code == 'permission-denied' ||
              error.code == 'unauthenticated') {
            continue;
          }
          rethrow;
        }
      }
      return unreadIds.length;
    } catch (e) {
      AppLogger.warn(
        'NotificationService',
        'Failed to resolve unread count for badge',
        extra: {'uid': uid, 'error': e.toString()},
      );
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> _safeNotificationSnapshotStream(
    String userId,
  ) {
    return Stream.multi((controller) {
      final firestore = FirebaseFirestore.instance;
      final docsByField = <String, Map<String, Map<String, dynamic>>>{};
      final subscriptions =
          <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
      final retryTimers = <String, Timer>{};
      final retryAttempts = <String, int>{};
      final exhaustedFields = <String>{};
      final warnedFields = <String>{};
      bool allFieldsExhaustedLogged = false;
      bool hasEmitted = false;

      void emit() {
        final merged = <String, Map<String, dynamic>>{};
        for (final docs in docsByField.values) {
          merged.addAll(docs);
        }
        final sorted = merged.values.toList()
          ..sort((a, b) {
            final aDate = _asDateTime(a['createdAt']);
            final bDate = _asDateTime(b['createdAt']);
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate);
          });
        controller.add(sorted);
        hasEmitted = true;
      }

      void attachField(String field) {
        if (exhaustedFields.contains(field)) return;
        final subscription = firestore
            .collection('notifications')
            .where(field, isEqualTo: userId)
            .snapshots()
            .listen(
              (snapshot) {
                final byId = <String, Map<String, dynamic>>{};
                for (final doc in snapshot.docs) {
                  byId[doc.id] = _toJsonSafeMap(doc.data())..['id'] = doc.id;
                }
                retryAttempts.remove(field);
                docsByField[field] = byId;
                emit();
              },
              onError: (error, stack) {
                if (error is FirebaseException &&
                    (error.code == 'permission-denied' ||
                        error.code == 'unauthenticated')) {
                  if (warnedFields.add(field)) {
                    AppLogger.warn(
                      'NotificationService',
                      'Notifications stream blocked; scheduling bounded retry for recipient field',
                      extra: {
                        'userId': userId,
                        'field': field,
                        'code': error.code,
                        'attempt': retryAttempts[field] ?? 0,
                      },
                    );
                  } else {
                    AppLogger.debug(
                      'NotificationService',
                      'Notifications stream still blocked for recipient field',
                      extra: {
                        'userId': userId,
                        'field': field,
                        'code': error.code,
                        'attempt': retryAttempts[field] ?? 0,
                      },
                    );
                  }
                  docsByField.remove(field);
                  final sub = subscriptions.remove(field);
                  sub?.cancel();
                  retryTimers.remove(field)?.cancel();
                  final currentAttempt = retryAttempts[field] ?? 0;
                  if (currentAttempt >= _notificationFieldRetryCap) {
                    exhaustedFields.add(field);
                    AppLogger.warn(
                      'NotificationService',
                      'Notifications stream retries exhausted for recipient field; field circuit opened',
                      extra: {
                        'userId': userId,
                        'field': field,
                        'attempt': currentAttempt,
                      },
                    );
                    if (!allFieldsExhaustedLogged &&
                        exhaustedFields.length ==
                            _notificationRecipientFields.length) {
                      allFieldsExhaustedLogged = true;
                      AppLogger.warn(
                        'NotificationService',
                        'All notification recipient fields exhausted; stream pinned to safe empty fallback',
                        extra: {'userId': userId},
                      );
                    }
                    if (subscriptions.isEmpty) {
                      if (!hasEmitted) {
                        controller.add(const <Map<String, dynamic>>[]);
                        hasEmitted = true;
                      } else {
                        emit();
                      }
                    }
                    return;
                  }
                  if (retryTimers[field] == null) {
                    final nextAttempt = currentAttempt + 1;
                    retryAttempts[field] = nextAttempt;
                    retryTimers[field] = Timer(const Duration(seconds: 4), () {
                      retryTimers.remove(field);
                      if (controller.isClosed) return;
                      if (subscriptions.containsKey(field)) return;
                      if (exhaustedFields.contains(field)) return;
                      attachField(field);
                    });
                  }
                  if (subscriptions.isEmpty) {
                    if (!hasEmitted) {
                      controller.add(const <Map<String, dynamic>>[]);
                      hasEmitted = true;
                    } else {
                      emit();
                    }
                  }
                  return;
                }
                AppLogger.error(
                  'NotificationService',
                  'Notifications stream listener failed',
                  error: error,
                  stackTrace: stack,
                  extra: {'userId': userId, 'field': field},
                );
                for (final sub in subscriptions.values) {
                  sub.cancel();
                }
                for (final timer in retryTimers.values) {
                  timer.cancel();
                }
                controller.addError(error, stack);
              },
            );

        subscriptions[field] = subscription;
      }

      for (final field in _notificationRecipientFields) {
        attachField(field);
      }

      controller.onCancel = () {
        for (final subscription in subscriptions.values) {
          subscription.cancel();
        }
        for (final timer in retryTimers.values) {
          timer.cancel();
        }
        subscriptions.clear();
        retryTimers.clear();
      };
      controller.add(const <Map<String, dynamic>>[]);
    });
  }

  bool _isNotificationUnread(Map<String, dynamic> data) {
    return !(data['read'] == true || data['isRead'] == true);
  }

  Future<void> _syncTopicSubscription(String userId) async {
    if (kIsWeb || userId.isEmpty) return;
    if (_subscribedTopicUserId == userId) return;

    if (_subscribedTopicUserId != null && _subscribedTopicUserId!.isNotEmpty) {
      final previousTopic = '$_userTopicPrefix${_subscribedTopicUserId!}';
      try {
        await _firebaseMessaging.unsubscribeFromTopic(previousTopic);
      } catch (error) {
        AppLogger.warn(
          'NotificationService',
          'Failed to unsubscribe from previous user topic',
          extra: {'topic': previousTopic, 'error': error.toString()},
        );
      }
    }

    final topic = '$_userTopicPrefix$userId';
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      _subscribedTopicUserId = userId;
      AppLogger.info(
        'NotificationService',
        'Subscribed to user notification topic',
        extra: {'topic': topic},
      );
    } catch (error) {
      AppLogger.warn(
        'NotificationService',
        'Failed to subscribe to user notification topic',
        extra: {'topic': topic, 'error': error.toString()},
      );
    }
  }

  Future<void> _clearTopicSubscription() async {
    if (kIsWeb) return;
    final existingUserId = _subscribedTopicUserId;
    if (existingUserId == null || existingUserId.isEmpty) return;
    final topic = '$_userTopicPrefix$existingUserId';
    _subscribedTopicUserId = null;
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      AppLogger.info(
        'NotificationService',
        'Unsubscribed from user notification topic',
        extra: {'topic': topic},
      );
    } catch (error) {
      AppLogger.warn(
        'NotificationService',
        'Failed to unsubscribe from user notification topic',
        extra: {'topic': topic, 'error': error.toString()},
      );
    }
  }

  void _scheduleTokenRetryIfNeeded({required String reason}) {
    if (kIsWeb) return;
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return;
    }
    if (_tokenRetryHardStopped) return;
    if (_tokenRetryAttempts >= _tokenRetryHardCap) {
      _tokenRetryTimer?.cancel();
      _tokenRetryTimer = null;
      _tokenRetryHardStopped = true;
      AppLogger.warn(
        'NotificationService',
        'Stopped APNS/FCM token retry attempts',
        extra: {'attempts': _tokenRetryAttempts, 'reason': reason},
      );
      return;
    }
    _tokenRetryTimer?.cancel();
    _tokenRetryTimer = Timer(_tokenRetryInterval, () async {
      _tokenRetryAttempts += 1;
      if (_tokenRetryAttempts % _tokenRetryLogInterval == 0) {
        AppLogger.warn(
          'NotificationService',
          'Still retrying APNS/FCM token registration',
          extra: {'attempts': _tokenRetryAttempts, 'reason': reason},
        );
      }
      await updateToken(_currentUserId);
    });
  }

  void _resetTokenRetryState() {
    _tokenRetryTimer?.cancel();
    _tokenRetryTimer = null;
    _tokenRetryAttempts = 0;
    _tokenRetryHardStopped = false;
    _hasLoggedTokenPersistPermissionBlock = false;
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
      icon: '@mipmap/ic_launcher',
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
      icon: '@mipmap/ic_launcher',
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
      icon: '@mipmap/ic_launcher',
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

    const androidDetails = AndroidNotificationDetails(
      'sparewo_tips',
      'Tips & Setup',
      channelDescription: 'Profile setup reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: AppColors.primary,
      icon: '@mipmap/ic_launcher',
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
    handleNavigation(decoded, router);
  }

  // Check if app was launched from notification (Cold boot or Background)
  Future<void> setupInteractedMessage(GoRouter router) async {
    _router = router;
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      unawaited(
        _recordPushTelemetry(
          event: 'push_opened_initial_message',
          severity: 'info',
          data: {
            'messageId': initialMessage.messageId,
            'type': initialMessage.data['type'],
            'notificationId': initialMessage.data['notificationId'],
          },
        ),
      );
      handleNavigation(initialMessage.data, router);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      unawaited(
        _recordPushTelemetry(
          event: 'push_opened_background',
          severity: 'info',
          data: {
            'messageId': message.messageId,
            'type': message.data['type'],
            'notificationId': message.data['notificationId'],
          },
        ),
      );
      handleNavigation(message.data, router);
    });
  }

  Future<void> _recordPushTelemetry({
    required String event,
    required String severity,
    Map<String, dynamic>? data,
  }) async {
    try {
      await FirebaseFirestore.instance.collection(_diagnosticsCollection).add({
        'source': 'client',
        'service': 'notification_service',
        'severity': severity,
        'code': event,
        'message': event,
        'context': {
          'uid': _currentUserId,
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
          ...?data,
        },
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        'uid': _currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'isoTimestamp': DateTime.now().toIso8601String(),
        'createdAtMs': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      // Never throw from telemetry path.
    }
  }

  void handleNavigation(Map<String, dynamic> data, GoRouter router) {
    unawaited(_markNotificationAsRead(data));

    final type = data['type']?.toString();
    final id = data['id']?.toString();
    final link = data['link']?.toString();
    final notificationId = data['notificationId']?.toString();

    if (link != null && link.isNotEmpty && link.startsWith('/')) {
      final parsedLink = Uri.tryParse(link);
      if (parsedLink?.path == '/notifications') {
        if (notificationId != null && notificationId.isNotEmpty) {
          _navigateSafely(
            router,
            '/notifications?openId=${Uri.encodeComponent(notificationId)}',
          );
          return;
        }
        if (type == 'order' && id != null && id.isNotEmpty) {
          _navigateSafely(router, '/order/$id');
          return;
        }
        if (type == 'booking' && id != null && id.isNotEmpty) {
          _navigateSafely(router, '/booking/$id');
          return;
        }
      }
      _navigateSafely(router, link);
      return;
    }

    if (type == 'order' && id != null) {
      _navigateSafely(router, '/order/$id');
    } else if (type == 'booking' && id != null) {
      _navigateSafely(router, '/booking/$id');
    } else if (type == 'add_car_nudge') {
      _navigateSafely(router, '/add-car?nudge=true');
    } else if (notificationId != null && notificationId.isNotEmpty) {
      _navigateSafely(
        router,
        '/notifications?openId=${Uri.encodeComponent(notificationId)}',
      );
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

  Map<String, dynamic> _notificationPayloadFromDoc(
    Map<String, dynamic> data, {
    String? notificationId,
  }) {
    final payload = <String, dynamic>{...data};
    payload['title'] = payload['title']?.toString() ?? 'SpareWo Update';
    payload['message'] = payload['message']?.toString() ?? '';
    payload['notificationId'] =
        payload['notificationId']?.toString() ??
        (notificationId == null || notificationId.isEmpty
            ? null
            : notificationId);

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

  Future<void> _markNotificationAsRead(Map<String, dynamic> data) async {
    final notificationId = data['notificationId']?.toString();
    if (notificationId == null || notificationId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .set({
            'read': true,
            'isRead': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      AppLogger.warn(
        'NotificationService',
        'Failed to mark notification as read on open',
        extra: {
          'notificationId': notificationId,
          'error': error.toString(),
          'stack': stackTrace.toString(),
        },
      );
    }
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
    _tokenRetryTimer?.cancel();
    _firestoreListenerRetryTimer?.cancel();
    _tokenRefreshSubscription?.cancel();
    _firestoreNotifSubscription?.cancel();
    _foregroundMessageController.close();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
