// lib/models/user_roles.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserRoles {
  final String uid;
  final String role;
  final bool isAdmin;
  final bool isVendor;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserRoles({
    required this.uid,
    required this.role,
    this.isAdmin = false,
    this.isVendor = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  UserRoles copyWith({
    String? uid,
    String? role,
    bool? isAdmin,
    bool? isVendor,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserRoles(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      isVendor: isVendor ?? this.isVendor,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'role': role,
      'isAdmin': isAdmin,
      'isVendor': isVendor,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserRoles.fromJson(Map<String, dynamic> json) {
    return UserRoles(
      uid: json['uid'],
      role: json['role'],
      isAdmin: json['isAdmin'] ?? false,
      isVendor: json['isVendor'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  factory UserRoles.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserRoles.fromJson({
      'uid': doc.id,
      'role': data['role'] ?? 'vendor',
      'isAdmin': data['isAdmin'] ?? false,
      'isVendor': data['isVendor'] ?? true,
      'isActive': data['isActive'] ?? true,
      'createdAt': data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
          : DateTime.now().toIso8601String(),
      'updatedAt': data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate().toIso8601String()
          : DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('uid'); // UID is used as the document ID
    return {
      ...json,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
