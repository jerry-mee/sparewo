// lib/features/catalog/data/catalog_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sparewo_client/features/catalog/domain/product_model.dart';

class CatalogRepository {
  final FirebaseFirestore _firestore;

  CatalogRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<ProductModel>> getCatalogProducts({
    String? category,
    String? searchQuery,
  }) {
    Query query = _firestore.collection('catalog_products');
    query = query.where('isActive', isEqualTo: true);

    if (category != null && category.isNotEmpty) {
      query = query.where('categories', arrayContains: category);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      final products = <ProductModel>[];
      for (final doc in snapshot.docs) {
        try {
          final product = ProductModel.fromFirestore(
            doc.id,
            doc.data() as Map<String, dynamic>,
          );
          products.add(product);
        } catch (e) {
          debugPrint('Failed to parse product with ID ${doc.id}: $e');
        }
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        final upperQuery = searchQuery.toUpperCase();
        return products.where((product) {
          return product.partName.toLowerCase().contains(searchLower) ||
              product.brand.toLowerCase().contains(searchLower) ||
              (product.partNumber?.toUpperCase().contains(upperQuery) ??
                  false) ||
              product.description.toLowerCase().contains(searchLower);
        }).toList();
      }

      return products;
    });
  }

  Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _firestore
          .collection('catalog_products')
          .doc(productId)
          .get();

      if (!doc.exists) return null;

      return ProductModel.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching product: $e');
      return null;
    }
  }

  Future<List<String>> getProductCategories() async {
    try {
      final snapshot = await _firestore
          .collection('catalog_products')
          .where('isActive', isEqualTo: true)
          .get();

      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final categoryList = doc.data()['categories'] as List<dynamic>?;
        if (categoryList != null) {
          for (final cat in categoryList) {
            if (cat is String && cat.isNotEmpty) {
              categories.add(cat);
            }
          }
        }
      }

      final sortedCategories = categories.toList()..sort();
      return sortedCategories;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching categories: $e');
      return [];
    }
  }

  Stream<List<ProductModel>> getFeaturedProducts({int limit = 6}) {
    return _firestore
        .collection('catalog_products')
        .where('isActive', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final products = <ProductModel>[];
          for (final doc in snapshot.docs) {
            try {
              products.add(ProductModel.fromFirestore(doc.id, doc.data()));
            } catch (e) {
              debugPrint(
                'Failed to parse featured product with ID ${doc.id}: $e',
              );
            }
          }
          return products;
        });
  }

  Stream<List<ProductModel>> getProductsByBrand(String brand) {
    return _firestore
        .collection('catalog_products')
        .where('isActive', isEqualTo: true)
        .where('brand', isEqualTo: brand)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ProductModel.fromFirestore(doc.id, doc.data());
          }).toList();
        });
  }

  Stream<List<ProductModel>> getProductsForVehicle({
    required String make,
    required String model,
    required int year,
  }) {
    return getCatalogProducts();
  }

  Future<List<ProductModel>> searchByPartNumber(String partNumber) async {
    try {
      final snapshot = await _firestore
          .collection('catalog_products')
          .where('isActive', isEqualTo: true)
          .where('partNumber', isEqualTo: partNumber.toUpperCase())
          .get();

      return snapshot.docs.map((doc) {
        return ProductModel.fromFirestore(doc.id, doc.data());
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error searching by part number: $e');
      return [];
    }
  }

  Stream<List<ProductModel>> getRecentProducts({int limit = 10}) {
    return _firestore
        .collection('catalog_products')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ProductModel.fromFirestore(doc.id, doc.data());
          }).toList();
        });
  }
}
