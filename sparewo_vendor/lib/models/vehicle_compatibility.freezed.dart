// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle_compatibility.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VehicleCompatibility _$VehicleCompatibilityFromJson(Map<String, dynamic> json) {
  return _VehicleCompatibility.fromJson(json);
}

/// @nodoc
mixin _$VehicleCompatibility {
  String get brand => throw _privateConstructorUsedError;
  String get model => throw _privateConstructorUsedError;
  List<int> get compatibleYears => throw _privateConstructorUsedError;

  /// Serializes this VehicleCompatibility to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VehicleCompatibility
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VehicleCompatibilityCopyWith<VehicleCompatibility> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VehicleCompatibilityCopyWith<$Res> {
  factory $VehicleCompatibilityCopyWith(VehicleCompatibility value,
          $Res Function(VehicleCompatibility) then) =
      _$VehicleCompatibilityCopyWithImpl<$Res, VehicleCompatibility>;
  @useResult
  $Res call({String brand, String model, List<int> compatibleYears});
}

/// @nodoc
class _$VehicleCompatibilityCopyWithImpl<$Res,
        $Val extends VehicleCompatibility>
    implements $VehicleCompatibilityCopyWith<$Res> {
  _$VehicleCompatibilityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VehicleCompatibility
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? brand = null,
    Object? model = null,
    Object? compatibleYears = null,
  }) {
    return _then(_value.copyWith(
      brand: null == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      compatibleYears: null == compatibleYears
          ? _value.compatibleYears
          : compatibleYears // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VehicleCompatibilityImplCopyWith<$Res>
    implements $VehicleCompatibilityCopyWith<$Res> {
  factory _$$VehicleCompatibilityImplCopyWith(_$VehicleCompatibilityImpl value,
          $Res Function(_$VehicleCompatibilityImpl) then) =
      __$$VehicleCompatibilityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String brand, String model, List<int> compatibleYears});
}

/// @nodoc
class __$$VehicleCompatibilityImplCopyWithImpl<$Res>
    extends _$VehicleCompatibilityCopyWithImpl<$Res, _$VehicleCompatibilityImpl>
    implements _$$VehicleCompatibilityImplCopyWith<$Res> {
  __$$VehicleCompatibilityImplCopyWithImpl(_$VehicleCompatibilityImpl _value,
      $Res Function(_$VehicleCompatibilityImpl) _then)
      : super(_value, _then);

  /// Create a copy of VehicleCompatibility
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? brand = null,
    Object? model = null,
    Object? compatibleYears = null,
  }) {
    return _then(_$VehicleCompatibilityImpl(
      brand: null == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      compatibleYears: null == compatibleYears
          ? _value._compatibleYears
          : compatibleYears // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VehicleCompatibilityImpl implements _VehicleCompatibility {
  const _$VehicleCompatibilityImpl(
      {required this.brand,
      required this.model,
      required final List<int> compatibleYears})
      : _compatibleYears = compatibleYears;

  factory _$VehicleCompatibilityImpl.fromJson(Map<String, dynamic> json) =>
      _$$VehicleCompatibilityImplFromJson(json);

  @override
  final String brand;
  @override
  final String model;
  final List<int> _compatibleYears;
  @override
  List<int> get compatibleYears {
    if (_compatibleYears is EqualUnmodifiableListView) return _compatibleYears;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_compatibleYears);
  }

  @override
  String toString() {
    return 'VehicleCompatibility(brand: $brand, model: $model, compatibleYears: $compatibleYears)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VehicleCompatibilityImpl &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.model, model) || other.model == model) &&
            const DeepCollectionEquality()
                .equals(other._compatibleYears, _compatibleYears));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, brand, model,
      const DeepCollectionEquality().hash(_compatibleYears));

  /// Create a copy of VehicleCompatibility
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VehicleCompatibilityImplCopyWith<_$VehicleCompatibilityImpl>
      get copyWith =>
          __$$VehicleCompatibilityImplCopyWithImpl<_$VehicleCompatibilityImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VehicleCompatibilityImplToJson(
      this,
    );
  }
}

