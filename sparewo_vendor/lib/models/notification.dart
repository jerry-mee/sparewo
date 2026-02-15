// lib/models/notification.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/enums.dart';

class VendorNotification {
  final String id;
  final String vendorId;
  final String title;
  final String message;
  final NotificationType type;
  final Map<String, dynamic> data;
  final bool isRead;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? readAt;

  const VendorNotification({
    required this.id,
    required this.vendorId,
    required this.title,
    required this.message,
    required this.type,
    required this.data,
    this.isRead = false,
    this.imageUrl,
    required this.createdAt,
    this.readAt,
  });

  VendorNotification copyWith({
    String? id,
    String? vendorId,
    String? title,
    String? message,
    NotificationType? type,
    Map<String, dynamic>? data,
    bool? isRead,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return VendorNotification(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'title': title,
      'message': message,
      'type': type.name,
      'data': data,
      'isRead': isRead,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  factory VendorNotification.fromJson(Map<String, dynamic> json) {
    return VendorNotification(
      id: json['id'],
      vendorId: json['vendorId'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.values.byName(json['type']),
      data: json['data'],
      isRead: json['isRead'] ?? false,
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }

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
