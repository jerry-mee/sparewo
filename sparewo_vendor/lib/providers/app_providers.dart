import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/enums.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/notification.dart';
import '../models/settings.dart';
import '../models/vendor.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../services/stats_service.dart';
import '../providers/auth_provider.dart';
import 'order_notifier.dart';
import 'product_provider.dart';

// Service Providers
final firebaseServiceProvider =
    Provider<FirebaseService>((ref) => FirebaseService());

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

final apiServiceProvider = Provider<ApiService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ApiService(storageService: storageService);
});

// Auth State Provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(
    firebaseService: firebaseService,
    storageService: storageService,
    apiService: apiService,
  );
});

final currentVendorProvider =
    Provider<Vendor?>((ref) => ref.watch(authStateProvider).vendor);

final currentVendorIdProvider =
    Provider<String?>((ref) => ref.watch(currentVendorProvider)?.id);

// Products Provider
final productsProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  final productService = ref.watch(productServiceProvider);
  final vendorId = ref.watch(currentVendorIdProvider);
  return ProductsNotifier(productService, vendorId);
});

// Orders Provider
final ordersProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final vendorId = ref.watch(currentVendorIdProvider);
  return OrderNotifier(
    orderService: orderService,
    notificationService: notificationService,
    vendorId: vendorId,
  );
});

// Notifications Provider
final notificationsProvider = StateNotifierProvider<NotificationsNotifier,
    AsyncValue<List<VendorNotification>>>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final vendorId = ref.watch(currentVendorIdProvider);
  return NotificationsNotifier(notificationService, vendorId);
});

// Settings Provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return SettingsNotifier(settingsService);
});

// Stats Provider
final statsProvider = Provider<StatsService>((ref) => StatsService());

final dashboardStatsProvider = FutureProvider((ref) async {
  final vendorId = ref.watch(currentVendorIdProvider);
  if (vendorId == null) throw Exception('No vendor ID available');
  final statsService = ref.read(statsProvider);
  return statsService.getDashboardStats(vendorId);
});

// Service Export Providers
final orderServiceProvider = Provider<OrderService>((ref) => OrderService());
final productServiceProvider =
    Provider<ProductService>((ref) => ProductService());
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());
final settingsServiceProvider =
    Provider<SettingsService>((ref) => SettingsService());

// Filtered Providers
final filteredProductsProvider =
    Provider.family<List<Product>, String?>((ref, filter) {
  final products = ref.watch(productsProvider).value ?? [];
  if (filter == null || filter.isEmpty) return products;
  return products
      .where((product) =>
          product.title.toLowerCase().contains(filter.toLowerCase()))
      .toList();
});

final filteredOrdersProvider =
    Provider.family<List<VendorOrder>, OrderStatus?>((ref, status) {
  final orders =
      ref.watch(ordersProvider.select((state) => state.orders.value ?? []));
  if (status == null) return orders;
  return orders.where((order) => order.status == status).toList();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref
          .watch(notificationsProvider)
          .value
          ?.where((n) => !n.isRead)
          .length ??
      0;
});

// State Providers
final themeProvider =
    StateProvider<bool>((ref) => ref.watch(settingsProvider).isDarkMode);

// Loading States
final isLoadingProvider = Provider<bool>((ref) =>
    ref.watch(authStateProvider).isLoading ||
    ref.watch(productsProvider).isLoading ||
    ref.watch(ordersProvider.select((state) => state.isLoading)) ||
    ref.watch(notificationsProvider).isLoading);

// Error States
final errorProvider = Provider<String?>((ref) =>
    ref.watch(authStateProvider).error ??
    ref.watch(productsProvider).error?.toString() ??
    ref.watch(ordersProvider).error ??
    ref.watch(notificationsProvider).error?.toString());

// Stream Providers
final statsStreamProvider = StreamProvider((ref) {
  final vendorId = ref.watch(currentVendorIdProvider);
  if (vendorId == null) throw Exception('No vendor ID available');
  final statsService = ref.read(statsProvider);
  return statsService.watchDashboardStats(vendorId);
});
