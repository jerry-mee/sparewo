// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Product _$ProductFromJson(Map<String, dynamic> json) {
  return _Product.fromJson(json);
}

/// @nodoc
mixin _$Product {
  String get id => throw _privateConstructorUsedError;
  String get vendorId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  int get stockQuantity => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  List<String> get images => throw _privateConstructorUsedError;
  String get carModel => throw _privateConstructorUsedError;
  String get yearOfManufacture => throw _privateConstructorUsedError;
  List<String> get compatibleModels => throw _privateConstructorUsedError;
  String? get partNumber => throw _privateConstructorUsedError;
  ProductStatus get status => throw _privateConstructorUsedError;
  int get views => throw _privateConstructorUsedError;
  int get orders => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductCopyWith<Product> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductCopyWith<$Res> {
  factory $ProductCopyWith(Product value, $Res Function(Product) then) =
      _$ProductCopyWithImpl<$Res, Product>;
  @useResult
  $Res call(
      {String id,
      String vendorId,
      String title,
      String description,
      double price,
      int stockQuantity,
      String category,
      List<String> images,
      String carModel,
      String yearOfManufacture,
      List<String> compatibleModels,
      String? partNumber,
      ProductStatus status,
      int views,
      int orders,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$ProductCopyWithImpl<$Res, $Val extends Product>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vendorId = null,
    Object? title = null,
    Object? description = null,
    Object? price = null,
    Object? stockQuantity = null,
    Object? category = null,
    Object? images = null,
    Object? carModel = null,
    Object? yearOfManufacture = null,
    Object? compatibleModels = null,
    Object? partNumber = freezed,
    Object? status = null,
    Object? views = null,
    Object? orders = null,
    Object? createdAt = null,
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
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      stockQuantity: null == stockQuantity
          ? _value.stockQuantity
          : stockQuantity // ignore: cast_nullable_to_non_nullable
              as int,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      images: null == images
          ? _value.images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      carModel: null == carModel
          ? _value.carModel
          : carModel // ignore: cast_nullable_to_non_nullable
              as String,
      yearOfManufacture: null == yearOfManufacture
          ? _value.yearOfManufacture
          : yearOfManufacture // ignore: cast_nullable_to_non_nullable
              as String,
      compatibleModels: null == compatibleModels
          ? _value.compatibleModels
          : compatibleModels // ignore: cast_nullable_to_non_nullable
              as List<String>,
      partNumber: freezed == partNumber
          ? _value.partNumber
          : partNumber // ignore: cast_nullable_to_non_nullable
              as String?,
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
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProductImplCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$$ProductImplCopyWith(
          _$ProductImpl value, $Res Function(_$ProductImpl) then) =
      __$$ProductImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String vendorId,
      String title,
      String description,
      double price,
      int stockQuantity,
      String category,
      List<String> images,
      String carModel,
      String yearOfManufacture,
      List<String> compatibleModels,
      String? partNumber,
      ProductStatus status,
      int views,
      int orders,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$ProductImplCopyWithImpl<$Res>
    extends _$ProductCopyWithImpl<$Res, _$ProductImpl>
    implements _$$ProductImplCopyWith<$Res> {
  __$$ProductImplCopyWithImpl(
      _$ProductImpl _value, $Res Function(_$ProductImpl) _then)
      : super(_value, _then);

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vendorId = null,
    Object? title = null,
    Object? description = null,
    Object? price = null,
    Object? stockQuantity = null,
    Object? category = null,
    Object? images = null,
    Object? carModel = null,
    Object? yearOfManufacture = null,
    Object? compatibleModels = null,
    Object? partNumber = freezed,
    Object? status = null,
    Object? views = null,
    Object? orders = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ProductImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      vendorId: null == vendorId
          ? _value.vendorId
          : vendorId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      stockQuantity: null == stockQuantity
          ? _value.stockQuantity
          : stockQuantity // ignore: cast_nullable_to_non_nullable
              as int,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      images: null == images
          ? _value._images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      carModel: null == carModel
          ? _value.carModel
          : carModel // ignore: cast_nullable_to_non_nullable
              as String,
      yearOfManufacture: null == yearOfManufacture
          ? _value.yearOfManufacture
          : yearOfManufacture // ignore: cast_nullable_to_non_nullable
              as String,
      compatibleModels: null == compatibleModels
          ? _value._compatibleModels
          : compatibleModels // ignore: cast_nullable_to_non_nullable
              as List<String>,
      partNumber: freezed == partNumber
          ? _value.partNumber
          : partNumber // ignore: cast_nullable_to_non_nullable
              as String?,
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
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductImpl extends _Product {
  const _$ProductImpl(
      {required this.id,
      required this.vendorId,
      required this.title,
      required this.description,
      required this.price,
      required this.stockQuantity,
      required this.category,
      required final List<String> images,
      required this.carModel,
      required this.yearOfManufacture,
      required final List<String> compatibleModels,
      this.partNumber,
      required this.status,
      this.views = 0,
      this.orders = 0,
      required this.createdAt,
      required this.updatedAt})
      : _images = images,
        _compatibleModels = compatibleModels,
        super._();

  factory _$ProductImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductImplFromJson(json);

  @override
  final String id;
  @override
  final String vendorId;
  @override
  final String title;
  @override
  final String description;
  @override
  final double price;
  @override
  final int stockQuantity;
  @override
  final String category;
  final List<String> _images;
  @override
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  @override
  final String carModel;
  @override
  final String yearOfManufacture;
  final List<String> _compatibleModels;
  @override
  List<String> get compatibleModels {
    if (_compatibleModels is EqualUnmodifiableListView)
      return _compatibleModels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_compatibleModels);
  }

  @override
  final String? partNumber;
  @override
  final ProductStatus status;
  @override
  @JsonKey()
  final int views;
  @override
  @JsonKey()
  final int orders;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Product(id: $id, vendorId: $vendorId, title: $title, description: $description, price: $price, stockQuantity: $stockQuantity, category: $category, images: $images, carModel: $carModel, yearOfManufacture: $yearOfManufacture, compatibleModels: $compatibleModels, partNumber: $partNumber, status: $status, views: $views, orders: $orders, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.vendorId, vendorId) ||
                other.vendorId == vendorId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.stockQuantity, stockQuantity) ||
                other.stockQuantity == stockQuantity) &&
            (identical(other.category, category) ||
                other.category == category) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.carModel, carModel) ||
                other.carModel == carModel) &&
            (identical(other.yearOfManufacture, yearOfManufacture) ||
                other.yearOfManufacture == yearOfManufacture) &&
            const DeepCollectionEquality()
                .equals(other._compatibleModels, _compatibleModels) &&
            (identical(other.partNumber, partNumber) ||
                other.partNumber == partNumber) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.views, views) || other.views == views) &&
            (identical(other.orders, orders) || other.orders == orders) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      vendorId,
      title,
      description,
      price,
      stockQuantity,
      category,
      const DeepCollectionEquality().hash(_images),
      carModel,
      yearOfManufacture,
      const DeepCollectionEquality().hash(_compatibleModels),
      partNumber,
      status,
      views,
      orders,
      createdAt,
      updatedAt);

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      __$$ProductImplCopyWithImpl<_$ProductImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductImplToJson(
      this,
    );
  }
}

abstract class _Product extends Product {
  const factory _Product(
      {required final String id,
      required final String vendorId,
      required final String title,
      required final String description,
      required final double price,
      required final int stockQuantity,
      required final String category,
      required final List<String> images,
      required final String carModel,
      required final String yearOfManufacture,
      required final List<String> compatibleModels,
      final String? partNumber,
      required final ProductStatus status,
      final int views,
      final int orders,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$ProductImpl;
  const _Product._() : super._();

  factory _Product.fromJson(Map<String, dynamic> json) = _$ProductImpl.fromJson;

  @override
  String get id;
  @override
  String get vendorId;
  @override
  String get title;
  @override
  String get description;
  @override
  double get price;
  @override
  int get stockQuantity;
  @override
  String get category;
  @override
  List<String> get images;
  @override
  String get carModel;
  @override
  String get yearOfManufacture;
  @override
  List<String> get compatibleModels;
  @override
  String? get partNumber;
  @override
  ProductStatus get status;
  @override
  int get views;
  @override
  int get orders;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
