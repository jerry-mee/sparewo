import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/enums.dart';

part 'order.freezed.dart';
part 'order.g.dart';

@freezed
class VendorOrder with _$VendorOrder {
  const factory VendorOrder({
    required String id,
    required String vendorId,
    required String customerId,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    required String productId,
    required String productName,
    String? productImage,
    required double price,
    required int quantity,
    required double totalAmount,
    required OrderStatus status,
    String? deliveryAddress,
    double? deliveryFee,
    String? notes,
    required bool isPaid,
    String? paymentMethod,
    String? paymentId,
    required DateTime createdAt,
    DateTime? expectedDeliveryDate,
    DateTime? acceptedAt,
    DateTime? processedAt,
    DateTime? readyAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    DateTime? completedAt,
    required DateTime updatedAt,
  }) = _VendorOrder;

  const VendorOrder._();

  factory VendorOrder.fromJson(Map<String, dynamic> json) =>
      _$VendorOrderFromJson(json);

  factory VendorOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VendorOrder.fromJson({
      'id': doc.id,
      ...data,
      'status':
          OrderStatus.values.byName(data['status'].toString().toLowerCase()),
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp).toDate().toIso8601String(),
      if (data['acceptedAt'] != null)
        'acceptedAt':
            (data['acceptedAt'] as Timestamp).toDate().toIso8601String(),
      if (data['processedAt'] != null)
        'processedAt':
            (data['processedAt'] as Timestamp).toDate().toIso8601String(),
      if (data['readyAt'] != null)
        'readyAt': (data['readyAt'] as Timestamp).toDate().toIso8601String(),
      if (data['deliveredAt'] != null)
        'deliveredAt':
            (data['deliveredAt'] as Timestamp).toDate().toIso8601String(),
      if (data['cancelledAt'] != null)
        'cancelledAt':
            (data['cancelledAt'] as Timestamp).toDate().toIso8601String(),
      if (data['completedAt'] != null)
        'completedAt':
            (data['completedAt'] as Timestamp).toDate().toIso8601String(),
      if (data['expectedDeliveryDate'] != null)
        'expectedDeliveryDate': (data['expectedDeliveryDate'] as Timestamp)
            .toDate()
            .toIso8601String(),
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');

    final dateFields = {
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (acceptedAt != null) 'acceptedAt': acceptedAt,
      if (processedAt != null) 'processedAt': processedAt,
      if (readyAt != null) 'readyAt': readyAt,
      if (deliveredAt != null) 'deliveredAt': deliveredAt,
      if (cancelledAt != null) 'cancelledAt': cancelledAt,
      if (completedAt != null) 'completedAt': completedAt,
      if (expectedDeliveryDate != null)
        'expectedDeliveryDate': expectedDeliveryDate,
    };

    dateFields.forEach((key, value) {
      json[key] = Timestamp.fromDate(value!);
    });

    return json;
  }

  bool get isActive =>
      status == OrderStatus.accepted ||
      status == OrderStatus.processing ||
      status == OrderStatus.readyForDelivery;

  bool get isPending => status == OrderStatus.pending;

  bool get isCompleted => status == OrderStatus.delivered;

  bool get isCancelled =>
      status == OrderStatus.cancelled || status == OrderStatus.rejected;

  double get subtotal => price * quantity;

  double get total => subtotal + (deliveryFee ?? 0);
}
