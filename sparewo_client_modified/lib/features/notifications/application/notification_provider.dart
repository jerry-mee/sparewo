import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
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
      final link = ref.keepAlive();
      Timer? timer;
      ref.onCancel(() {
        timer = Timer(const Duration(minutes: 5), link.close);
      });
      ref.onResume(() => timer?.cancel());
      ref.onDispose(() => timer?.cancel());

      final uid = ref.watch(currentUidProvider);
      if (uid == null || uid.isEmpty) return Stream.value(const []);

      AppLogger.debug(
        'NotificationsProvider',
        'Subscribing to notifications stream',
        extra: {'uid': uid},
      );
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

  Iterable<List<String>> _chunkIds(List<String> ids) sync* {
    for (var i = 0; i < ids.length; i += 500) {
      final end = (i + 500 < ids.length) ? i + 500 : ids.length;
      yield ids.sublist(i, end);
    }
  }

  Future<void> markRead(List<String> ids) async {
    if (ids.isEmpty) return;
    AppLogger.info(
      'NotificationActions',
      'Marking notifications as read',
      extra: {'count': ids.length},
    );
    for (final chunk in _chunkIds(ids)) {
      final batch = _firestore.batch();
      for (final id in chunk) {
        final ref = _firestore.collection('notifications').doc(id);
        batch.set(ref, {'read': true}, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  Future<void> delete(List<String> ids) async {
    if (ids.isEmpty) return;
    AppLogger.info(
      'NotificationActions',
      'Deleting notifications',
      extra: {'count': ids.length},
    );
    for (final chunk in _chunkIds(ids)) {
      final batch = _firestore.batch();
      for (final id in chunk) {
        batch.delete(_firestore.collection('notifications').doc(id));
      }
      await batch.commit();
    }
  }

  Future<void> markAllRead(String userId) async {
    AppLogger.debug(
      'NotificationActions',
      'Marking all notifications as read',
      extra: {'uid': userId},
    );
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
    AppLogger.debug(
      'NotificationActions',
      'Deleting all notifications',
      extra: {'uid': userId},
    );
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
