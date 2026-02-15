// lib/providers/vendor_product_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/vendor_product.dart';
import '../services/vendor_product_service.dart';
import '../services/logger_service.dart';
import '../constants/enums.dart';
import '../providers/providers.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../services/camera_service.dart';

final vendorProductsProvider = StateNotifierProvider.autoDispose<
    VendorProductsNotifier, AsyncValue<List<VendorProduct>>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final productService = ref.watch(vendorProductServiceProvider);

  if (authState.status == AuthStatus.authenticated &&
      authState.vendor != null &&
      productService != null) {
    return VendorProductsNotifier(
      ref: ref,
      vendorProductService: productService,
      notificationService: ref.watch(notificationServiceProvider),
      cameraService: ref.watch(cameraServiceProvider),
      vendorId: authState.vendor!.id,
      isAdmin: authState.userRole?.isAdmin ?? false,
    );
  }

  return VendorProductsNotifier.empty(ref);
});

final filteredProductsProvider =
    Provider.autoDispose.family<List<VendorProduct>, String?>((ref, search) {
  final productsState = ref.watch(vendorProductsProvider);
  return productsState.when(
    data: (products) {
      if (search == null || search.isEmpty) return products;
      final searchLower = search.toLowerCase();
      return products.where((product) {
        return product.partName.toLowerCase().contains(searchLower) ||
            product.description.toLowerCase().contains(searchLower) ||
            (product.partNumber?.toLowerCase().contains(searchLower) ??
                false) ||
            product.brand.toLowerCase().contains(searchLower);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final productsByStatusProvider = Provider.autoDispose
    .family<List<VendorProduct>, ProductStatus>((ref, status) {
  final productsState = ref.watch(vendorProductsProvider);
  return productsState.when(
    data: (products) => products.where((p) => p.status == status).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

class VendorProductsNotifier
    extends StateNotifier<AsyncValue<List<VendorProduct>>> {
  final Ref _ref;
  final VendorProductService? _productService;
  final NotificationService? _notificationService;
  final CameraService? _cameraService;
  final String? _vendorId;
  final bool _isAdmin;
  final LoggerService _logger = LoggerService.instance;
  StreamSubscription? _productSubscription;

  VendorProductsNotifier({
    required Ref ref,
    required VendorProductService? vendorProductService,
    required NotificationService? notificationService,
    required CameraService? cameraService,
    required String? vendorId,
    required bool isAdmin,
  })  : _ref = ref,
        _productService = vendorProductService,
        _notificationService = notificationService,
        _cameraService = cameraService,
        _vendorId = vendorId,
        _isAdmin = isAdmin,
        super(const AsyncValue.loading()) {
    _listenToProducts();
  }

  VendorProductsNotifier.empty(Ref ref)
      : _ref = ref,
        _productService = null,
        _notificationService = null,
        _cameraService = null,
        _vendorId = null,
        _isAdmin = false,
        super(const AsyncValue.data([]));

  void _listenToProducts() {
    if (_productService == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    _productSubscription?.cancel();
    _productSubscription =
        _productService!.watchVendorProducts(_vendorId).listen((products) {
      state = AsyncValue.data(products);
    }, onError: (e, stack) {
      _logger.error('Failed to listen to products',
          error: e, stackTrace: stack);
      state = AsyncValue.error(e, stack);
    });
  }

  Future<void> addProduct(
      VendorProduct product, List<XFile> newImageFiles) async {
    if (_productService == null || _cameraService == null) return;

    final originalState = state;
    state = const AsyncValue.loading();
    try {
      List<String> uploadedImageUrls = [];
      for (final imageFile in newImageFiles) {
        final imageUrl = await _cameraService!.uploadProductImage(
          filePath: imageFile.path,
          vendorId: product.vendorId,
          productId: product.id,
        );
        uploadedImageUrls.add(imageUrl);
      }

      final productWithImages = product.copyWith(images: uploadedImageUrls);
      await _productService!.createProduct(productWithImages);
    } catch (e, stack) {
      _logger.error('Failed to add product', error: e, stackTrace: stack);
      state = originalState;
      rethrow;
    }
  }

  Future<void> addProductWithUrls(VendorProduct product) async {
    if (_productService == null) return;

    final originalState = state;
    state = const AsyncValue.loading();
    try {
      await _productService!.createProduct(product);
    } catch (e, stack) {
      _logger.error('Failed to add product with URLs',
          error: e, stackTrace: stack);
      state = originalState;
      rethrow;
    }
  }

  Future<void> updateProduct(VendorProduct product, List<XFile> newImageFiles,
      List<String> existingImageUrls) async {
    if (_productService == null || _cameraService == null) return;

    final originalState = state;
    state = const AsyncValue.loading();
    try {
      List<String> uploadedImageUrls = [];
      for (final imageFile in newImageFiles) {
        final imageUrl = await _cameraService!.uploadProductImage(
          filePath: imageFile.path,
          vendorId: product.vendorId,
          productId: product.id,
        );
        uploadedImageUrls.add(imageUrl);
      }

      final allImageUrls = [...existingImageUrls, ...uploadedImageUrls];
      final productWithImages = product.copyWith(images: allImageUrls);

      await _productService!.updateProduct(productWithImages);
    } catch (e, stack) {
      _logger.error('Failed to update product', error: e, stackTrace: stack);
      state = originalState;
      rethrow;
    }
  }

  Future<void> updateProductWithUrls(VendorProduct product) async {
    if (_productService == null) return;

    final originalState = state;
    state = const AsyncValue.loading();
    try {
      await _productService!.updateProduct(product);
    } catch (e, stack) {
      _logger.error('Failed to update product with URLs',
          error: e, stackTrace: stack);
      state = originalState;
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    if (_productService == null) return;
    try {
      await _productService!.deleteProduct(id);
    } catch (e, stack) {
      _logger.error('Failed to delete product', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> updateStock(String id, int newQuantity) async {
    if (_productService == null) return;
    try {
      await _productService!.updateStock(id, newQuantity);
      if (newQuantity <= 10 && _vendorId != null) {
        state.whenData((products) {
          final product = products.firstWhere((p) => p.id == id,
              orElse: () => VendorProduct.empty());
          if (product.id.isNotEmpty) {
            _sendStockAlert(product, newQuantity);
          }
        });
      }
    } catch (e, stack) {
      _logger.error('Failed to update stock', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> _sendStockAlert(VendorProduct product, int currentStock) async {
    if (_notificationService == null || _vendorId == null) return;
    try {
      await _notificationService!.sendStockAlert(
          vendorId: _vendorId!,
          productId: product.id,
          productName: product.partName,
          currentStock: currentStock);
    } catch (e) {
      _logger.error('Failed to send stock alert', error: e);
    }
  }

  @override
  void dispose() {
    _productSubscription?.cancel();
    super.dispose();
  }
}