abstract class _VehicleCompatibility implements VehicleCompatibility {
  const factory _VehicleCompatibility(
      {required final String brand,
      required final String model,
      required final List<int> compatibleYears}) = _$VehicleCompatibilityImpl;

  factory _VehicleCompatibility.fromJson(Map<String, dynamic> json) =
      _$VehicleCompatibilityImpl.fromJson;

  @override
  String get brand;
  @override
  String get model;
  @override
  List<int> get compatibleYears;

  /// Create a copy of VehicleCompatibility
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VehicleCompatibilityImplCopyWith<_$VehicleCompatibilityImpl>
      get copyWith => throw _privateConstructorUsedError;
}

CarPart _$CarPartFromJson(Map<String, dynamic> json) {
  return _CarPart.fromJson(json);
}

/// @nodoc
mixin _$CarPart {
  String get id => throw _privateConstructorUsedError;
  String get vendorId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  String get condition => throw _privateConstructorUsedError;
  List<String> get images => throw _privateConstructorUsedError;
  List<VehicleCompatibility> get compatibleVehicles =>
      throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  ProductStatus get status => throw _privateConstructorUsedError;
  int get views => throw _privateConstructorUsedError;
  int get orders => throw _privateConstructorUsedError;

  /// Serializes this CarPart to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CarPart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CarPartCopyWith<CarPart> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CarPartCopyWith<$Res> {
  factory $CarPartCopyWith(CarPart value, $Res Function(CarPart) then) =
      _$CarPartCopyWithImpl<$Res, CarPart>;
  @useResult
  $Res call(
      {String id,
      String vendorId,
      String name,
      String description,
      double price,
      int quantity,
      String condition,
      List<String> images,
      List<VehicleCompatibility> compatibleVehicles,
      DateTime createdAt,
      DateTime updatedAt,
      ProductStatus status,
      int views,
      int orders});
}

/// @nodoc
class _$CarPartCopyWithImpl<$Res, $Val extends CarPart>
    implements $CarPartCopyWith<$Res> {
  _$CarPartCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CarPart
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vendorId = null,
    Object? name = null,
    Object? description = null,
    Object? price = null,
    Object? quantity = null,
    Object? condition = null,
    Object? images = null,
    Object? compatibleVehicles = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? status = null,
    Object? views = null,
    Object? orders = null,
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
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      condition: null == condition
          ? _value.condition
          : condition // ignore: cast_nullable_to_non_nullable
              as String,
      images: null == images
          ? _value.images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      compatibleVehicles: null == compatibleVehicles
          ? _value.compatibleVehicles
          : compatibleVehicles // ignore: cast_nullable_to_non_nullable
              as List<VehicleCompatibility>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ProductStatus,
      views: null == views
          ? _value.views
          : views // ignore: cast_nullable_to_non_nullable
              as int,
      orders: null == orders
          ? _value.orders
          : orders // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CarPartImplCopyWith<$Res> implements $CarPartCopyWith<$Res> {
  factory _$$CarPartImplCopyWith(
          _$CarPartImpl value, $Res Function(_$CarPartImpl) then) =
      __$$CarPartImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String vendorId,
      String name,
      String description,
      double price,
      int quantity,
      String condition,
      List<String> images,
      List<VehicleCompatibility> compatibleVehicles,
      DateTime createdAt,
      DateTime updatedAt,
      ProductStatus status,
      int views,
      int orders});
}

