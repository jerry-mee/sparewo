// lib/models/order.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/enums.dart';

class VendorOrder {
  final String id;
  final String vendorId;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final double totalAmount;
  final OrderStatus status;
  final String? deliveryAddress;
  final double? deliveryFee;
  final String? notes;
  final bool isPaid;
  final String? paymentMethod;
  final String? paymentId;
  final DateTime createdAt;
  final DateTime? expectedDeliveryDate;
  final DateTime? acceptedAt;
  final DateTime? processedAt;
  final DateTime? readyAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  const VendorOrder({
    required this.id,
    required this.vendorId,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    required this.totalAmount,
    required this.status,
    this.deliveryAddress,
    this.deliveryFee,
    this.notes,
    required this.isPaid,
    this.paymentMethod,
    this.paymentId,
    required this.createdAt,
    this.expectedDeliveryDate,
    this.acceptedAt,
    this.processedAt,
    this.readyAt,
    this.deliveredAt,
    this.cancelledAt,
    this.completedAt,
    required this.updatedAt,
  });

  VendorOrder copyWith({
    String? id,
    String? vendorId,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? productId,
    String? productName,
    String? productImage,
    double? price,
    int? quantity,
    double? totalAmount,
    OrderStatus? status,
    String? deliveryAddress,
    double? deliveryFee,
    String? notes,
    bool? isPaid,
    String? paymentMethod,
    String? paymentId,
    DateTime? createdAt,
    DateTime? expectedDeliveryDate,
    DateTime? acceptedAt,
    DateTime? processedAt,
    DateTime? readyAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return VendorOrder(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      createdAt: createdAt ?? this.createdAt,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      processedAt: processedAt ?? this.processedAt,
      readyAt: readyAt ?? this.readyAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'totalAmount': totalAmount,
      'status': status.name,
      'deliveryAddress': deliveryAddress,
      'deliveryFee': deliveryFee,
      'notes': notes,
      'isPaid': isPaid,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'createdAt': createdAt.toIso8601String(),
      'expectedDeliveryDate': expectedDeliveryDate?.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'readyAt': readyAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory VendorOrder.fromJson(Map<String, dynamic> json) {
    return VendorOrder(
      id: json['id'],
      vendorId: json['vendorId'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      customerEmail: json['customerEmail'],
      customerPhone: json['customerPhone'],
      productId: json['productId'],
      productName: json['productName'],
      productImage: json['productImage'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: OrderStatus.values.byName(json['status']),
      deliveryAddress: json['deliveryAddress'],
      deliveryFee: json['deliveryFee'] != null
          ? (json['deliveryFee'] as num).toDouble()
          : null,
      notes: json['notes'],
      isPaid: json['isPaid'],
      paymentMethod: json['paymentMethod'],
      paymentId: json['paymentId'],
      createdAt: DateTime.parse(json['createdAt']),
      expectedDeliveryDate: json['expectedDeliveryDate'] != null
          ? DateTime.parse(json['expectedDeliveryDate'])
          : null,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'])
          : null,
      readyAt: json['readyAt'] != null ? DateTime.parse(json['readyAt']) : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

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
