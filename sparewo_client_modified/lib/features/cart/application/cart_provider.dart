// lib/features/cart/application/cart_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/cart/data/cart_repository.dart';
import 'package:sparewo_client/features/cart/domain/cart_model.dart';
import 'package:sparewo_client/features/cart/domain/cart_item_model.dart';
import 'package:sparewo_client/features/catalog/application/product_provider.dart';

// 1. Repository Provider
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  return CartRepository(userId: user?.uid);
});

// 1.1 Reactive Subtotal Provider
final cartSubtotalProvider = FutureProvider<double>((ref) async {
  final cartAsync = ref.watch(cartNotifierProvider);
  final cart = cartAsync.asData?.value;
  if (cart == null || cart.items.isEmpty) return 0.0;

  double subtotal = 0.0;
  for (final item in cart.items) {
    try {
      final product = await ref.watch(
        productByIdProvider(item.productId).future,
      );
      if (product != null) {
        subtotal += product.unitPrice * item.quantity;
      }
    } catch (_) {
      // Ignore errors for individual products and continue
    }
  }
  return subtotal;
});

// 2. Cart Stream Provider
final cartStreamProvider = StreamProvider<CartModel>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null || uid.isEmpty) {
    return Stream.value(const CartModel(items: []));
  }

  final repository = CartRepository(userId: uid);
  return repository.getUserCart();
});

// 3. Cart Notifier
final cartNotifierProvider = AsyncNotifierProvider<CartNotifier, CartModel>(
  CartNotifier.new,
);

class CartNotifier extends AsyncNotifier<CartModel> {
  static const _guestCartStorageKey = 'sparewo.guest_cart.v1';

  // Initial local state
  CartModel _localCart = const CartModel(items: []);
  bool _localCartHydrated = false;
  bool _authListenerRegistered = false;
  bool _cartStreamListenerRegistered = false;
  bool _isMigratingLocalCart = false;

  fb_auth.User? _effectiveAuthUser() {
    return ref.read(authStateChangesProvider).asData?.value ??
        fb_auth.FirebaseAuth.instance.currentUser;
  }

  @override
  FutureOr<CartModel> build() async {
    if (!_localCartHydrated) {
      _localCart = await _loadLocalCart();
      _localCartHydrated = true;
    }

    final userAsync = ref.watch(authStateChangesProvider);
    final fbUser = userAsync.asData?.value;

    if (!_authListenerRegistered) {
      _authListenerRegistered = true;
      // Listen for login changes once to migrate guest cart
      ref.listen(authStateChangesProvider, (prev, next) {
        final wasLoggedIn = prev?.asData?.value != null;
        final isLoggedIn = next.asData?.value != null;
        if (!wasLoggedIn && isLoggedIn) {
          final uid = next.asData?.value?.uid;
          if (uid == null || uid.isEmpty) return;
          Future.microtask(() async {
            await migrateLocalCart();
            try {
              final latest = await CartRepository(
                userId: uid,
              ).getUserCart().first;
              state = AsyncData(latest);
            } catch (_) {
              // Ignore transient stream races during auth transitions
            }
          });
        }
      });
    }

    if (fbUser != null) {
      if (_localCart.items.isNotEmpty) {
        await migrateLocalCart();
      }

      // Listen to stream when logged in
      if (!_cartStreamListenerRegistered) {
        _cartStreamListenerRegistered = true;
        ref.listen(cartStreamProvider, (previous, next) {
          next.whenData((cart) => state = AsyncData(cart));
        });
      }
      return await CartRepository(userId: fbUser.uid).getUserCart().first;
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
      // Fix: Use authStateChangesProvider to check actual login status
      // authNotifierProvider only shows *action* state, not *session* state.
      final user = _effectiveAuthUser();

      if (user != null) {
        final repository = CartRepository(userId: user.uid);
        await repository.addItem(productId: productId, quantity: quantity);
        return await repository.getUserCart().first;
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
        await _persistLocalCart(_localCart);
        return _localCart;
      }
    });
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      // Fix: Use authStateChangesProvider to check actual login status
      // authNotifierProvider only shows *action* state, not *session* state.
      final user = _effectiveAuthUser();