/// @nodoc
class __$$CarPartImplCopyWithImpl<$Res>
    extends _$CarPartCopyWithImpl<$Res, _$CarPartImpl>
    implements _$$CarPartImplCopyWith<$Res> {
  __$$CarPartImplCopyWithImpl(
      _$CarPartImpl _value, $Res Function(_$CarPartImpl) _then)
      : super(_value, _then);

  /// Create a copy of CarPart
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vendorId = null,
    Object? name = null,
    Object? description = null,
    Object? price = null,
    Object? quantity = null,
    Object? condition = null,
    Object? images = null,
    Object? compatibleVehicles = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? status = null,
    Object? views = null,
    Object? orders = null,
  }) {
    return _then(_$CarPartImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      vendorId: null == vendorId
          ? _value.vendorId
          : vendorId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      condition: null == condition
          ? _value.condition
          : condition // ignore: cast_nullable_to_non_nullable
              as String,
      images: null == images
          ? _value._images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      compatibleVehicles: null == compatibleVehicles
          ? _value._compatibleVehicles
          : compatibleVehicles // ignore: cast_nullable_to_non_nullable
              as List<VehicleCompatibility>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ProductStatus,
      views: null == views
          ? _value.views
          : views // ignore: cast_nullable_to_non_nullable
              as int,
      orders: null == orders
          ? _value.orders
          : orders // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CarPartImpl extends _CarPart {
  const _$CarPartImpl(
      {required this.id,
      required this.vendorId,
      required this.name,
      required this.description,
      required this.price,
      required this.quantity,
      required this.condition,
      required final List<String> images,
      required final List<VehicleCompatibility> compatibleVehicles,
      required this.createdAt,
      required this.updatedAt,
      this.status = ProductStatus.pending,
      this.views = 0,
      this.orders = 0})
      : _images = images,
        _compatibleVehicles = compatibleVehicles,
        super._();

  factory _$CarPartImpl.fromJson(Map<String, dynamic> json) =>
      _$$CarPartImplFromJson(json);

  @override
  final String id;
  @override
  final String vendorId;
  @override
  final String name;
  @override
  final String description;
  @override
  final double price;
  @override
  final int quantity;
  @override
  final String condition;
  final List<String> _images;
  @override
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  final List<VehicleCompatibility> _compatibleVehicles;
  @override
  List<VehicleCompatibility> get compatibleVehicles {
    if (_compatibleVehicles is EqualUnmodifiableListView)
      return _compatibleVehicles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_compatibleVehicles);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  @JsonKey()
  final ProductStatus status;
  @override
  @JsonKey()
  final int views;
  @override
  @JsonKey()
  final int orders;

  @override
  String toString() {
    return 'CarPart(id: $id, vendorId: $vendorId, name: $name, description: $description, price: $price, quantity: $quantity, condition: $condition, images: $images, compatibleVehicles: $compatibleVehicles, createdAt: $createdAt, updatedAt: $updatedAt, status: $status, views: $views, orders: $orders)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CarPartImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.vendorId, vendorId) ||
                other.vendorId == vendorId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.condition, condition) ||
                other.condition == condition) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            const DeepCollectionEquality()
                .equals(other._compatibleVehicles, _compatibleVehicles) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.views, views) || other.views == views) &&
            (identical(other.orders, orders) || other.orders == orders));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      vendorId,
      name,
      description,
      price,
      quantity,
      condition,
      const DeepCollectionEquality().hash(_images),
      const DeepCollectionEquality().hash(_compatibleVehicles),
      createdAt,
      updatedAt,
      status,
      views,
      orders);

  /// Create a copy of CarPart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CarPartImplCopyWith<_$CarPartImpl> get copyWith =>
      __$$CarPartImplCopyWithImpl<_$CarPartImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CarPartImplToJson(
      this,
    );
  }
}

abstract class _CarPart extends CarPart {
  const factory _CarPart(
      {required final String id,
      required final String vendorId,
      required final String name,
      required final String description,
      required final double price,
      required final int quantity,
      required final String condition,
      required final List<String> images,
      required final List<VehicleCompatibility> compatibleVehicles,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final ProductStatus status,
      final int views,
      final int orders}) = _$CarPartImpl;
  const _CarPart._() : super._();

  factory _CarPart.fromJson(Map<String, dynamic> json) = _$CarPartImpl.fromJson;

  @override
  String get id;
  @override
  String get vendorId;
  @override
  String get name;
  @override
  String get description;
  @override
  double get price;
  @override
  int get quantity;
  @override
  String get condition;
  @override
  List<String> get images;
  @override
  List<VehicleCompatibility> get compatibleVehicles;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  ProductStatus get status;
  @override
  int get views;
  @override
  int get orders;

  /// Create a copy of CarPart
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CarPartImplCopyWith<_$CarPartImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
