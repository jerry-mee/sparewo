// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VendorOrder _$VendorOrderFromJson(Map<String, dynamic> json) {
  return _VendorOrder.fromJson(json);
}

/// @nodoc
mixin _$VendorOrder {
  String get id => throw _privateConstructorUsedError;
  String get vendorId => throw _privateConstructorUsedError;
  String get customerId => throw _privateConstructorUsedError;
  String get customerName => throw _privateConstructorUsedError;
  String get customerEmail => throw _privateConstructorUsedError;
  String? get customerPhone => throw _privateConstructorUsedError;
  String get productId => throw _privateConstructorUsedError;
  String get productName => throw _privateConstructorUsedError;
  String? get productImage => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  double get totalAmount => throw _privateConstructorUsedError;
  OrderStatus get status => throw _privateConstructorUsedError;
  String? get deliveryAddress => throw _privateConstructorUsedError;
  double? get deliveryFee => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  bool get isPaid => throw _privateConstructorUsedError;
  String? get paymentMethod => throw _privateConstructorUsedError;
  String? get paymentId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get expectedDeliveryDate => throw _privateConstructorUsedError;
  DateTime? get acceptedAt => throw _privateConstructorUsedError;
  DateTime? get processedAt => throw _privateConstructorUsedError;
  DateTime? get readyAt => throw _privateConstructorUsedError;
  DateTime? get deliveredAt => throw _privateConstructorUsedError;
  DateTime? get cancelledAt => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this VendorOrder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VendorOrder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VendorOrderCopyWith<VendorOrder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VendorOrderCopyWith<$Res> {
  factory $VendorOrderCopyWith(
          VendorOrder value, $Res Function(VendorOrder) then) =
      _$VendorOrderCopyWithImpl<$Res, VendorOrder>;
  @useResult
  $Res call(
      {String id,
      String vendorId,
      String customerId,
      String customerName,
      String customerEmail,
      String? customerPhone,
      String productId,
      String productName,
      String? productImage,
      double price,
      int quantity,
      double totalAmount,
      OrderStatus status,
      String? deliveryAddress,
      double? deliveryFee,
      String? notes,
      bool isPaid,
      String? paymentMethod,
      String? paymentId,
      DateTime createdAt,
      DateTime? expectedDeliveryDate,
      DateTime? acceptedAt,
      DateTime? processedAt,
      DateTime? readyAt,
      DateTime? deliveredAt,
      DateTime? cancelledAt,
      DateTime? completedAt,
      DateTime updatedAt});
}

/// @nodoc
class _$VendorOrderCopyWithImpl<$Res, $Val extends VendorOrder>
    implements $VendorOrderCopyWith<$Res> {
  _$VendorOrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VendorOrder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vendorId = null,
    Object? customerId = null,
    Object? customerName = null,
    Object? customerEmail = null,
    Object? customerPhone = freezed,
    Object? productId = null,
    Object? productName = null,
    Object? productImage = freezed,
    Object? price = null,
    Object? quantity = null,
    Object? totalAmount = null,
    Object? status = null,
    Object? deliveryAddress = freezed,
    Object? deliveryFee = freezed,
    Object? notes = freezed,
    Object? isPaid = null,
    Object? paymentMethod = freezed,
    Object? paymentId = freezed,
    Object? createdAt = null,
    Object? expectedDeliveryDate = freezed,
    Object? acceptedAt = freezed,
    Object? processedAt = freezed,
    Object? readyAt = freezed,
    Object? deliveredAt = freezed,
    Object? cancelledAt = freezed,
    Object? completedAt = freezed,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      vendorId: null == vendorId
          ? _value.vendorId
          : vendorId // ignore: cast_nullable_to_non_nullable
              as String,
      customerId: null == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String,
      customerName: null == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String,
      customerEmail: null == customerEmail
          ? _value.customerEmail
          : customerEmail // ignore: cast_nullable_to_non_nullable
              as String,
      customerPhone: freezed == customerPhone
          ? _value.customerPhone
          : customerPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      productName: null == productName
          ? _value.productName
          : productName // ignore: cast_nullable_to_non_nullable
              as String,
      productImage: freezed == productImage
          ? _value.productImage
          : productImage // ignore: cast_nullable_to_non_nullable
              as String?,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as OrderStatus,
      deliveryAddress: freezed == deliveryAddress
          ? _value.deliveryAddress
          : deliveryAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      deliveryFee: freezed == deliveryFee
          ? _value.deliveryFee
          : deliveryFee // ignore: cast_nullable_to_non_nullable
              as double?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      isPaid: null == isPaid
          ? _value.isPaid
          : isPaid // ignore: cast_nullable_to_non_nullable
              as bool,
      paymentMethod: freezed == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentId: freezed == paymentId
          ? _value.paymentId
          : paymentId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expectedDeliveryDate: freezed == expectedDeliveryDate
          ? _value.expectedDeliveryDate
          : expectedDeliveryDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      acceptedAt: freezed == acceptedAt
          ? _value.acceptedAt
          : acceptedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      processedAt: freezed == processedAt
          ? _value.processedAt
          : processedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      readyAt: freezed == readyAt
          ? _value.readyAt
          : readyAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deliveredAt: freezed == deliveredAt
          ? _value.deliveredAt
          : deliveredAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelledAt: freezed == cancelledAt
          ? _value.cancelledAt
          : cancelledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VendorOrderImplCopyWith<$Res>
    implements $VendorOrderCopyWith<$Res> {
  factory _$$VendorOrderImplCopyWith(
          _$VendorOrderImpl value, $Res Function(_$VendorOrderImpl) then) =
      __$$VendorOrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String vendorId,
      String customerId,
      String customerName,
      String customerEmail,
      String? customerPhone,
      String productId,
      String productName,
      String? productImage,
      double price,
      int quantity,
      double totalAmount,
      OrderStatus status,
      String? deliveryAddress,
      double? deliveryFee,
      String? notes,
      bool isPaid,
      String? paymentMethod,
      String? paymentId,
      DateTime createdAt,
      DateTime? expectedDeliveryDate,
      DateTime? acceptedAt,
      DateTime? processedAt,
      DateTime? readyAt,
      DateTime? deliveredAt,
      DateTime? cancelledAt,
      DateTime? completedAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$VendorOrderImplCopyWithImpl<$Res>
    extends _$VendorOrderCopyWithImpl<$Res, _$VendorOrderImpl>
    implements _$$VendorOrderImplCopyWith<$Res> {
  __$$VendorOrderImplCopyWithImpl(
      _$VendorOrderImpl _value, $Res Function(_$VendorOrderImpl) _then)
      : super(_value, _then);

  /// Create a copy of VendorOrder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vendorId = null,
    Object? customerId = null,
    Object? customerName = null,
    Object? customerEmail = null,
    Object? customerPhone = freezed,
    Object? productId = null,
    Object? productName = null,
    Object? productImage = freezed,
    Object? price = null,
    Object? quantity = null,
    Object? totalAmount = null,
    Object? status = null,
    Object? deliveryAddress = freezed,
    Object? deliveryFee = freezed,
    Object? notes = freezed,
    Object? isPaid = null,
    Object? paymentMethod = freezed,
    Object? paymentId = freezed,
    Object? createdAt = null,
    Object? expectedDeliveryDate = freezed,
    Object? acceptedAt = freezed,
    Object? processedAt = freezed,
    Object? readyAt = freezed,
    Object? deliveredAt = freezed,
    Object? cancelledAt = freezed,
    Object? completedAt = freezed,
    Object? updatedAt = null,
  }) {
    return _then(_$VendorOrderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      vendorId: null == vendorId
          ? _value.vendorId
          : vendorId // ignore: cast_nullable_to_non_nullable
              as String,
      customerId: null == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String,
      customerName: null == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String,
      customerEmail: null == customerEmail
          ? _value.customerEmail
          : customerEmail // ignore: cast_nullable_to_non_nullable
              as String,
      customerPhone: freezed == customerPhone
          ? _value.customerPhone
          : customerPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      productName: null == productName
          ? _value.productName
          : productName // ignore: cast_nullable_to_non_nullable
              as String,
      productImage: freezed == productImage
          ? _value.productImage
          : productImage // ignore: cast_nullable_to_non_nullable
              as String?,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as OrderStatus,
      deliveryAddress: freezed == deliveryAddress
          ? _value.deliveryAddress
          : deliveryAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      deliveryFee: freezed == deliveryFee
          ? _value.deliveryFee
          : deliveryFee // ignore: cast_nullable_to_non_nullable
              as double?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      isPaid: null == isPaid
          ? _value.isPaid
          : isPaid // ignore: cast_nullable_to_non_nullable
              as bool,
      paymentMethod: freezed == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentId: freezed == paymentId
          ? _value.paymentId
          : paymentId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expectedDeliveryDate: freezed == expectedDeliveryDate
          ? _value.expectedDeliveryDate
          : expectedDeliveryDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      acceptedAt: freezed == acceptedAt
          ? _value.acceptedAt
          : acceptedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      processedAt: freezed == processedAt
          ? _value.processedAt
          : processedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      readyAt: freezed == readyAt
          ? _value.readyAt
          : readyAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deliveredAt: freezed == deliveredAt
          ? _value.deliveredAt
          : deliveredAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cancelledAt: freezed == cancelledAt
          ? _value.cancelledAt
          : cancelledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VendorOrderImpl extends _VendorOrder {
  const _$VendorOrderImpl(
      {required this.id,
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
      required this.updatedAt})
      : super._();

  factory _$VendorOrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$VendorOrderImplFromJson(json);

  @override
  final String id;
  @override
  final String vendorId;
  @override
  final String customerId;
  @override
  final String customerName;
  @override
  final String customerEmail;
  @override
  final String? customerPhone;
  @override
  final String productId;
  @override
  final String productName;
  @override
  final String? productImage;
  @override
  final double price;
  @override
  final int quantity;
  @override
  final double totalAmount;
  @override
  final OrderStatus status;
  @override
  final String? deliveryAddress;
  @override
  final double? deliveryFee;
  @override
  final String? notes;
  @override
  final bool isPaid;
  @override
  final String? paymentMethod;
  @override
  final String? paymentId;
  @override
  final DateTime createdAt;
  @override
  final DateTime? expectedDeliveryDate;
  @override
  final DateTime? acceptedAt;
  @override
  final DateTime? processedAt;
  @override
  final DateTime? readyAt;
  @override
  final DateTime? deliveredAt;
  @override
  final DateTime? cancelledAt;
  @override
  final DateTime? completedAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'VendorOrder(id: $id, vendorId: $vendorId, customerId: $customerId, customerName: $customerName, customerEmail: $customerEmail, customerPhone: $customerPhone, productId: $productId, productName: $productName, productImage: $productImage, price: $price, quantity: $quantity, totalAmount: $totalAmount, status: $status, deliveryAddress: $deliveryAddress, deliveryFee: $deliveryFee, notes: $notes, isPaid: $isPaid, paymentMethod: $paymentMethod, paymentId: $paymentId, createdAt: $createdAt, expectedDeliveryDate: $expectedDeliveryDate, acceptedAt: $acceptedAt, processedAt: $processedAt, readyAt: $readyAt, deliveredAt: $deliveredAt, cancelledAt: $cancelledAt, completedAt: $completedAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VendorOrderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.vendorId, vendorId) ||
                other.vendorId == vendorId) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.customerEmail, customerEmail) ||
                other.customerEmail == customerEmail) &&
            (identical(other.customerPhone, customerPhone) ||
                other.customerPhone == customerPhone) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.productName, productName) ||
                other.productName == productName) &&
            (identical(other.productImage, productImage) ||
                other.productImage == productImage) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.deliveryAddress, deliveryAddress) ||
                other.deliveryAddress == deliveryAddress) &&
            (identical(other.deliveryFee, deliveryFee) ||
                other.deliveryFee == deliveryFee) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.isPaid, isPaid) || other.isPaid == isPaid) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.paymentId, paymentId) ||
                other.paymentId == paymentId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.expectedDeliveryDate, expectedDeliveryDate) ||
                other.expectedDeliveryDate == expectedDeliveryDate) &&
            (identical(other.acceptedAt, acceptedAt) ||
                other.acceptedAt == acceptedAt) &&
            (identical(other.processedAt, processedAt) ||
                other.processedAt == processedAt) &&
            (identical(other.readyAt, readyAt) || other.readyAt == readyAt) &&
            (identical(other.deliveredAt, deliveredAt) ||
                other.deliveredAt == deliveredAt) &&
            (identical(other.cancelledAt, cancelledAt) ||
                other.cancelledAt == cancelledAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        vendorId,
        customerId,
        customerName,
        customerEmail,
        customerPhone,
        productId,
        productName,
        productImage,
        price,
        quantity,
        totalAmount,
        status,
        deliveryAddress,
        deliveryFee,
        notes,
        isPaid,
        paymentMethod,
        paymentId,
        createdAt,
        expectedDeliveryDate,
        acceptedAt,
        processedAt,
        readyAt,
        deliveredAt,
        cancelledAt,
        completedAt,
        updatedAt
      ]);

  /// Create a copy of VendorOrder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VendorOrderImplCopyWith<_$VendorOrderImpl> get copyWith =>
      __$$VendorOrderImplCopyWithImpl<_$VendorOrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VendorOrderImplToJson(
      this,
    );
  }
}

