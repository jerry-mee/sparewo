import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/enums.dart';

part 'vendor.freezed.dart';
part 'vendor.g.dart';

@freezed
class Vendor with _$Vendor {
  const factory Vendor({
    required String id,
    required String name,
    required String email,
    required String phone,
    required String businessName,
    required String businessAddress,
    required List<String> categories,
    String? profileImage,
    Map<String, dynamic>? businessHours,
    Map<String, dynamic>? settings,
    @Default(false) bool isVerified,
    required VendorStatus status,
    @Default(0.0) double rating,
    @Default(0) int completedOrders,
    @Default(0) int totalProducts,
    String? fcmToken,
    String? latitude,
    String? longitude,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Vendor;

  const Vendor._();

  factory Vendor.fromJson(Map<String, dynamic> json) => _$VendorFromJson(json);

  factory Vendor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Vendor.fromJson({
      'id': doc.id,
      ...data,
      'status':
          VendorStatus.values.byName(data['status'].toString().toLowerCase()),
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp).toDate().toIso8601String(),
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson()..remove('id');
    return {
      ...json,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isActive => status == VendorStatus.approved && isVerified;
  bool get isPending => status == VendorStatus.pending;
  bool get isSuspended => status == VendorStatus.suspended;
  bool get hasLocation => latitude != null && longitude != null;
}
