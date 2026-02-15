// lib/constants/api_constants.dart

import 'package:flutter_dotenv/flutter_dotenv.dart'; // <<< ADDED

class ApiConstants {
  // --- SECURITY WARNING ---
  // Sensitive keys have been moved to a .env file.
  // This file is safe to commit to version control.

  // >>>>> SECTION MODIFIED <<<<<
  // Base URL updated to the new vendor domain
  static const String baseUrl = 'https://vendor.sparewo.ug/api';

  // Firebase Functions URL updated with the correct project ID
  static final String firebaseFunctionsBaseUrl =
      'https://us-central1-${dotenv.env['FIREBASE_PROJECT_ID']!}.cloudfunctions.net';
  // >>>>> END OF SECTION <<<<<

  // Auth Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';

  // Resource Endpoints
  static const String profile = '/profile';
  static const String products = '/products';
  static const String orders = '/orders';
  static const String stats = '/stats/dashboard';

  // Default Headers
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // >>>>> SECTION MODIFIED (KEYS REMOVED) <<<<<
  // Firebase Config (loaded from environment variables)
  static final String projectId = dotenv.env['FIREBASE_PROJECT_ID']!;
  static final String apiKey = dotenv.env['FIREBASE_API_KEY_ANDROID']!;
  static final String appId = dotenv.env['FIREBASE_APP_ID_ANDROID']!;
  static final String messagingSenderId =
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!;
  static final String storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET']!;
  // >>>>> END OF SECTION <<<<<

  // --- ADDED TO FIX VERIFICATION SERVICE ERRORS (NO REMOVALS) ---
  static const String verificationCodesCollection = 'verificationCodes';
  static const String debugVerificationCode = '123456';
}