abstract class _VendorOrder extends VendorOrder {
  const factory _VendorOrder(
      {required final String id,
      required final String vendorId,
      required final String customerId,
      required final String customerName,
      required final String customerEmail,
      final String? customerPhone,
      required final String productId,
      required final String productName,
      final String? productImage,
      required final double price,
      required final int quantity,
      required final double totalAmount,
      required final OrderStatus status,
      final String? deliveryAddress,
      final double? deliveryFee,
      final String? notes,
      required final bool isPaid,
      final String? paymentMethod,
      final String? paymentId,
      required final DateTime createdAt,
      final DateTime? expectedDeliveryDate,
      final DateTime? acceptedAt,
      final DateTime? processedAt,
      final DateTime? readyAt,
      final DateTime? deliveredAt,
      final DateTime? cancelledAt,
      final DateTime? completedAt,
      required final DateTime updatedAt}) = _$VendorOrderImpl;
  const _VendorOrder._() : super._();

  factory _VendorOrder.fromJson(Map<String, dynamic> json) =
      _$VendorOrderImpl.fromJson;

  @override
  String get id;
  @override
  String get vendorId;
  @override
  String get customerId;
  @override
  String get customerName;
  @override
  String get customerEmail;
  @override
  String? get customerPhone;
  @override
  String get productId;
  @override
  String get productName;
  @override
  String? get productImage;
  @override
  double get price;
  @override
  int get quantity;
  @override
  double get totalAmount;
  @override
  OrderStatus get status;
  @override
  String? get deliveryAddress;
  @override
  double? get deliveryFee;
  @override
  String? get notes;
  @override
  bool get isPaid;
  @override
  String? get paymentMethod;
  @override
  String? get paymentId;
  @override
  DateTime get createdAt;
  @override
  DateTime? get expectedDeliveryDate;
  @override
  DateTime? get acceptedAt;
  @override
  DateTime? get processedAt;
  @override
  DateTime? get readyAt;
  @override
  DateTime? get deliveredAt;
  @override
  DateTime? get cancelledAt;
  @override
  DateTime? get completedAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of VendorOrder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VendorOrderImplCopyWith<_$VendorOrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
