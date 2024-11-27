import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_vendor/providers/app_providers.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../constants/notification_types.dart';
import '../constants/enums.dart';
import 'auth_provider.dart' as auth;

class NotificationState {
  final List<VendorNotification> notifications;
  final LoadingStatus status;
  final String? error;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.status = LoadingStatus.initial,
    this.error,
    this.isLoading = false,
  });

  NotificationState copyWith({
    List<VendorNotification>? notifications,
    LoadingStatus? status,
    String? error,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      status: status ?? this.status,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  AsyncValue<List<VendorNotification>> toAsyncValue() {
    if (isLoading) return const AsyncValue.loading();
    if (error != null) return AsyncValue.error(error!, StackTrace.current);
    return AsyncValue.data(notifications);
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<VendorNotification>>> {
  final NotificationService _notificationService;
  final String? _vendorId;

  NotificationsNotifier(this._notificationService, this._vendorId)
      : super(const AsyncValue.loading()) {
    if (_vendorId != null) {
      loadNotifications();
    }
  }

  Future<void> loadNotifications() async {
    if (state.isLoading || _vendorId == null) return;

    state = const AsyncValue.loading();

    try {
      final notifications =
          await _notificationService.getVendorNotifications(_vendorId!);
      state = AsyncValue.data(notifications);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    if (state.isLoading) return;

    try {
      await _notificationService.markAsRead(notificationId);
      state = AsyncValue.data(
        state.value!.map((notification) {
          if (notification.id == notificationId) {
            return notification.copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
          }
          return notification;
        }).toList(),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> markAllAsRead() async {
    if (state.isLoading || _vendorId == null) return;

    state = const AsyncValue.loading();

    try {
      await _notificationService.markAllAsRead(_vendorId!);
      state = AsyncValue.data(
        state.value!
            .map((notification) => notification.copyWith(
                  isRead: true,
                  readAt: DateTime.now(),
                ))
            .toList(),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    if (state.isLoading) return;

    try {
      await _notificationService.deleteNotification(notificationId);
      state = AsyncValue.data(
        state.value!
            .where((notification) => notification.id != notificationId)
            .toList(),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void filterByType(NotificationType? type) {
    if (state.isLoading || _vendorId == null) return;

    if (type == null) {
      loadNotifications();
      return;
    }

    final filtered = state.value!
        .where((notification) => notification.type == type)
        .toList();

    state = AsyncValue.data(filtered);
  }

  Stream<List<VendorNotification>> watchNotifications() {
    if (_vendorId == null) return Stream.value([]);
    return _notificationService.watchVendorNotifications(_vendorId!);
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier,
    AsyncValue<List<VendorNotification>>>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final vendorId =
      ref.watch(auth.currentVendorProvider.select((vendor) => vendor?.id));
  return NotificationsNotifier(notificationService, vendorId);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref
          .watch(notificationsProvider)
          .value
          ?.where((n) => !n.isRead)
          .length ??
      0;
});

final filteredNotificationsProvider =
    Provider.family<List<VendorNotification>, NotificationType?>((ref, type) {
  final notifications = ref.watch(notificationsProvider).value ?? [];
  if (type == null) return notifications;
  return notifications
      .where((notification) => notification.type == type)
      .toList();
});

final notificationLoadingProvider = Provider<bool>((ref) {
  return ref.watch(notificationsProvider).isLoading;
});

final notificationErrorProvider = Provider<String?>((ref) {
  return ref.watch(notificationsProvider).error?.toString();
});

final notificationStreamProvider =
    StreamProvider<List<VendorNotification>>((ref) {
  return ref.watch(notificationsProvider.notifier).watchNotifications();
});
