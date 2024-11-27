import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'firebase_options.dart';
import 'providers/data_provider.dart';
import 'providers/auth_provider.dart';
import 'services/api/api_service.dart';
import 'services/storage/storage_service.dart';
import 'services/feedback_service.dart';
import 'services/navigation_service.dart';
import 'constants/theme.dart';
import 'utils/error_handler.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  try {
    // Preserve splash screen while initializing
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    // Initialize services
    final AppServices services = await _initializeApp();

    // Launch app
    runApp(MyApp(services: services));

    // Remove splash screen
    FlutterNativeSplash.remove();
  } catch (e, stackTrace) {
    ErrorHandler.handleCriticalError(e, stackTrace);
    _runErrorApp(e.toString());
  }
}

Future<AppServices> _initializeApp() async {
  try {
    // Configure system UI
    await _configureSystemUI();

    // Initialize core services
    final apiService = ApiService();
    final storageService = StorageService();
    await storageService.init();

    // Get Google Client ID
    final googleClientId = _getGoogleClientId();

    // Configure loading indicator
    _configureEasyLoading();

    return AppServices(
      apiService: apiService,
      storageService: storageService,
      googleClientId: googleClientId,
      navigationService: NavigationService(),
    );
  } catch (e, stackTrace) {
    ErrorHandler.handleCriticalError(e, stackTrace);
    rethrow;
  }
}

Future<void> _configureSystemUI() async {
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF1A1B4B),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  } catch (e) {
    debugPrint('Warning: System UI configuration failed: $e');
  }
}

String _getGoogleClientId() {
  final options = DefaultFirebaseOptions.currentPlatform;
  if (options.appId.isEmpty) {
    throw Exception('Firebase configuration is missing required App ID');
  }
  return options.appId;
}

void _configureEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.white
    ..backgroundColor = Colors.black.withOpacity(0.7)
    ..indicatorColor = Colors.white
    ..textColor = Colors.white
    ..maskColor = Colors.black.withOpacity(0.5)
    ..userInteractions = false
    ..dismissOnTap = false;
}

void _runErrorApp(String error) {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Application Error',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    ),
  ));
}

class AppServices {
  final ApiService apiService;
  final StorageService storageService;
  final String googleClientId;
  final NavigationService navigationService;

  const AppServices({
    required this.apiService,
    required this.storageService,
    required this.googleClientId,
    required this.navigationService,
  });
}

class MyApp extends StatelessWidget {
  final AppServices services;

  const MyApp({
    super.key,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            // Services
            Provider.value(value: services.apiService),
            Provider.value(value: services.storageService),
            Provider.value(value: services.navigationService),
            Provider(create: (_) => FeedbackService()),

            // State Management
            ChangeNotifierProvider(
              create: (context) => AuthProvider(
                apiService: services.apiService,
                storageService: services.storageService,
                googleClientId: services.googleClientId,
              )..init(),
            ),
            ChangeNotifierProvider(
              create: (context) => DataProvider(
                apiService: services.apiService,
              ),
            ),
          ],
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return MaterialApp(
                title: 'SpareWo',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                navigatorKey: services.navigationService.navigatorKey,
                scaffoldMessengerKey: services.navigationService.scaffoldKey,
                builder: (context, child) {
                  child = EasyLoading.init()(context, child);
                  return child ?? const SizedBox.shrink();
                },
                onGenerateRoute: AppRouter.onGenerateRoute,
                initialRoute: AppRouter.splash,
              );
            },
          ),
        );
      },
    );
  }
}
