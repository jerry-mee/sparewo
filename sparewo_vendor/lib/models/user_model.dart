import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImg;
  final bool status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? firebaseUid; // Added for Firebase integration

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImg,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.firebaseUid,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      profileImg: json['profileImg'],
      status: json['status'] == 1,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      firebaseUid: json['firebase_uid'],
    );
  }

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: data['id'],
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      profileImg: data['profileImg'],
      status: data['status'] == 1,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      firebaseUid: doc.id,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImg': profileImg,
      'status': status ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'firebase_uid': firebaseUid,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImg': profileImg,
      'status': status ? 1 : 0,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'type': 'client', // To distinguish from vendors
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? profileImg,
    bool? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firebaseUid,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImg: profileImg ?? this.profileImg,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      firebaseUid: firebaseUid ?? this.firebaseUid,
    );
  }

  // Helper method to generate next ID during migration
  static Future<int> getNextId(FirebaseFirestore firestore) async {
    final counterDoc =
        await firestore.collection('counters').doc('users').get();

    if (!counterDoc.exists) {
      await firestore.collection('counters').doc('users').set({'current': 1});
      return 1;
    }

    final currentId = counterDoc.data()?['current'] as int;
    await firestore.collection('counters').doc('users').update(
      {'current': FieldValue.increment(1)},
    );

    return currentId + 1;
  }

  // Helper method for data migration
  static Future<User> migrateFromLegacy({
    required Map<String, dynamic> legacyData,
    required FirebaseFirestore firestore,
    required String existingFirebaseUid,
    required String newFirebaseUid,
  }) async {
    final nextId = await getNextId(firestore);

    return User(
      id: nextId,
      name: legacyData['name'] ?? '',
      email: legacyData['email'] ?? '',
      phone: legacyData['phone'],
      profileImg: legacyData['profileImg'],
      status: legacyData['status'] == 1,
      createdAt: DateTime.parse(legacyData['createdAt']),
      updatedAt: DateTime.now(), // Reset update time during migration
      firebaseUid: legacyData['firebase_uid'],
    );
  }

  static generateId() {}
}
