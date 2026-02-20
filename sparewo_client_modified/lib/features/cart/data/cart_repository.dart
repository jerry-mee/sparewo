// lib/features/cart/data/cart_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparewo_client/features/cart/domain/cart_item_model.dart';
import 'package:sparewo_client/features/cart/domain/cart_model.dart';

class CartRepository {
  final FirebaseFirestore _firestore;
  final String? userId;

  CartRepository({this.userId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _canonicalUserDoc() {
    if (userId == null) throw StateError('No userId for cart operations');
    return _firestore.collection('users').doc(userId);
  }

  Future<DocumentReference<Map<String, dynamic>>>
  _existingUserDocForRead() async {
    final usersDoc = _firestore.collection('users').doc(userId);
    final clientsDoc = _firestore.collection('clients').doc(userId);
    final usersSnap = await usersDoc.get();
    if (usersSnap.exists) return usersDoc;

    // Subcollections may exist even when the parent user document is missing.
    // Prefer the canonical users/{uid}/cart if it already has cart data.
    final usersCartSnap = await usersDoc.collection('cart').limit(1).get();
    if (usersCartSnap.docs.isNotEmpty) return usersDoc;

    final clientsSnap = await clientsDoc.get();
    if (clientsSnap.exists) return clientsDoc;

    final clientsCartSnap = await clientsDoc.collection('cart').limit(1).get();
    if (clientsCartSnap.docs.isNotEmpty) return clientsDoc;

    return usersDoc;
  }

  Stream<CartModel> getUserCart() async* {
    if (userId == null) {
      yield const CartModel(items: []);
      return;
    }

    final doc = await _existingUserDocForRead();
    yield* doc.collection('cart').snapshots().map((qs) {
      final items = qs.docs.map((d) {
        final data = d.data();
        return CartItemModel(
          productId: d.id,
          quantity: (data['quantity'] as int?) ?? 0,
          addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      return CartModel(items: items);
    });
  }

  Future<int> countUserCartItems() async {
    if (userId == null) return 0;
    final doc = await _existingUserDocForRead();
    final qs = await doc.collection('cart').get();
    var total = 0;
    for (final d in qs.docs) {
      total += (d.data()['quantity'] as int?) ?? 0;
    }
    return total;
  }

  Future<void> addItem({
    required String productId,
    required int quantity,
  }) async {
    final doc = _canonicalUserDoc().collection('cart').doc(productId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final prev = (snap.data()?['quantity'] as int?) ?? 0;
      tx.set(doc, {
        'quantity': prev + quantity,
        'addedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> updateQuantity({
    required String productId,
    required int quantity,
  }) async {
    final doc = _canonicalUserDoc().collection('cart').doc(productId);
    if (quantity <= 0) {
      await doc.delete();
    } else {
      await doc.set({'quantity': quantity}, SetOptions(merge: true));
    }
  }

  Future<void> removeItem(String productId) async {
    await _canonicalUserDoc().collection('cart').doc(productId).delete();
  }

  Future<void> clearCart() async {
    final col = _canonicalUserDoc().collection('cart');
    final batch = _firestore.batch();
    final qs = await col.get();
    for (final d in qs.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}
