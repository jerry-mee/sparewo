// lib/features/cart/application/cart_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/cart/data/cart_repository.dart';
import 'package:sparewo_client/features/cart/domain/cart_model.dart';
import 'package:sparewo_client/features/cart/domain/cart_item_model.dart';

// 1. Repository Provider
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final userId = userAsync.asData?.value?.id;
  return CartRepository(userId: userId);
});

// 2. Cart Stream Provider
final cartStreamProvider = StreamProvider<CartModel>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  return repository.getUserCart();
});

// 3. Cart Notifier
final cartNotifierProvider = AsyncNotifierProvider<CartNotifier, CartModel>(
  CartNotifier.new,
);

class CartNotifier extends AsyncNotifier<CartModel> {
  // Initial local state
  CartModel _localCart = const CartModel(items: []);

  @override
  FutureOr<CartModel> build() async {
    final userAsync = ref.watch(authStateChangesProvider);
    final fbUser = userAsync.asData?.value;

    // Listen for login changes to migrate cart
    ref.listen(authStateChangesProvider, (prev, next) {
      final wasLoggedIn = prev?.asData?.value != null;
      final isLoggedIn = next.asData?.value != null;
      if (!wasLoggedIn && isLoggedIn) {
        Future.microtask(() async {
          await migrateLocalCart();
          ref.invalidate(cartStreamProvider);
          // Wait for stream to emit new value
          final latest = await ref.read(cartStreamProvider.future);
          state = AsyncData(latest);
        });
      }
    });

    if (fbUser != null) {
      // Listen to stream when logged in
      ref.listen(cartStreamProvider, (previous, next) {
        next.whenData((cart) => state = AsyncData(cart));
      });
      return await ref.read(cartStreamProvider.future);
    } else {
      // Use local cart when logged out
      return _localCart;
    }
  }

  Future<void> addItem({
    required String productId,
    required int quantity,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final authState = ref.read(authNotifierProvider);

      if (authState.asData?.value != null) {
        final repository = ref.read(cartRepositoryProvider);
        await repository.addItem(productId: productId, quantity: quantity);
        return await ref.read(cartStreamProvider.future);
      } else {
        final currentItems = List<CartItemModel>.from(_localCart.items);
        final existingIndex = currentItems.indexWhere(
          (item) => item.productId == productId,
        );

        if (existingIndex >= 0) {
          currentItems[existingIndex] = currentItems[existingIndex].copyWith(
            quantity: currentItems[existingIndex].quantity + quantity,
          );
        } else {
          currentItems.add(
            CartItemModel(
              productId: productId,
              quantity: quantity,
              addedAt: DateTime.now(),
            ),
          );
        }

        _localCart = CartModel(items: currentItems);
        return _localCart;
      }
    });
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final authState = ref.read(authNotifierProvider);

      if (authState.asData?.value != null) {
        final repository = ref.read(cartRepositoryProvider);
        await repository.updateQuantity(
          productId: productId,
          quantity: quantity,
        );
        return await ref.read(cartStreamProvider.future);
      } else {
        if (quantity <= 0) {
          await removeItem(productId);
          return _localCart;
        }

        final currentItems = List<CartItemModel>.from(_localCart.items);
        final index = currentItems.indexWhere(
          (item) => item.productId == productId,
        );

        if (index >= 0) {
          currentItems[index] = currentItems[index].copyWith(
            quantity: quantity,
          );
          _localCart = CartModel(items: currentItems);
        }
        return _localCart;
      }
    });
  }

  Future<void> removeItem(String productId) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final authState = ref.read(authNotifierProvider);

      if (authState.asData?.value != null) {
        final repository = ref.read(cartRepositoryProvider);
        await repository.removeItem(productId);
        return await ref.read(cartStreamProvider.future);
      } else {
        final currentItems = List<CartItemModel>.from(_localCart.items);
        currentItems.removeWhere((item) => item.productId == productId);
        _localCart = CartModel(items: currentItems);
        return _localCart;
      }
    });
  }

  Future<void> clearCart() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final authState = ref.read(authNotifierProvider);

      if (authState.asData?.value != null) {
        final repository = ref.read(cartRepositoryProvider);
        await repository.clearCart();
        return await ref.read(cartStreamProvider.future);
      } else {
        _localCart = const CartModel(items: []);
        return _localCart;
      }
    });
  }

  Future<void> migrateLocalCart() async {
    if (_localCart.items.isEmpty) return;

    final authState = ref.read(authNotifierProvider);
    if (authState.asData?.value == null) return;

    final repository = ref.read(cartRepositoryProvider);

    for (final item in _localCart.items) {
      try {
        await repository.addItem(
          productId: item.productId,
          quantity: item.quantity,
        );
      } catch (e) {
        // silently ignore conflicts during migration
      }
    }
    _localCart = const CartModel(items: []);
  }
}
