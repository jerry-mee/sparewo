import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/vehicle_compatibility.dart';
import '../exceptions/api_exceptions.dart';
import '../constants/enums.dart';

class ProductService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProductService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  Future<List<CarPart>> getVendorProducts(String vendorId) async {
    try {
      final querySnapshot = await _productsRef
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CarPart.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch products: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<CarPart> getProduct(String productId) async {
    try {
      final doc = await _productsRef.doc(productId).get();
      if (!doc.exists) {
        throw const ApiException(
          message: 'Product not found',
          statusCode: 404,
        );
      }
      return CarPart.fromFirestore(doc);
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch product: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<CarPart> createProduct(CarPart product) async {
    try {
      // Upload images first
      final uploadedImages = await Future.wait(
        product.images.map((path) => _uploadProductImage(path)),
      );

      final docRef = _productsRef.doc();
      final newProduct = product.copyWith(
        id: docRef.id,
        images: uploadedImages,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ProductStatus.pending,
      );

      await docRef.set(newProduct.toFirestore());
      return newProduct;
    } catch (e) {
      throw ApiException(
        message: 'Failed to create product: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<CarPart> updateProduct(CarPart product) async {
    try {
      // Handle new image uploads
      final imageUrls = await Future.wait(
        product.images.map((path) => path.startsWith('http')
            ? Future.value(path)
            : _uploadProductImage(path)),
      );

      final updatedProduct = product.copyWith(
        images: imageUrls,
        updatedAt: DateTime.now(),
      );

      await _productsRef.doc(product.id).update(updatedProduct.toFirestore());

      return updatedProduct;
    } catch (e) {
      throw ApiException(
        message: 'Failed to update product: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      final product = await getProduct(productId);

      // Delete images from storage
      await Future.wait(
        product.images
            .where((path) => path.startsWith('http'))
            .map(_deleteProductImage),
      );

      await _productsRef.doc(productId).delete();
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete product: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<String> _uploadProductImage(String path) async {
    try {
      final file = File(path);
      final fileName =
          'product_${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
      final ref = _storage.ref().child('products/$fileName');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': path},
      );

      final uploadTask = await ref.putFile(file, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw ApiException(
        message: 'Failed to upload image: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<void> _deleteProductImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Log error but don't throw - image might have been already deleted
      print('Warning: Failed to delete image: ${e.toString()}');
    }
  }

  Future<List<CarPart>> searchProducts(String vendorId, String query) async {
    try {
      final querySnapshot = await _productsRef
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('name')
          .startAt([query.toLowerCase()]).endAt(
              ['${query.toLowerCase()}\uf8ff']).get();

      return querySnapshot.docs
          .map((doc) => CarPart.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ApiException(
        message: 'Failed to search products: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Stream<List<CarPart>> watchVendorProducts(String vendorId) {
    return _productsRef
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CarPart.fromFirestore(doc)).toList());
  }
}
