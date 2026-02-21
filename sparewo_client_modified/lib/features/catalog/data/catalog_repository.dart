// lib/features/catalog/data/catalog_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/features/catalog/domain/product_model.dart';

class CatalogRepository {
  final FirebaseFirestore _firestore;
  static const Map<String, List<String>> _categoryKeywordMap = {
    'tyres': ['tyre', 'tyres', 'tire', 'tires', 'tubeless', 'all-season'],
    'engine': [
      'engine',
      'motor',
      'piston',
      'gasket',
      'radiator',
      'spark',
      'filter',
      'timing',
      'injector',
    ],
    'body': [
      'body',
      'body kit',
      'bodykit',
      'bumper',
      'bonnet',
      'hood',
      'door',
      'fender',
      'panel',
      'grille',
      'grill',
      'mirror',
      'spoiler',
      'trunk',
    ],
    'electrical': [
      'electrical',
      'electrics',
      'alternator',
      'battery',
      'starter',
      'sensor',
      'wiring',
      'headlight',
      'taillight',
      'fuse',
      'relay',
      'ecu',
    ],
    'chassis': [
      'chassis',
      'frame',
      'axle',
      'control arm',
      'bearing',
      'hub',
      'mount',
      'steering',
      'suspension',
      'shock',
      'strut',
      'absorber',
    ],
    'suspension': [
      'suspension',
      'shock',
      'strut',
      'absorber',
      'coil',
      'spring',
      'stabilizer',
      'bush',
    ],
    'accessories': [
      'accessory',
      'accessories',
      'mat',
      'cover',
      'bulb',
      'wiper',
      'cleaner',
      'freshener',
      'charger',
      'phone holder',
    ],
  };

  CatalogRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<ProductModel>> getCatalogProducts({
    String? category,
    String? searchQuery,
  }) {
    Query query = _firestore.collection('catalog_products');
    query = query.where('isActive', isEqualTo: true);

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
          AppLogger.warn(
            'CatalogRepository',
            'Failed to parse catalog product',
            extra: {'productId': doc.id, 'error': e.toString()},
          );
        }
      }

      var filtered = products;

      if (category != null && category.trim().isNotEmpty) {
        filtered = filtered
            .where((product) => _matchesCategoryFallback(product, category))
            .toList();
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final searchLower = searchQuery.trim().toLowerCase();
        filtered = filtered
            .where((product) => _matchesSearchQuery(product, searchLower))
            .toList();
      }

      return filtered;
    });
  }

  bool _matchesSearchQuery(ProductModel product, String queryLower) {
    return product.partName.toLowerCase().contains(queryLower) ||
        product.brand.toLowerCase().contains(queryLower) ||
        product.description.toLowerCase().contains(queryLower) ||
        (product.partNumber?.toLowerCase().contains(queryLower) ?? false);
  }

  bool _matchesCategoryFallback(ProductModel product, String rawCategory) {
    final normalizedCategory = _canonicalCategory(rawCategory);

    if (normalizedCategory.isEmpty ||
        normalizedCategory == 'all' ||
        normalizedCategory == 'all parts') {
      return true;
    }

    final normalizedProductCategories = <String>{
      for (final category in product.categories) _canonicalCategory(category),
      if (product.category != null) _canonicalCategory(product.category!),
    };

    // Honor explicit category tagging first when available.
    if (normalizedProductCategories.contains(normalizedCategory)) {
      return true;
    }

    if (normalizedCategory == 'more') {
      return normalizedProductCategories.contains('accessories') ||
          _matchesCategoryByKeywords(product, 'accessories');
    }

    final keywordGroup = normalizedCategory == 'body kits'
        ? 'body'
        : normalizedCategory;

    return _matchesCategoryByKeywords(product, keywordGroup);
  }

  bool _matchesCategoryByKeywords(ProductModel product, String categoryKey) {
    final keywords = _categoryKeywordMap[categoryKey];
    if (keywords == null || keywords.isEmpty) return false;

    final haystack = <String>[
      product.partName,
      product.description,
      product.brand,
      product.partNumber ?? '',
      ...product.specifications.values.map((value) => value.toString()),
    ].join(' ').toLowerCase().replaceAll(RegExp(r'[_-]+'), ' ');

    return keywords.any((keyword) => _containsKeyword(haystack, keyword));
  }

  bool _containsKeyword(String haystack, String keyword) {
    final normalizedKeyword = keyword.trim().toLowerCase();
    if (normalizedKeyword.isEmpty) return false;

    // Multi-word phrases can be matched as a plain substring.
    if (normalizedKeyword.contains(' ')) {
      return haystack.contains(normalizedKeyword);
    }

    // Single-word keywords use word boundaries to avoid false positives
    // like matching "wheel" in "steering wheel alignment" for tyre filters.
    final pattern = RegExp(
      '(^|[^a-z0-9])${RegExp.escape(normalizedKeyword)}([^a-z0-9]|\\\$)',
    );
    return pattern.hasMatch(haystack);
  }

  String _canonicalCategory(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    switch (normalized) {
      case 'tyre':
      case 'tyres':
      case 'tire':
      case 'tires':
      case 'tyres & wheels':
      case 'tyres and wheels':
      case 'tires & wheels':
      case 'tires and wheels':
        return 'tyres';
      case 'chasis':
        return 'chassis';
      case 'electricals':
      case 'electric':
        return 'electrical';
      case 'body kits':
      case 'body kit':
      case 'bodykits':
      case 'bodykit':
        return 'body';
      case 'accessory':
      case 'accessories':
        return 'accessories';
      case 'more':
        return 'more';
      default:
        return normalized;
    }
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
      AppLogger.error(
        'CatalogRepository',
        'Error fetching product by ID',
        error: e,
      );
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
      AppLogger.error(
        'CatalogRepository',
        'Error fetching product categories',
        error: e,
      );
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
              AppLogger.warn(
                'CatalogRepository',
                'Failed to parse featured product',
                extra: {'productId': doc.id, 'error': e.toString()},
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
      AppLogger.error(
        'CatalogRepository',
        'Error searching by part number',
        error: e,
      );
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
