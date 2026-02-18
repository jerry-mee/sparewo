// lib/main.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:sparewo_client/core/router/app_router.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/theme/theme_mode_provider.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/features/shared/services/notification_service.dart';
import 'package:sparewo_client/core/notifications/fcm_background_handler.dart';
import 'firebase_options.dart';

// Global Key to allow showing SnackBars from anywhere (Aesthetic In-App Notifications)
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Register Firebase Background Handler as early as possible
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Load environment variables (optional in web builds)
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        AppLogger.warn(
          'Env',
          'Skipping .env load',
          extra: {'error': e.toString()},
        );
      }

      // Global Flutter error handler
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        AppLogger.error(
          'FlutterError',
          details.exceptionAsString(),
          stackTrace: details.stack,
          extra: {
            'library': details.library,
            'context': details.context?.toDescription(),
          },
        );
      };

      // Catch uncaught platform / isolate errors
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.error('PlatformError', error.toString(), stackTrace: stack);
        return true;
      };

      // Initialize logger without blocking first-frame startup.
      unawaited(AppLogger.init());

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        AppLogger.info('Firebase', 'Initialized successfully');
      } else {
        AppLogger.info('Firebase', 'Already initialized');
      }

      // ----------------------------------------------------------------------
      // ASYNC INITIALIZATIONS (NON-BLOCKING)
      // ----------------------------------------------------------------------

      // Start App Check without blocking the main thread
      if (!kIsWeb) {
        _activateAppCheck();
      }

      _configureEasyLoading();

      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stack) {
      AppLogger.error('UncaughtZoneError', error.toString(), stackTrace: stack);
    },
  );
}

/// Activates Firebase App Check without blocking the app startup
Future<void> _activateAppCheck() async {
  try {
    // Small delay to let the platform initialize things
    await Future.delayed(const Duration(seconds: 1));

    await FirebaseAppCheck.instance.activate(
      androidProvider: kReleaseMode
          ? AndroidProvider.playIntegrity
          : AndroidProvider.debug,
      appleProvider: kReleaseMode
          ? AppleProvider.appAttest
          : AppleProvider.debug,
    );

    if (!kReleaseMode) {
      // Don't await this forever, if it fails it fails.
      unawaited(
        FirebaseAppCheck.instance
            .getToken()
            .then((token) {
              if (token != null) {
                AppLogger.info(
                  'FirebaseAppCheck',
                  '!!! DEBUG TOKEN !!!: $token',
                );
              }
            })
            .catchError((e) {
              AppLogger.warn('FirebaseAppCheck', 'Token fetch failed: $e');
            }),
      );
    }

    AppLogger.info(
      'FirebaseAppCheck',
      kReleaseMode
          ? 'Activated with production providers'
          : 'Activated with debug providers',
    );
  } catch (e) {
    AppLogger.warn('FirebaseAppCheck', 'Activation failed: $e');
  }
}

void _configureEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.white
    ..backgroundColor = Colors.black.withValues(alpha: 0.7)
    ..indicatorColor = Colors.white
    ..textColor = Colors.white
    ..maskColor = Colors.black.withValues(alpha: 0.5)
    ..userInteractions = false
    ..dismissOnTap = false;
}

class _NoBounceScrollBehavior extends MaterialScrollBehavior {
  const _NoBounceScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription? _notificationSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _bookingApprovalSubscription;
  final Map<String, String> _knownBookingStatuses = <String, String>{};
  String? _bookingListenerUserId;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      final notifService = ref.read(notificationServiceProvider);
      await notifService.init();

      // Wire up the Foreground Stream to the Aesthetic UI
      _notificationSubscription = notifService.foregroundStream.listen((
        message,
      ) {
        if (message.notification != null) {
          _showAestheticInAppNotification(message);
        }
      });

      // Handle App Opening from Notification
      final router = ref.read(routerProvider);
      await notifService.setupInteractedMessage(router);

      AppLogger.info('MyApp', 'Services wired up');
    } catch (e, st) {
      AppLogger.error('MyApp', 'Service Init Failed', error: e, stackTrace: st);
    }
  }

  void _syncBookingApprovalListener({
    required String? userId,
    required NotificationService notificationService,
  }) {
    if (userId == null || userId.isEmpty) {
      _bookingApprovalSubscription?.cancel();
      _bookingApprovalSubscription = null;
      _bookingListenerUserId = null;
      _knownBookingStatuses.clear();
      return;
    }

    if (_bookingListenerUserId == userId &&
        _bookingApprovalSubscription != null) {
      return;
    }

    _bookingApprovalSubscription?.cancel();
    _knownBookingStatuses.clear();
    _bookingListenerUserId = userId;

    _bookingApprovalSubscription = FirebaseFirestore.instance
        .collection('service_bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final bookingId = doc.id;
            final status = (data['status'] as String?) ?? '';
            final bookingNumber =
                (data['bookingNumber'] as String?) ?? bookingId;

            final previousStatus = _knownBookingStatuses[bookingId];
            if (previousStatus != null &&
                previousStatus != status &&
                status == 'confirmed') {
              notificationService.showLocalNotification(
                id: bookingId.hashCode,
                title: 'AutoHub Request Approved',
                body:
                    'Your request $bookingNumber is approved. We shall reach out shortly.',
              );
            }

            _knownBookingStatuses[bookingId] = status;
          }
        });
  }

  /// Shows a custom styled SnackBar that matches the app aesthetic
  void _showAestheticInAppNotification(RemoteMessage message) {
    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.secondary, // Navy Brand Color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2), // Orange tint
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  if (body.isNotEmpty)
                    Text(
                      body,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: AppColors.primary,
          onPressed: () {
            // Handle simple foreground tap if needed
            // For complex routing, using the stream data is better
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _bookingApprovalSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifService = ref.read(notificationServiceProvider);
    ref.listen(currentUserProvider, (previous, next) {
      final userId = next.asData?.value?.id;
      if (userId != null) {
        _syncBookingApprovalListener(
          userId: userId,
          notificationService: notifService,
        );

        // Efficiently save FCM Token for the logged-in user
        notifService.updateToken(userId);

        // Start live Firestore notification listener
        notifService.startFirestoreNotificationListener(userId);
      } else {
        _syncBookingApprovalListener(
          userId: null,
          notificationService: notifService,
        );
      }
    });

    // Dismiss loading on auth change
    ref.listen(authStateChangesProvider, (prev, next) {
      if (!next.isLoading) {
        EasyLoading.dismiss();
      }
    });

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => MaterialApp.router(
        scaffoldMessengerKey:
            rootScaffoldMessengerKey, // Global Key for Notifications
        title: 'SpareWo Client',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        scrollBehavior: const _NoBounceScrollBehavior(),
        routerConfig: router,
        builder: EasyLoading.init(),
      ),
    );
  }
}
