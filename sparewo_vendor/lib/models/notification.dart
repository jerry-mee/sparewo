import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/notification_types.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

@freezed
class VendorNotification with _$VendorNotification {
  const factory VendorNotification({
    required String id,
    required String vendorId,
    required String title,
    required String message,
    required NotificationType type,
    required Map<String, dynamic> data,
    @Default(false) bool isRead,
    String? imageUrl,
    required DateTime createdAt,
    DateTime? readAt,
  }) = _VendorNotification;

  const VendorNotification._();

  factory VendorNotification.fromJson(Map<String, dynamic> json) =>
      _$VendorNotificationFromJson(json);

  factory VendorNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VendorNotification.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'readAt': data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate().toIso8601String()
          : null,
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return {
      ...json,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }
}
