// lib/models/vendor.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/enums.dart';

class Vendor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String businessName;
  final String businessAddress;
  final List<String> categories;
  final String? profileImage;
  final Map<String, dynamic>? businessHours;
  final Map<String, dynamic>? settings;
  final bool isVerified;
  final VendorStatus status;
  final double rating;
  final int completedOrders;
  final int totalProducts;
  final String? fcmToken;
  final String? latitude;
  final String? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vendor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.businessName,
    required this.businessAddress,
    required this.categories,
    this.profileImage,
    this.businessHours,
    this.settings,
    this.isVerified = false,
    required this.status,
    this.rating = 0.0,
    this.completedOrders = 0,
    this.totalProducts = 0,
    this.fcmToken,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  Vendor copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? businessName,
    String? businessAddress,
    List<String>? categories,
    String? profileImage,
    Map<String, dynamic>? businessHours,
    Map<String, dynamic>? settings,
    bool? isVerified,
    VendorStatus? status,
    double? rating,
    int? completedOrders,
    int? totalProducts,
    String? fcmToken,
    String? latitude,
    String? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      categories: categories ?? this.categories,
      profileImage: profileImage ?? this.profileImage,
      businessHours: businessHours ?? this.businessHours,
      settings: settings ?? this.settings,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      completedOrders: completedOrders ?? this.completedOrders,
      totalProducts: totalProducts ?? this.totalProducts,
      fcmToken: fcmToken ?? this.fcmToken,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'categories': categories,
      'profileImage': profileImage,
      'businessHours': businessHours,
      'settings': settings,
      'isVerified': isVerified,
      'status': status.name,
      'rating': rating,
      'completedOrders': completedOrders,
      'totalProducts': totalProducts,
      'fcmToken': fcmToken,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      businessName: json['businessName'],
      businessAddress: json['businessAddress'],
      categories: List<String>.from(json['categories']),
      profileImage: json['profileImage'],
      businessHours: json['businessHours'],
      settings: json['settings'],
      isVerified: json['isVerified'] ?? false,
      status: VendorStatus.values.byName(json['status']),
      rating: (json['rating'] ?? 0.0).toDouble(),
      completedOrders: json['completedOrders'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      fcmToken: json['fcmToken'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  factory Vendor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    VendorStatus vendorStatus;
    try {
      final statusString =
          (data['status'] as String? ?? 'pending').toLowerCase();
      switch (statusString) {
        case 'approved':
          vendorStatus = VendorStatus.approved;
          break;
        case 'pending':
          vendorStatus = VendorStatus.pending;
          break;
        case 'suspended':
          vendorStatus = VendorStatus.suspended;
          break;
        case 'rejected':
          vendorStatus = VendorStatus.rejected;
          break;
        default:
          vendorStatus = VendorStatus.pending;
      }
    } catch (e) {
      vendorStatus = VendorStatus.pending;
    }

    return Vendor(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      businessName: data['businessName'] ?? '',
      businessAddress: data['businessAddress'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      profileImage: data['profileImage'],
      businessHours: data['businessHours'] as Map<String, dynamic>?,
      settings: data['settings'] as Map<String, dynamic>?,
      isVerified: data['isVerified'] ?? false,
      status: vendorStatus,
      rating: (data['rating'] ?? 0.0).toDouble(),
      completedOrders: data['completedOrders'] ?? 0,
      totalProducts: data['totalProducts'] ?? 0,
      fcmToken: data['fcmToken'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json['status'] = status.name;
    json['createdAt'] = Timestamp.fromDate(createdAt);
    json['updatedAt'] = Timestamp.fromDate(updatedAt);
    json.remove('id');
    return json;
  }
}
