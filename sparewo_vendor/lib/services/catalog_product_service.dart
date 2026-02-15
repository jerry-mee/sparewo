// lib/services/catalog_product_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/catalog_product.dart';
import '../models/vendor_product.dart';
import '../exceptions/api_exceptions.dart';
import '../constants/enums.dart';

class CatalogProductService {
  final FirebaseFirestore _firestore;
  final String _collectionName = 'catalog_products';

  CatalogProductService({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection(_collectionName);

  Future<CatalogProduct> createFromVendorProduct(
    VendorProduct vendorProduct, {
    required double retailPrice,
    required bool installationService,
    required String estimatedDelivery,
    String? warrantyInfo,
  }) async {
    try {
      final docRef = _productsRef.doc();

      // Convert List<VehicleCompatibility> to Map<String, dynamic>
      final compatibilityMap = <String, dynamic>{};
      for (final vehicle in vendorProduct.compatibility) {
        if (!compatibilityMap.containsKey(vehicle.brand)) {
          compatibilityMap[vehicle.brand] = <String, dynamic>{};
        }
        if (!compatibilityMap[vehicle.brand].containsKey(vehicle.model)) {
          compatibilityMap[vehicle.brand][vehicle.model] = [];
        }
        compatibilityMap[vehicle.brand][vehicle.model]
            .addAll(vehicle.compatibleYears);
      }

      final catalogProduct = CatalogProduct(
        id: docRef.id,
        partName: vendorProduct.partName,
        description: vendorProduct.description,
        brand: vendorProduct.brand,
        partNumber: vendorProduct.partNumber,
        condition:
            vendorProduct.condition == PartCondition.new_ ? 'new' : 'used',
        retailPrice: retailPrice,
        compatibility: compatibilityMap,
        images: vendorProduct.images,
        specifications: {
          'quality_grade': vendorProduct.qualityGrade,
          'condition':
              vendorProduct.condition == PartCondition.new_ ? 'new' : 'used',
        },
        available: true,
        estimatedDelivery: estimatedDelivery,
        warrantyInfo: warrantyInfo,
        installationService: installationService,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sourceVendorId: vendorProduct.vendorId,
      );

      await docRef.set(catalogProduct.toFirestore());
      return catalogProduct;
    } catch (e) {
      throw ApiException(
        message: 'Failed to create catalog product: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Stream<List<CatalogProduct>> watchAllProducts() {
    return _productsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CatalogProduct.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<CatalogProduct>> watchPublicProducts() {
    return _productsRef
        .where('available', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CatalogProduct.fromFirestore(doc))
          .toList();
    });
  }
}