      if (user != null) {
        final repository = CartRepository(userId: user.uid);
        await repository.updateQuantity(
          productId: productId,
          quantity: quantity,
        );
        return await repository.getUserCart().first;
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
          await _persistLocalCart(_localCart);
        }
        return _localCart;
      }
    });
  }

  Future<void> removeItem(String productId) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      // Fix: Use authStateChangesProvider to check actual login status
      // authNotifierProvider only shows *action* state, not *session* state.
      final user = _effectiveAuthUser();

      if (user != null) {
        final repository = CartRepository(userId: user.uid);
        await repository.removeItem(productId);
        return await repository.getUserCart().first;
      } else {
        final currentItems = List<CartItemModel>.from(_localCart.items);
        currentItems.removeWhere((item) => item.productId == productId);
        _localCart = CartModel(items: currentItems);
        await _persistLocalCart(_localCart);
        return _localCart;
      }
    });
  }

  Future<void> clearCart() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      // Fix: Use authStateChangesProvider to check actual login status
      // authNotifierProvider only shows *action* state, not *session* state.
      final user = _effectiveAuthUser();

      if (user != null) {
        final repository = CartRepository(userId: user.uid);
        await repository.clearCart();
        return await repository.getUserCart().first;
      } else {
        _localCart = const CartModel(items: []);
        await _clearPersistedLocalCart();
        return _localCart;
      }
    });
  }

  Future<void> migrateLocalCart() async {
    if (_isMigratingLocalCart || _localCart.items.isEmpty) return;

    final user = _effectiveAuthUser();
    if (user == null) return;

    _isMigratingLocalCart = true;
    final repository = CartRepository(userId: user.uid);

    try {
      final failedItems = <CartItemModel>[];
      for (final item in _localCart.items) {
        try {
          await repository.addItem(
            productId: item.productId,
            quantity: item.quantity,
          );
        } catch (_) {
          failedItems.add(item);
        }
      }

      _localCart = CartModel(items: failedItems);
      if (failedItems.isEmpty) {
        await _clearPersistedLocalCart();
      } else {
        await _persistLocalCart(_localCart);
      }
    } finally {
      _isMigratingLocalCart = false;
    }
  }

  Future<CartModel> _loadLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_guestCartStorageKey);
      if (raw == null || raw.isEmpty) {
        return const CartModel(items: []);
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const CartModel(items: []);
      }

      final rawItems = decoded['items'];
      if (rawItems is! List) {
        return const CartModel(items: []);
      }

      final items = <CartItemModel>[];
      for (final entry in rawItems) {
        if (entry is! Map) continue;
        final map = Map<String, dynamic>.from(entry);

        final productId = (map['productId'] ?? '').toString();
        final quantity = map['quantity'] is int
            ? map['quantity'] as int
            : int.tryParse('${map['quantity']}') ?? 0;
        if (productId.isEmpty || quantity <= 0) continue;

        final addedAtRaw = map['addedAt'];
        final updatedAtRaw = map['updatedAt'];
        final addedAt = addedAtRaw is String
            ? DateTime.tryParse(addedAtRaw)
            : null;
        final updatedAt = updatedAtRaw is String
            ? DateTime.tryParse(updatedAtRaw)
            : null;

        items.add(
          CartItemModel(
            productId: productId,
            quantity: quantity,
            addedAt: addedAt ?? DateTime.now(),
            updatedAt: updatedAt,
          ),
        );
      }

      return CartModel(items: items);
    } catch (_) {
      return const CartModel(items: []);
    }
  }

  Future<void> _persistLocalCart(CartModel cart) async {
    final prefs = await SharedPreferences.getInstance();
    final localJson = <String, dynamic>{
      'items': [
        for (final item in cart.items)
          {
            'productId': item.productId,
            'quantity': item.quantity,
            'addedAt': item.addedAt.toIso8601String(),
            if (item.updatedAt != null)
              'updatedAt': item.updatedAt!.toIso8601String(),
          },
      ],
    };
    await prefs.setString(_guestCartStorageKey, jsonEncode(localJson));
  }

  Future<void> _clearPersistedLocalCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestCartStorageKey);
  }
}
