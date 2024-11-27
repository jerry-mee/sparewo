class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://sparewo.matchstick.ug/api/vendor';

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

  // Firebase Config
  static const String projectId = 'sparewovendor';
  static const String apiKey = 'AIzaSyCwC4-PqJ3CPQq2x1DUUET6_qcDmIQD25s';
  static const String appId = '1:900028469691:android:20ddb4a69320740517b49e';
  static const String messagingSenderId = '900028469691';
  static const String storageBucket = 'sparewovendor.firebasestorage.app';
}
