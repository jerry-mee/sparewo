// lib/providers/product_draft_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_draft.dart';
import '../services/product_draft_service.dart';
import 'providers.dart';

// Draft service provider
final productDraftServiceProvider = Provider<ProductDraftService>((ref) {
  return ProductDraftService();
});

// List of vendor's drafts
final vendorDraftsProvider = FutureProvider<List<ProductDraft>>((ref) async {
  final service = ref.watch(productDraftServiceProvider);
  return service.getVendorDrafts();
});

// Single draft provider
final draftByIdProvider =
    FutureProvider.family<ProductDraft?, String>((ref, draftId) async {
  final service = ref.watch(productDraftServiceProvider);
  return service.getDraft(draftId);
});

// Draft state notifier for managing current draft being edited
class DraftStateNotifier extends StateNotifier<AsyncValue<ProductDraft?>> {
  final ProductDraftService _service;

  DraftStateNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> loadDraft(String draftId) async {
    state = const AsyncValue.loading();
    try {
      final draft = await _service.getDraft(draftId);
      state = AsyncValue.data(draft);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String> saveDraft(ProductDraft draft) async {
    try {
      final draftId = await _service.saveDraft(draft);
      state = AsyncValue.data(draft.copyWith(id: draftId));
      return draftId;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteDraft(String draftId) async {
    try {
      await _service.deleteDraft(draftId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  void clearDraft() {
    state = const AsyncValue.data(null);
  }
}

// Current draft state provider
final currentDraftProvider =
    StateNotifierProvider<DraftStateNotifier, AsyncValue<ProductDraft?>>((ref) {
  final service = ref.watch(productDraftServiceProvider);
  return DraftStateNotifier(service);
});
