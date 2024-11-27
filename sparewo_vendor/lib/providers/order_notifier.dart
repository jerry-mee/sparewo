import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_vendor/providers/app_providers.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';
import '../constants/enums.dart';

class OrderState {
  final AsyncValue<List<VendorOrder>> orders;
  final LoadingStatus status;
  final String? error;

  const OrderState({
    this.orders = const AsyncValue.loading(),
    this.status = LoadingStatus.initial,
    this.error,
  });

  get isLoading => null;

  OrderState copyWith({
    AsyncValue<List<VendorOrder>>? orders,
    LoadingStatus? status,
    String? error,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      status: status ?? this.status,
      error: error,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final OrderService _orderService;
  final NotificationService _notificationService;
  final String? _vendorId;

  OrderNotifier({
    required OrderService orderService,
    required NotificationService notificationService,
    required String? vendorId,
  })  : _orderService = orderService,
        _notificationService = notificationService,
        _vendorId = vendorId,
        super(const OrderState()) {
    if (_vendorId != null) {
      loadOrders();
    }
  }

  Future<void> loadOrders() async {
    if (_vendorId == null) return;

    state = state.copyWith(
      orders: const AsyncValue.loading(),
      status: LoadingStatus.loading,
    );

    try {
      final orders = await _orderService.getVendorOrders(_vendorId!);
      state = state.copyWith(
        orders: AsyncValue.data(orders),
        status: LoadingStatus.success,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        orders: AsyncValue.error(error, stackTrace),
        status: LoadingStatus.error,
        error: error.toString(),
      );
    }
  }

  Future<void> acceptOrder(String orderId) async {
    try {
      await _orderService.acceptOrder(orderId);
      await _notificationService.sendOrderStatusNotification(
        orderId: orderId,
        status: OrderStatus.accepted,
      );
      await loadOrders();
    } catch (error) {
      state = state.copyWith(
        error: error.toString(),
        status: LoadingStatus.error,
      );
    }
  }

  Future<void> rejectOrder(String orderId) async {
    try {
      await _orderService.rejectOrder(orderId);
      await _notificationService.sendOrderStatusNotification(
        orderId: orderId,
        status: OrderStatus.rejected,
      );
      await loadOrders();
    } catch (error) {
      state = state.copyWith(
        error: error.toString(),
        status: LoadingStatus.error,
      );
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      await _notificationService.sendOrderStatusNotification(
        orderId: orderId,
        status: newStatus,
      );
      await loadOrders();
    } catch (error) {
      state = state.copyWith(
        error: error.toString(),
        status: LoadingStatus.error,
      );
    }
  }

  List<VendorOrder> filterOrders(OrderStatus? status) {
    return state.orders.whenData((orders) {
          if (status == null) return orders;
          return orders.where((order) => order.status == status).toList();
        }).value ??
        [];
  }

  void searchOrders(String query) {
    if (query.isEmpty) {
      loadOrders();
      return;
    }

    state.orders.whenData((orders) {
      final searchTerm = query.toLowerCase();
      final filteredOrders = orders.where((order) {
        return order.customerName.toLowerCase().contains(searchTerm) ||
            order.id.toLowerCase().contains(searchTerm) ||
            order.productName.toLowerCase().contains(searchTerm);
      }).toList();

      state = state.copyWith(
        orders: AsyncValue.data(filteredOrders),
      );
    });
  }

  Stream<List<VendorOrder>> watchOrders() {
    if (_vendorId == null) return Stream.value([]);
    return _orderService.watchVendorOrders(_vendorId!);
  }
}

// Providers
final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final vendorId = ref.watch(currentVendorIdProvider);

  return OrderNotifier(
    orderService: orderService,
    notificationService: notificationService,
    vendorId: vendorId,
  );
});

final ordersAsyncProvider = Provider<AsyncValue<List<VendorOrder>>>((ref) {
  return ref.watch(orderProvider).orders;
});

final filteredOrdersProvider =
    Provider.family<List<VendorOrder>, OrderStatus?>((ref, status) {
  return ref.watch(orderProvider.notifier).filterOrders(status);
});

final orderLoadingProvider = Provider<bool>((ref) {
  return ref.watch(orderProvider).status == LoadingStatus.loading;
});

final orderErrorProvider = Provider<String?>((ref) {
  return ref.watch(orderProvider).error;
});

final orderStatusProvider = Provider<LoadingStatus>((ref) {
  return ref.watch(orderProvider).status;
});

final orderStreamProvider = StreamProvider<List<VendorOrder>>((ref) {
  return ref.watch(orderProvider.notifier).watchOrders();
});
