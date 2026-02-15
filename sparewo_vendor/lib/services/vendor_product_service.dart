// lib/services/vendor_product_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/vendor_product.dart';
import '../constants/enums.dart';
import '../exceptions/api_exceptions.dart';
import '../services/camera_service.dart';
import '../services/logger_service.dart';

class VendorProductService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final CameraService _cameraService;
  final String? _vendorId;
  final bool isAdmin;
  final String _collectionName = 'vendor_products';
  final LoggerService _logger = LoggerService.instance;

  VendorProductService({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    CameraService? cameraService,
    required String? vendorId,
    this.isAdmin = false,
  })  : _firestore = firestore,
        _storage = storage,
        _cameraService = cameraService ?? CameraService(storage: storage),
        _vendorId = vendorId;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection(_collectionName);

  CollectionReference<Map<String, dynamic>> get _draftsRef =>
      _firestore.collection('product_drafts');

  /// Validates that the vendor ID is available.
  void _validateVendorId() {
    if (_vendorId == null || _vendorId!.isEmpty) {
      throw const ApiException(
        message: 'User not authenticated. Please sign in to continue.',
        statusCode: 401,
      );
    }
  }

  /// Creates a new vendor product after validating the vendor ID and uploading images.
  Future<VendorProduct> createProduct(VendorProduct product) async {
    try {
      _validateVendorId();
      _logger.info('Creating product', error: {
        'vendorId': _vendorId,
        'productName': product.partName,
        'category': product.category.name,
      });

      // For non-admin users, always set status to pending
      final productStatus = isAdmin ? product.status : ProductStatus.pending;
      _logger.info('Setting product status to: ${productStatus.name}');

      // Process images - upload any that are file paths
      final List<String> uploadedImages = await Future.wait<String>(
        product.images.map((path) async {
          if (path.startsWith('http')) return path;
          try {
            return await _cameraService.uploadProductImage(
              filePath: path,
              vendorId: _vendorId,
              productId: product.id,
            );
          } catch (e) {
            _logger.error('Failed to upload image during product creation',
                error: e);
            rethrow;
          }
        }),
      );

      final docRef = _productsRef.doc(product.id);
      final newProduct = product.copyWith(
        id: product.id.isEmpty ? docRef.id : product.id,
        vendorId: _vendorId!,
        status: productStatus,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        images: uploadedImages,
      );

      // Convert to Firestore data
      final productData = newProduct.toFirestore();

      // Explicitly add status field to ensure it's not missed
      productData['status'] = productStatus.toString().split('.').last;

      // Explicitly add category field to ensure it's not missed
      productData['category'] = newProduct.category.toString().split('.').last;

      await docRef.set(productData);

      _logger.info(
          'Product created successfully with status: ${productStatus.name} and category: ${newProduct.category.name}',
          error: {
            'id': newProduct.id,
            'status': productStatus.name,
            'category': newProduct.category.name,
          });

      // Delete any draft after successful creation
      await _deleteDraft(newProduct.id);

      return newProduct;
    } catch (e) {
      _logger.error('Failed to create product', error: e);
      throw ApiException(
        message: e is ApiException
            ? e.message
            : 'Failed to create product: ${e.toString()}',
        statusCode: e is ApiException ? e.statusCode : 500,
      );
    }
  }

  /// Save a product draft for later completion
  Future<void> saveDraft(VendorProduct draft) async {
    try {
      _validateVendorId();

      final docRef = _draftsRef.doc(draft.id.isEmpty ? null : draft.id);
      final draftWithId = draft.copyWith(
        id: draft.id.isEmpty ? docRef.id : draft.id,
        vendorId: _vendorId!,
        updatedAt: DateTime.now(),
      );

      await docRef.set(draftWithId.toFirestore());
      _logger.info('Draft saved successfully', error: {'id': draftWithId.id});
    } catch (e) {
      _logger.error('Failed to save draft', error: e);
      throw ApiException(
        message: 'Failed to save draft: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Get all drafts for the current vendor
  Future<List<VendorProduct>> getDrafts() async {
    try {
      _validateVendorId();

      final querySnapshot = await _draftsRef
          .where('vendorId', isEqualTo: _vendorId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VendorProduct.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.error('Failed to load drafts', error: e);
      throw ApiException(
        message: 'Failed to load drafts: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Get a specific draft by ID
  Future<VendorProduct?> getDraft(String draftId) async {
    try {
      _validateVendorId();

      final docSnapshot = await _draftsRef.doc(draftId).get();
      if (!docSnapshot.exists) return null;

      final draft = VendorProduct.fromFirestore(docSnapshot);
      if (draft.vendorId != _vendorId && !isAdmin) {
        throw const ApiException(
          message: 'You do not have permission to access this draft',
          statusCode: 403,
        );
      }

      return draft;
    } catch (e) {
      _logger.error('Failed to load draft', error: e);
      throw ApiException(
        message: 'Failed to load draft: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Delete a draft
  Future<void> _deleteDraft(String draftId) async {
    try {
      await _draftsRef.doc(draftId).delete();
      _logger.info('Draft deleted successfully', error: {'id': draftId});
    } catch (e) {
      // Just log the error, don't throw - we don't want to fail the main operation
      _logger.error('Failed to delete draft', error: e);
    }
  }

  /// Uploads a product image using the vendorId in the storage path.
  Future<String> uploadProductImage(String filePath) async {
    try {
      _validateVendorId();

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';

      // Fix storage path to match Firestore security rules
      final ref = _storage.ref().child('vendors/$_vendorId/products/$fileName');

      final file = File(filePath);
      final metadata = SettableMetadata(
        contentType: 'image/${filePath.split('.').last}',
        customMetadata: {
          'vendorId': _vendorId!,
          'uploadTimestamp': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = await ref.putFile(file, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      _logger.error('Failed to upload image', error: e);
      throw ApiException(
        message: e is ApiException
            ? e.message
            : 'Failed to upload image: ${e.toString()}',
        statusCode: e is ApiException ? e.statusCode : 500,
      );
    }
  }

  /// Retrieves all vendor products for the specified vendor ID.
  Future<List<VendorProduct>> getVendorProducts(String? vendorId) async {
    try {
      final targetVendorId = vendorId ?? _vendorId;

      if (!isAdmin && (targetVendorId == null || targetVendorId.isEmpty)) {
        throw const ApiException(
          message: 'Vendor ID is required for product operations',
          statusCode: 400,
        );
      }

      final query = isAdmin && targetVendorId == null
          ? _productsRef.orderBy('createdAt', descending: true)
          : _productsRef
              .where('vendorId', isEqualTo: targetVendorId)
              .orderBy('createdAt', descending: true);

      final querySnapshot = await query.get();
      final products = querySnapshot.docs
          .map((doc) => VendorProduct.fromFirestore(doc))
          .toList();

      _logger.info(
          'Retrieved ${products.length} products for vendor $targetVendorId');
      return products;
    } catch (e) {
      _logger.error('Error loading vendor products: $e');
      throw ApiException(
        message: 'Failed to load vendor products: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Retrieves products by category
  Future<List<VendorProduct>> getProductsByCategory(
      ProductCategory category) async {
    try {
      final query = _productsRef
          .where('category', isEqualTo: category.name)
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true);

      final querySnapshot = await query.get();
      final products = querySnapshot.docs
          .map((doc) => VendorProduct.fromFirestore(doc))
          .toList();

      _logger.info(
          'Retrieved ${products.length} products for category ${category.name}');
      return products;
    } catch (e) {
      _logger.error('Error loading products by category: $e');
      throw ApiException(
        message: 'Failed to load products by category: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Retrieves paginated products with offset and limit
  Future<List<VendorProduct>> getPaginatedProducts(
      String? vendorId, int offset, int limit) async {
    try {
      final targetVendorId = vendorId ?? _vendorId;

      if (!isAdmin && (targetVendorId == null || targetVendorId.isEmpty)) {
        throw const ApiException(
          message: 'Vendor ID is required for product operations',
          statusCode: 400,
        );
      }

      Query<Map<String, dynamic>> query;

      if (isAdmin && targetVendorId == null) {
        query = _productsRef.orderBy('createdAt', descending: true);
      } else {
        query = _productsRef
            .where('vendorId', isEqualTo: targetVendorId)
            .orderBy('createdAt', descending: true);
      }

      // Apply pagination
      query = query.limit(limit);

      if (offset > 0) {
        // If this is not the first page, we need to use startAfter
        // First get all products up to offset
        final allProductsQuery = isAdmin && targetVendorId == null
            ? _productsRef.orderBy('createdAt', descending: true).limit(offset)
            : _productsRef
                .where('vendorId', isEqualTo: targetVendorId)
                .orderBy('createdAt', descending: true)
                .limit(offset);

        final snapshot = await allProductsQuery.get();

        // If we have fewer documents than the offset, return empty list
        if (snapshot.docs.length < offset) {
          return [];
        }

        // Get the last document
        final lastDoc = snapshot.docs.last;

        // Start after that document
        query = query.startAfterDocument(lastDoc);
      }

      final querySnapshot = await query.get();
      final products = querySnapshot.docs
          .map((doc) => VendorProduct.fromFirestore(doc))
          .toList();

      _logger.info(
          'Retrieved ${products.length} paginated products (offset: $offset, limit: $limit)');
      return products;
    } catch (e) {
      _logger.error('Error loading paginated products: $e');
      throw ApiException(
        message: 'Failed to load paginated products: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Watches vendor products for real-time updates.
  Stream<List<VendorProduct>> watchVendorProducts(String? vendorId) {
    final targetVendorId = vendorId ?? _vendorId;

    if (!isAdmin && (targetVendorId == null || targetVendorId.isEmpty)) {
      throw const ApiException(
        message: 'Vendor ID is required for watching products',
        statusCode: 400,
      );
    }

    final query = isAdmin && targetVendorId == null
        ? _productsRef.orderBy('createdAt', descending: true)
        : _productsRef
            .where('vendorId', isEqualTo: targetVendorId)
            .orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      final products =
          snapshot.docs.map((doc) => VendorProduct.fromFirestore(doc)).toList();
      _logger.info(
          'Watching ${products.length} products for vendor $targetVendorId');
      return products;
    });
  }

  /// Updates an existing vendor product.
  Future<VendorProduct> updateProduct(VendorProduct product) async {
    try {
      _validateVendorId();

      final docRef = _productsRef.doc(product.id);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw ApiException(
          message: 'Product not found: ${product.id}',
          statusCode: 404,
        );
      }

      // Only admins can change status directly, others will have product set to pending on update
      final updatedStatus = isAdmin ? product.status : ProductStatus.pending;
      _logger.info('Setting updated product status to: ${updatedStatus.name}');

      // Process images - upload any that are file paths
      final List<String> updatedImages = await Future.wait<String>(
        product.images.map((path) async {
          if (path.startsWith('http')) return path;
          return await _cameraService.uploadProductImage(
            filePath: path,
            vendorId: _vendorId,
            productId: product.id,
          );
        }),
      );

      final updatedProduct = product.copyWith(
        updatedAt: DateTime.now(),
        status: updatedStatus,
        images: updatedImages,
      );

      // Convert to Firestore data
      final productData = updatedProduct.toFirestore();

      // Explicitly add status field to ensure it's not missed
      productData['status'] = updatedStatus.toString().split('.').last;

      // Explicitly add category field to ensure it's not missed
      productData['category'] =
          updatedProduct.category.toString().split('.').last;

      await docRef.update(productData);

      _logger.info(
          'Successfully updated product ${product.id} with status: ${updatedStatus.name} and category: ${updatedProduct.category.name}');

      // Delete any draft after successful update
      await _deleteDraft(product.id);

      return updatedProduct;
    } catch (e) {
      _logger.error('Error updating product: $e');
      throw ApiException(
        message: 'Failed to update product: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Deletes a vendor product and its associated images.
  Future<void> deleteProduct(String id) async {
    try {
      _validateVendorId();

      final docRef = _productsRef.doc(id);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw ApiException(
          message: 'Product not found: $id',
          statusCode: 404,
        );
      }

      final product = VendorProduct.fromFirestore(doc);

      // Ensure vendor can only delete their own products unless they're admin
      if (!isAdmin && product.vendorId != _vendorId) {
        throw const ApiException(
          message: 'You do not have permission to delete this product',
          statusCode: 403,
        );
      }

      // Delete product images from storage.
      await Future.wait(
        product.images.map((imageUrl) async {
          if (imageUrl.startsWith('http')) {
            try {
              final ref = _storage.refFromURL(imageUrl);
              await ref.delete();
            } catch (e) {
              _logger.error('Error deleting image $imageUrl: $e');
            }
          }
        }),
      );

      // Delete the product document.
      await docRef.delete();

      // Delete any draft
      await _deleteDraft(id);

      _logger.info('Successfully deleted product: $id');
    } catch (e) {
      _logger.error('Error deleting product: $e');
      throw ApiException(
        message: 'Failed to delete product: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Updates the status of a product (admins only).
  Future<void> updateProductStatus(String id, ProductStatus newStatus) async {
    try {
      if (!isAdmin) {
        throw const ApiException(
          message: 'Only admins can update product status',
          statusCode: 403,
        );
      }

      await _productsRef.doc(id).update({
        'status': newStatus.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.info('Successfully updated product status: $id -> $newStatus');
    } catch (e) {
      _logger.error('Error updating product status: $e');
      throw ApiException(
        message: 'Failed to update product status: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Updates the stock quantity for a product.
  Future<void> updateStock(String id, int newQuantity) async {
    try {
      _validateVendorId();

      if (newQuantity < 0) {
        throw const ApiException(
          message: 'Stock quantity cannot be negative',
          statusCode: 400,
        );
      }

      final docRef = _productsRef.doc(id);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw ApiException(
          message: 'Product not found: $id',
          statusCode: 404,
        );
      }

      final product = VendorProduct.fromFirestore(doc);

      // Check if user is allowed to update this product
      if (!isAdmin && product.vendorId != _vendorId) {
        throw const ApiException(
          message: 'You do not have permission to update this product',
          statusCode: 403,
        );
      }

      await docRef.update({
        'stockQuantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.info('Successfully updated product stock: $id -> $newQuantity');
    } catch (e) {
      _logger.error('Error updating product stock: $e');
      throw ApiException(
        message: 'Failed to update product stock: ${e.toString()}',
        statusCode: 500,
      );
    }
  }
}
