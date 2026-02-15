// lib/main.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'firebase_options.dart';

// Global Key to allow showing SnackBars from anywhere (Aesthetic In-App Notifications)
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

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

      if (kReleaseMode && !kIsWeb) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.deviceCheck,
        );
      }

      _configureEasyLoading();

      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stack) {
      AppLogger.error('UncaughtZoneError', error.toString(), stackTrace: stack);
    },
  );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
