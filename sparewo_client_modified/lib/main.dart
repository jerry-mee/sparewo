// lib/main.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sparewo_client/core/router/app_router.dart';
import 'package:sparewo_client/core/router/shared_preferences_provider.dart';
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
      await AppLogger.init();

      // Register Firebase Background Handler as early as possible
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      final sharedPreferences = await SharedPreferences.getInstance();

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
        // Report to Firebase Crashlytics
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };

      // Catch uncaught platform / isolate errors
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.error('PlatformError', error.toString(), stackTrace: stack);
        // Report to Firebase Crashlytics
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        AppLogger.info('Firebase', 'Initialized successfully');
      } else {
        AppLogger.info('Firebase', 'Already initialized');
      }
      await AppLogger.enableCrashlyticsForwarding(
        includeInfo: true,
        includeDebug: kDebugMode,
        recordNonFatalErrors: true,
      );

      // ----------------------------------------------------------------------
      // ASYNC INITIALIZATIONS (NON-BLOCKING)
      // ----------------------------------------------------------------------

      // Start App Check without blocking the main thread
      if (!kIsWeb) {
        await _activateAppCheck();
      }

      _configureEasyLoading();

      runApp(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      AppLogger.error('UncaughtZoneError', error.toString(), stackTrace: stack);
    },
  );
}

/// Activates Firebase App Check without blocking the app startup
Future<void> _activateAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kReleaseMode
          ? AndroidProvider.playIntegrity
          : AndroidProvider.debug,
      appleProvider: kReleaseMode
          ? AppleProvider.appAttestWithDeviceCheckFallback
          : AppleProvider.debug,
    );

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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  ProviderSubscription<AsyncValue<fb_auth.User?>>? _authStateListener;
  ProviderSubscription<AsyncValue<fb_auth.User?>>? _easyLoadingListener;
  String? _pendingNotificationUserId;
  String? _lastAuthUid;
  bool _isOffline = false;
  bool _notificationsReady = false;
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      _notificationService = ref.read(notificationServiceProvider);

      _authStateListener = ref.listenManual<AsyncValue<fb_auth.User?>>(
        authStateChangesProvider,
        (previous, next) {
          _onAuthStateChanged(next.asData?.value?.uid);
        },
        fireImmediately: true,
      );

      _easyLoadingListener = ref.listenManual<AsyncValue<fb_auth.User?>>(
        authStateChangesProvider,
        (_, next) {
          if (!next.isLoading) {
            EasyLoading.dismiss();
          }
        },
      );

      unawaited(_startConnectivityMonitoring());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_initNotificationLayer());
      });
      AppLogger.info('MyApp', 'Service pipelines initialized');
    } catch (e, st) {
      AppLogger.error('MyApp', 'Service Init Failed', error: e, stackTrace: st);
    }
  }

  Future<void> _initNotificationLayer() async {
    try {
      await _notificationService.init();
      _notificationsReady = true;

      // Wire up the Foreground Stream to the Aesthetic UI
      _notificationSubscription = _notificationService.foregroundStream.listen((
        message,
      ) {
        if (message.notification != null) {
          _showAestheticInAppNotification(message);
        }
      });

      // Handle App Opening from Notification
      final router = ref.read(routerProvider);
      await _notificationService.setupInteractedMessage(router);

      _applyPendingNotificationAuth();
      AppLogger.info('MyApp', 'Notification layer ready');
    } catch (e, st) {
      AppLogger.error(
        'MyApp',
        'Notification layer init failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _onAuthStateChanged(String? userId) {
    if (_lastAuthUid != userId) {
      AppLogger.info(
        'AuthLifecycle',
        'Auth state transitioned',
        extra: {'from': _lastAuthUid, 'to': userId},
      );
      _lastAuthUid = userId;
      unawaited(AppLogger.setUserIdentifier(userId));
    }

    if (!_notificationsReady) {
      _pendingNotificationUserId = userId;
      return;
    }

    if (userId != null && userId.isNotEmpty) {
      unawaited(_notificationService.updateToken(userId));
      _notificationService.startFirestoreNotificationListener(userId);
      AppLogger.debug(
        'Notifications',
        'Started authenticated notification listeners',
        extra: {'uid': userId},
      );
      return;
    }

    AppLogger.debug('Notifications', 'Stopped notification listeners');
    _notificationService.stopFirestoreNotificationListener();
  }

  void _applyPendingNotificationAuth() {
    final userId =
        _pendingNotificationUserId ??
        ref.read(authStateChangesProvider).asData?.value?.uid;
    _pendingNotificationUserId = null;
    _onAuthStateChanged(userId);
  }

  Future<void> _startConnectivityMonitoring() async {
    final connectivity = Connectivity();

    Future<void> handleResults(List<ConnectivityResult> results) async {
      final isOfflineNow = results.every(
        (result) => result == ConnectivityResult.none,
      );

      if (_isOffline == isOfflineNow) return;
      _isOffline = isOfflineNow;

      if (isOfflineNow) {
        AppLogger.warn('Connectivity', 'Device offline');
        rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: const Text(
              'You are offline. Please check your internet connection.',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(days: 1),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
              },
            ),
          ),
        );
        return;
      }

      AppLogger.info('Connectivity', 'Device online');
      rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Back online'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }

    final initialResults = await connectivity.checkConnectivity();
    await handleResults(initialResults);
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(
      handleResults,
    );
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
    _connectivitySubscription?.cancel();
    _authStateListener?.close();
    _easyLoadingListener?.close();
    ref.read(notificationServiceProvider).stopFirestoreNotificationListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
