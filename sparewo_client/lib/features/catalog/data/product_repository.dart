// lib/features/catalog/data/product_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/features/catalog/domain/product_model.dart';

// Legacy repository for backward compatibility
// New code should use CatalogRepository instead
class ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get products stream with optional filtering
  Stream<List<ProductModel>> getProducts({String? category}) {
    Query query = _firestore.collection('catalog_products');

    query = query.where('isActive', isEqualTo: true);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ProductModel.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            });
          }).toList();
        })
        .handleError((error, stackTrace) {
          AppLogger.error(
            'ProductRepository.getProducts.streamError',
            error.toString(),
            stackTrace: stackTrace,
            extra: {'category': category},
          );
          // Pass error downstream
          throw error;
        });
  }

  // Search products
  Stream<List<ProductModel>> searchProducts(String searchQuery) {
    if (searchQuery.isEmpty) {
      return getProducts();
    }

    final upperQuery = searchQuery.toUpperCase();

    return _firestore
        .collection('catalog_products')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final products = snapshot.docs.map((doc) {
            return ProductModel.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            });
          }).toList();

          // Filter by search query
          return products.where((product) {
            final searchLower = searchQuery.toLowerCase();
            return product.partName.toLowerCase().contains(searchLower) ||
                product.brand.toLowerCase().contains(searchLower) ||
                (product.partNumber?.toUpperCase().contains(upperQuery) ??
                    false) ||
                product.description.toLowerCase().contains(searchLower);
          }).toList();
        })
        .handleError((error, stackTrace) {
          AppLogger.error(
            'ProductRepository.searchProducts.streamError',
            error.toString(),
            stackTrace: stackTrace,
            extra: {'query': searchQuery},
          );
          throw error;
        });
  }

  // Get single product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _firestore
          .collection('catalog_products')
          .doc(productId)
          .get();

      if (!doc.exists) {
        AppLogger.warn(
          'products.getById.notFound',
          'Product not found',
          extra: {'productId': productId},
        );
        return null;
      }

      return ProductModel.fromJson({'id': doc.id, ...doc.data()!});
    } catch (e, st) {
      AppLogger.error(
        'products.getById.error',
        e.toString(),
        stackTrace: st,
        extra: {'productId': productId},
      );
      return null;
    }
  }
}
