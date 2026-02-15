// lib/providers/order_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_vendor/models/order.dart';
import 'package:sparewo_vendor/services/notification_service.dart';
import '../constants/enums.dart';
import '../services/logger_service.dart';
import '../services/order_service.dart';
import 'dart:async';

class OrderState {
  final AsyncValue<List<VendorOrder>> orders;
  const OrderState({this.orders = const AsyncValue.loading()});

  OrderState copyWith({AsyncValue<List<VendorOrder>>? orders}) {
    return OrderState(orders: orders ?? this.orders);
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final OrderService? _orderService;
  final NotificationService? _notificationService;
  final String? _vendorId;
  final LoggerService _logger = LoggerService.instance;
  StreamSubscription? _orderSubscription;

  OrderNotifier(
    this._orderService,
    this._notificationService,
    this._vendorId,
  ) : super(const OrderState()) {
    _listenToOrders();
  }

  factory OrderNotifier.empty() {
    return OrderNotifier(null, null, null);
  }

  void _listenToOrders() {
    if (_orderService == null || _vendorId == null) {
      state = state.copyWith(orders: const AsyncValue.data([]));
      return;
    }

    state = state.copyWith(orders: const AsyncValue.loading());
    _orderSubscription?.cancel();
    _orderSubscription =
        _orderService!.watchVendorOrders(_vendorId!).listen((orders) {
      state = state.copyWith(orders: AsyncValue.data(orders));
    }, onError: (e, stack) {
      _logger.error('Failed to listen to orders', error: e, stackTrace: stack);
      state = state.copyWith(orders: AsyncValue.error(e, stack));
    });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    if (_orderService == null ||
        _notificationService == null ||
        _vendorId == null) return;

    try {
      await _orderService!.updateOrderStatus(orderId, newStatus);
      await _notificationService!.sendOrderStatusNotification(
        orderId: orderId,
        status: newStatus,
        vendorId: _vendorId!,
      );
    } catch (e) {
      _logger.error('Failed to update order status', error: e);
      rethrow;
    }
  }

  Future<void> acceptOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.accepted);
  }

  Future<void> rejectOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.rejected);
  }

  Future<void> processOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.processing);
  }

  Future<void> completeOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.delivered);
  }

  Future<void> refreshOrders() async {
    _listenToOrders();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }
}
