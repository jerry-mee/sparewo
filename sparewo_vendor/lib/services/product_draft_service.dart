// lib/services/product_draft_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_draft.dart';
import '../models/vendor_product.dart';
import '../models/vehicle_compatibility.dart';
import '../exceptions/api_exceptions.dart';
import '../constants/enums.dart';
import 'logger_service.dart';

class ProductDraftService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LoggerService _logger = LoggerService.instance;

  ProductDraftService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Save or update draft
  Future<String> saveDraft(ProductDraft draft) async {
    try {
      final vendorId = _auth.currentUser?.uid;
      if (vendorId == null) {
        throw const ApiException(
          message: 'User not authenticated',
          statusCode: 401,
        );
      }

      final draftData = draft.toJson();
      draftData['vendorId'] = vendorId;
      draftData['lastModified'] = FieldValue.serverTimestamp();

      if (draft.id.isEmpty) {
        // Create new draft
        draftData['createdAt'] = FieldValue.serverTimestamp();
        final docRef =
            await _firestore.collection('product_drafts').add(draftData);
        _logger.info('Draft created: ${docRef.id}');
        return docRef.id;
      } else {
        // Update existing draft
        await _firestore
            .collection('product_drafts')
            .doc(draft.id)
            .update(draftData);
        _logger.info('Draft updated: ${draft.id}');
        return draft.id;
      }
    } catch (e) {
      _logger.error('Error saving draft', error: e);
      throw ApiException(
        message: 'Failed to save draft: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Get vendor's drafts
  Future<List<ProductDraft>> getVendorDrafts() async {
    try {
      final vendorId = _auth.currentUser?.uid;
      if (vendorId == null) {
        throw const ApiException(
          message: 'User not authenticated',
          statusCode: 401,
        );
      }

      final querySnapshot = await _firestore
          .collection('product_drafts')
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('lastModified', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductDraft.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.error('Error getting drafts', error: e);
      throw ApiException(
        message: 'Failed to get drafts: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Get single draft
  Future<ProductDraft?> getDraft(String draftId) async {
    try {
      final vendorId = _auth.currentUser?.uid;
      if (vendorId == null) {
        throw const ApiException(
          message: 'User not authenticated',
          statusCode: 401,
        );
      }

      final doc =
          await _firestore.collection('product_drafts').doc(draftId).get();

      if (!doc.exists) {
        return null;
      }

      final draft = ProductDraft.fromFirestore(doc);

      // Verify ownership
      if (draft.vendorId != vendorId) {
        throw const ApiException(
          message: 'Unauthorized access to draft',
          statusCode: 403,
        );
      }

      return draft;
    } catch (e) {
      _logger.error('Error getting draft', error: e);
      throw ApiException(
        message: 'Failed to get draft: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Convert draft to product
  Future<VendorProduct> convertDraftToProduct(String draftId) async {
    try {
      final draft = await getDraft(draftId);
      if (draft == null) {
        throw const ApiException(
          message: 'Draft not found',
          statusCode: 404,
        );
      }

      final product = VendorProduct(
        id: '',
        vendorId: draft.vendorId,
        partName: draft.partName,
        brand: draft.brand,
        description: draft.description,
        partNumber: draft.partNumber,
        unitPrice: draft.unitPrice,
        stockQuantity: draft.stockQuantity,
        condition: draft.condition,
        category: draft.category,
        qualityGrade: draft.qualityGrade,
        images: draft.images,
        compatibility: draft.compatibility,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ProductStatus.pending,
      );

      // Delete draft after conversion
      await deleteDraft(draftId);

      return product;
    } catch (e) {
      _logger.error('Error converting draft', error: e);
      throw ApiException(
        message: 'Failed to convert draft: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Delete draft
  Future<void> deleteDraft(String draftId) async {
    try {
      final vendorId = _auth.currentUser?.uid;
      if (vendorId == null) {
        throw const ApiException(
          message: 'User not authenticated',
          statusCode: 401,
        );
      }

      // Verify ownership before deletion
      final draft = await getDraft(draftId);
      if (draft == null) {
        return;
      }

      await _firestore.collection('product_drafts').doc(draftId).delete();

      _logger.info('Draft deleted: $draftId');
    } catch (e) {
      _logger.error('Error deleting draft', error: e);
      throw ApiException(
        message: 'Failed to delete draft: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Auto-save draft (called periodically)
  Future<void> autoSaveDraft({
    String? draftId,
    required String partName,
    required String description,
    required double unitPrice,
    required int stockQuantity,
    required List<String> images,
    required List<VehicleCompatibility> compatibility,
    required PartCondition condition,
    required ProductCategory category,
    required String qualityGrade,
    required String brand,
    String? partNumber,
  }) async {
    try {
      final vendorId = _auth.currentUser?.uid;
      if (vendorId == null) return;

      final draft = ProductDraft(
        id: draftId ?? '',
        vendorId: vendorId,
        partName: partName,
        description: description,
        unitPrice: unitPrice,
        stockQuantity: stockQuantity,
        images: images,
        compatibility: compatibility,
        condition: condition,
        category: category,
        qualityGrade: qualityGrade,
        brand: brand,
        partNumber: partNumber,
        isComplete: _isDataComplete(
          partName: partName,
          description: description,
          unitPrice: unitPrice,
          stockQuantity: stockQuantity,
          images: images,
          compatibility: compatibility,
          brand: brand,
        ),
        lastModified: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await saveDraft(draft);
    } catch (e) {
      _logger.error('Auto-save failed', error: e);
      // Don't throw - auto-save failures shouldn't interrupt user flow
    }
  }

  bool _isDataComplete({
    required String partName,
    required String description,
    required double unitPrice,
    required int stockQuantity,
    required List<String> images,
    required List<VehicleCompatibility> compatibility,
    required String brand,
  }) {
    return partName.isNotEmpty &&
        description.isNotEmpty &&
        unitPrice > 0 &&
        stockQuantity > 0 &&
        images.isNotEmpty &&
        compatibility.isNotEmpty &&
        brand.isNotEmpty;
  }
}
