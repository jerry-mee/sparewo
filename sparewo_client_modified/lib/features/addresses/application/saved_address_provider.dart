import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_client/features/addresses/data/saved_address_repository.dart';
import 'package:sparewo_client/features/addresses/domain/saved_address.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';

final savedAddressRepositoryProvider = Provider<SavedAddressRepository>((ref) {
  return SavedAddressRepository(FirebaseFirestore.instance);
});

final savedAddressesStreamProvider = StreamProvider<List<SavedAddress>>((ref) {
  final user = ref.watch(currentUserProvider).asData?.value;
  if (user == null) {
    return Stream.value(const <SavedAddress>[]);
  }
  return ref.watch(savedAddressRepositoryProvider).watchUserAddresses(user.id);
});

final defaultSavedAddressProvider = Provider<SavedAddress?>((ref) {
  final addresses = ref.watch(savedAddressesStreamProvider).asData?.value;
  if (addresses == null || addresses.isEmpty) return null;
  return addresses.firstWhere(
    (item) => item.isDefault,
    orElse: () => addresses.first,
  );
});
