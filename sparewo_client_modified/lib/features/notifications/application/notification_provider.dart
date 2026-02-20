import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';

class UserNotification {
  final String id;
  final String title;
  final String message;
  final bool read;
  final String? type;
  final String? itemId;
  final String? link;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  const UserNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    required this.type,
    required this.itemId,
    required this.link,
    required this.createdAt,
    required this.raw,
  });

  factory UserNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return UserNotification(
      id: doc.id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? data['title'] as String
          : 'SpareWo Update',
      message: (data['message'] as String?)?.trim().isNotEmpty == true
          ? data['message'] as String
          : 'You have a new notification.',
      read: data['read'] == true,
      type: data['type']?.toString(),
      itemId: data['id']?.toString(),
      link: data['link']?.toString(),
      createdAt: _asDateTime(data['createdAt']),
      raw: data,
    );
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

final userNotificationsProvider =
    StreamProvider.autoDispose<List<UserNotification>>((ref) {
      final authUser = ref.watch(authStateChangesProvider).asData?.value;
      final uid = authUser?.uid;
      if (uid == null || uid.isEmpty) return Stream.value(const []);

      return FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(UserNotification.fromDoc)
                .toList(growable: false),
          );
    });

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(userNotificationsProvider).asData?.value;
  if (notifications == null) return 0;
  return notifications.where((n) => !n.read).length;
});

class NotificationActions {
  NotificationActions(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> markRead(List<String> ids) async {
    if (ids.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in ids) {
      final ref = _firestore.collection('notifications').doc(id);
      batch.set(ref, {'read': true}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> delete(List<String> ids) async {
    if (ids.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(_firestore.collection('notifications').doc(id));
    }
    await batch.commit();
  }

  Future<void> markAllRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .get();

    final unreadIds = snapshot.docs
        .where((doc) => (doc.data()['read'] == true) == false)
        .map((doc) => doc.id)
        .toList(growable: false);

    await markRead(unreadIds);
  }

  Future<void> deleteAll(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .get();

    await delete(snapshot.docs.map((doc) => doc.id).toList(growable: false));
  }
}

final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(FirebaseFirestore.instance);
});
