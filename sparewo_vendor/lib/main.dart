// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <<< ADDED

import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'services/logger_service.dart';
import 'services/storage_service.dart'; // <<< ADDED
import 'services/ui_notification_service.dart'; // <<< ADDED
import 'theme.dart';
import 'providers/providers.dart'; // <<< ADDED for provider override

void main() async {
  // Run the entire app in a single zone to avoid zone mismatch issues
  runZonedGuarded(
    () async {
      // Ensure Flutter bindings are initialized in the same zone
      WidgetsFlutterBinding.ensureInitialized();

      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // >>>>> SECTION MODIFIED <<<<<
      // Initialize services
      try {
        // Initialize services and get the storageService instance
        final storageService = await _initializeServices();

        // Run the app with the initialized service provided
        runApp(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(storageService),
            ],
            child: const SpareWoVendorApp(),
          ),
        );
      } catch (e, stackTrace) {
        final logger = LoggerService.instance;
        logger.error('FATAL: Failed to initialize essential services.',
            error: e, stackTrace: stackTrace);
        // Optionally, run an error app
        // runApp(ErrorApp(error: e.toString()));
      }
      // >>>>> END OF SECTION <<<<<
    },
    (error, stack) {
      final logger = LoggerService.instance;
      logger.error('Uncaught error', error: error, stackTrace: stack);
    },
  );
}

// >>>>> SECTION MODIFIED <<<<<
// This function now returns the initialized StorageService
Future<StorageService> _initializeServices() async {
  final logger = LoggerService.instance;

  // Load environment variables first
  await dotenv.load(fileName: ".env");
  logger.info('.env file loaded.');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  logger.info('Firebase initialized.');

  // Initialize Storage Service (which now has an async init method)
  final storageService = StorageService();
  await storageService.init();
  logger.info('StorageService initialized.');

  logger.info('All services initialized successfully');
  return storageService;
}
// >>>>> END OF SECTION <<<<<

class SpareWoVendorApp extends ConsumerWidget {
  const SpareWoVendorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      // >>>>> SECTION MODIFIED <<<<<
      // Assign the global key from the UINotificationService to the MaterialApp
      scaffoldMessengerKey: UINotificationService.messengerKey,
      // >>>>> END OF SECTION <<<<<
      title: 'SpareWo Vendor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) {
        // Add responsive wrapper for desktop
        Widget wrappedChild = child ?? const SizedBox.shrink();

        // Only apply responsive constraints on desktop/web
        if (MediaQuery.of(context).size.width > 1200) {
          wrappedChild = Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            alignment: Alignment.center,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1600),
              child: Material(
                elevation: 0,
                color: Colors.transparent,
                child: wrappedChild,
              ),
            ),
          );
        }

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: wrappedChild,
        );
      },
    );
  }
}
