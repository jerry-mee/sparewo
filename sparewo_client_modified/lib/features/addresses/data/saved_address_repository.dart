import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparewo_client/features/addresses/domain/saved_address.dart';

class SavedAddressRepository {
  SavedAddressRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _addresses(String userId) {
    return _firestore.collection('users').doc(userId).collection('addresses');
  }

  Stream<List<SavedAddress>> watchUserAddresses(String userId) {
    return _addresses(
      userId,
    ).orderBy('createdAt', descending: true).snapshots().map((snap) {
      final rows = snap.docs
          .map((doc) => SavedAddress.fromMap(doc.id, doc.data()))
          .toList();
      rows.sort((a, b) {
        if (a.isDefault == b.isDefault) return 0;
        return a.isDefault ? -1 : 1;
      });
      return rows;
    });
  }

  Future<void> saveAddress({
    required String userId,
    required SavedAddress address,
    bool makeDefault = false,
  }) async {
    final addresses = _addresses(userId);
    final batch = _firestore.batch();
    final shouldMakeDefault = makeDefault || address.isDefault;

    if (shouldMakeDefault) {
      final current = await addresses.get();
      for (final doc in current.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }

    final payload = {
      'label': address.label.trim(),
      'line1': address.line1.trim(),
      'line2': address.line2?.trim(),
      'city': address.city?.trim(),
      'landmark': address.landmark?.trim(),
      'phone': address.phone?.trim(),
      'recipientName': address.recipientName?.trim(),
      'isDefault': shouldMakeDefault,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (address.id.isEmpty) {
      batch.set(addresses.doc(), {
        ...payload,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      batch.set(addresses.doc(address.id), {
        ...payload,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> setDefaultAddress({
    required String userId,
    required String addressId,
  }) async {
    final addresses = _addresses(userId);
    final current = await addresses.get();
    final batch = _firestore.batch();
    for (final doc in current.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == addressId});
    }
    await batch.commit();
  }

  Future<void> deleteAddress({
    required String userId,
    required String addressId,
  }) {
    return _addresses(userId).doc(addressId).delete();
  }
}
