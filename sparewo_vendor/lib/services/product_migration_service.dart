import 'package:cloud_firestore/cloud_firestore.dart';
import 'vendor_product_service.dart';
import 'catalog_product_service.dart';
import '../exceptions/api_exceptions.dart';
import '../models/vendor_product.dart';
import '../models/catalog_product.dart';

class ProductMigrationService {
  final FirebaseFirestore firestore;
  final VendorProductService vendorProductService;
  final CatalogProductService catalogProductService;

  ProductMigrationService({
    required this.firestore,
    required this.vendorProductService,
    required this.catalogProductService,
  });

  /// Migrates all documents from the old "products" collection
  /// into both vendor_products and catalog_products.
  Future<void> migrateProducts() async {
    try {
      final snapshot = await firestore.collection('products').get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Assume that the old product data is compatible with VendorProduct.
        final vendorProduct = VendorProduct.fromJson({
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp).toDate(),
          'updatedAt': (data['updatedAt'] as Timestamp).toDate(),
        });
        // Create vendor product
        await vendorProductService.createProduct(vendorProduct);
        // Optionally, create a catalog product version.
        // Uncomment and adjust the parameters if needed:
        /*
        await catalogProductService.createFromVendorProduct(
          vendorProduct,
          retailPrice: vendorProduct.unitPrice,
          installationService: false,
          estimatedDelivery: '5-7 business days',
          warrantyInfo: null,
        );
        */
      }
    } catch (e) {
      throw ApiException(
          message: 'Product migration failed: ${e.toString()}',
          statusCode: 500);
    }
  }
}
