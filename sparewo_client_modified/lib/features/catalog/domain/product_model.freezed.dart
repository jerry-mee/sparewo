// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductModel {

 String get id; String get partName; String get description; String get brand; double get unitPrice; double? get originalPrice; int get stockQuantity; List<String> get categories; String? get category; List<String> get imageUrls; List<String> get compatibility; String? get partNumber; String get condition; Map<String, dynamic> get specifications; bool get isActive; bool get isFeatured;@TimestampConverter() DateTime get createdAt;@NullableTimestampConverter() DateTime? get updatedAt;
/// Create a copy of ProductModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductModelCopyWith<ProductModel> get copyWith => _$ProductModelCopyWithImpl<ProductModel>(this as ProductModel, _$identity);

  /// Serializes this ProductModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductModel&&(identical(other.id, id) || other.id == id)&&(identical(other.partName, partName) || other.partName == partName)&&(identical(other.description, description) || other.description == description)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.originalPrice, originalPrice) || other.originalPrice == originalPrice)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&const DeepCollectionEquality().equals(other.categories, categories)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.imageUrls, imageUrls)&&const DeepCollectionEquality().equals(other.compatibility, compatibility)&&(identical(other.partNumber, partNumber) || other.partNumber == partNumber)&&(identical(other.condition, condition) || other.condition == condition)&&const DeepCollectionEquality().equals(other.specifications, specifications)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,partName,description,brand,unitPrice,originalPrice,stockQuantity,const DeepCollectionEquality().hash(categories),category,const DeepCollectionEquality().hash(imageUrls),const DeepCollectionEquality().hash(compatibility),partNumber,condition,const DeepCollectionEquality().hash(specifications),isActive,isFeatured,createdAt,updatedAt);

@override
String toString() {
  return 'ProductModel(id: $id, partName: $partName, description: $description, brand: $brand, unitPrice: $unitPrice, originalPrice: $originalPrice, stockQuantity: $stockQuantity, categories: $categories, category: $category, imageUrls: $imageUrls, compatibility: $compatibility, partNumber: $partNumber, condition: $condition, specifications: $specifications, isActive: $isActive, isFeatured: $isFeatured, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ProductModelCopyWith<$Res>  {
  factory $ProductModelCopyWith(ProductModel value, $Res Function(ProductModel) _then) = _$ProductModelCopyWithImpl;
@useResult
$Res call({
 String id, String partName, String description, String brand, double unitPrice, double? originalPrice, int stockQuantity, List<String> categories, String? category, List<String> imageUrls, List<String> compatibility, String? partNumber, String condition, Map<String, dynamic> specifications, bool isActive, bool isFeatured,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$ProductModelCopyWithImpl<$Res>
    implements $ProductModelCopyWith<$Res> {
  _$ProductModelCopyWithImpl(this._self, this._then);

  final ProductModel _self;
  final $Res Function(ProductModel) _then;

/// Create a copy of ProductModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? partName = null,Object? description = null,Object? brand = null,Object? unitPrice = null,Object? originalPrice = freezed,Object? stockQuantity = null,Object? categories = null,Object? category = freezed,Object? imageUrls = null,Object? compatibility = null,Object? partNumber = freezed,Object? condition = null,Object? specifications = null,Object? isActive = null,Object? isFeatured = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,partName: null == partName ? _self.partName : partName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double,originalPrice: freezed == originalPrice ? _self.originalPrice : originalPrice // ignore: cast_nullable_to_non_nullable
as double?,stockQuantity: null == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,imageUrls: null == imageUrls ? _self.imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,compatibility: null == compatibility ? _self.compatibility : compatibility // ignore: cast_nullable_to_non_nullable
as List<String>,partNumber: freezed == partNumber ? _self.partNumber : partNumber // ignore: cast_nullable_to_non_nullable
as String?,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,specifications: null == specifications ? _self.specifications : specifications // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductModel].
extension ProductModelPatterns on ProductModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductModel value)  $default,){
final _that = this;
switch (_that) {
case _ProductModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductModel value)?  $default,){
final _that = this;
switch (_that) {
case _ProductModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String partName,  String description,  String brand,  double unitPrice,  double? originalPrice,  int stockQuantity,  List<String> categories,  String? category,  List<String> imageUrls,  List<String> compatibility,  String? partNumber,  String condition,  Map<String, dynamic> specifications,  bool isActive,  bool isFeatured, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductModel() when $default != null:
return $default(_that.id,_that.partName,_that.description,_that.brand,_that.unitPrice,_that.originalPrice,_that.stockQuantity,_that.categories,_that.category,_that.imageUrls,_that.compatibility,_that.partNumber,_that.condition,_that.specifications,_that.isActive,_that.isFeatured,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String partName,  String description,  String brand,  double unitPrice,  double? originalPrice,  int stockQuantity,  List<String> categories,  String? category,  List<String> imageUrls,  List<String> compatibility,  String? partNumber,  String condition,  Map<String, dynamic> specifications,  bool isActive,  bool isFeatured, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ProductModel():
return $default(_that.id,_that.partName,_that.description,_that.brand,_that.unitPrice,_that.originalPrice,_that.stockQuantity,_that.categories,_that.category,_that.imageUrls,_that.compatibility,_that.partNumber,_that.condition,_that.specifications,_that.isActive,_that.isFeatured,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String partName,  String description,  String brand,  double unitPrice,  double? originalPrice,  int stockQuantity,  List<String> categories,  String? category,  List<String> imageUrls,  List<String> compatibility,  String? partNumber,  String condition,  Map<String, dynamic> specifications,  bool isActive,  bool isFeatured, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ProductModel() when $default != null:
return $default(_that.id,_that.partName,_that.description,_that.brand,_that.unitPrice,_that.originalPrice,_that.stockQuantity,_that.categories,_that.category,_that.imageUrls,_that.compatibility,_that.partNumber,_that.condition,_that.specifications,_that.isActive,_that.isFeatured,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductModel extends ProductModel {
  const _ProductModel({required this.id, required this.partName, required this.description, required this.brand, required this.unitPrice, this.originalPrice, required this.stockQuantity, final  List<String> categories = const [], this.category, required final  List<String> imageUrls, final  List<String> compatibility = const [], this.partNumber, this.condition = 'New', final  Map<String, dynamic> specifications = const {}, this.isActive = true, this.isFeatured = false, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.updatedAt}): _categories = categories,_imageUrls = imageUrls,_compatibility = compatibility,_specifications = specifications,super._();
  factory _ProductModel.fromJson(Map<String, dynamic> json) => _$ProductModelFromJson(json);

@override final  String id;
@override final  String partName;
@override final  String description;
@override final  String brand;
@override final  double unitPrice;
@override final  double? originalPrice;
@override final  int stockQuantity;
 final  List<String> _categories;
@override@JsonKey() List<String> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

@override final  String? category;
 final  List<String> _imageUrls;
@override List<String> get imageUrls {
  if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_imageUrls);
}

 final  List<String> _compatibility;
@override@JsonKey() List<String> get compatibility {
  if (_compatibility is EqualUnmodifiableListView) return _compatibility;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_compatibility);
}

@override final  String? partNumber;
@override@JsonKey() final  String condition;
 final  Map<String, dynamic> _specifications;
@override@JsonKey() Map<String, dynamic> get specifications {
  if (_specifications is EqualUnmodifiableMapView) return _specifications;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_specifications);
}

@override@JsonKey() final  bool isActive;
@override@JsonKey() final  bool isFeatured;
@override@TimestampConverter() final  DateTime createdAt;
@override@NullableTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of ProductModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductModelCopyWith<_ProductModel> get copyWith => __$ProductModelCopyWithImpl<_ProductModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductModel&&(identical(other.id, id) || other.id == id)&&(identical(other.partName, partName) || other.partName == partName)&&(identical(other.description, description) || other.description == description)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.originalPrice, originalPrice) || other.originalPrice == originalPrice)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._imageUrls, _imageUrls)&&const DeepCollectionEquality().equals(other._compatibility, _compatibility)&&(identical(other.partNumber, partNumber) || other.partNumber == partNumber)&&(identical(other.condition, condition) || other.condition == condition)&&const DeepCollectionEquality().equals(other._specifications, _specifications)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,partName,description,brand,unitPrice,originalPrice,stockQuantity,const DeepCollectionEquality().hash(_categories),category,const DeepCollectionEquality().hash(_imageUrls),const DeepCollectionEquality().hash(_compatibility),partNumber,condition,const DeepCollectionEquality().hash(_specifications),isActive,isFeatured,createdAt,updatedAt);

@override
String toString() {
  return 'ProductModel(id: $id, partName: $partName, description: $description, brand: $brand, unitPrice: $unitPrice, originalPrice: $originalPrice, stockQuantity: $stockQuantity, categories: $categories, category: $category, imageUrls: $imageUrls, compatibility: $compatibility, partNumber: $partNumber, condition: $condition, specifications: $specifications, isActive: $isActive, isFeatured: $isFeatured, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ProductModelCopyWith<$Res> implements $ProductModelCopyWith<$Res> {
  factory _$ProductModelCopyWith(_ProductModel value, $Res Function(_ProductModel) _then) = __$ProductModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String partName, String description, String brand, double unitPrice, double? originalPrice, int stockQuantity, List<String> categories, String? category, List<String> imageUrls, List<String> compatibility, String? partNumber, String condition, Map<String, dynamic> specifications, bool isActive, bool isFeatured,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$ProductModelCopyWithImpl<$Res>
    implements _$ProductModelCopyWith<$Res> {
  __$ProductModelCopyWithImpl(this._self, this._then);

  final _ProductModel _self;
  final $Res Function(_ProductModel) _then;

/// Create a copy of ProductModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? partName = null,Object? description = null,Object? brand = null,Object? unitPrice = null,Object? originalPrice = freezed,Object? stockQuantity = null,Object? categories = null,Object? category = freezed,Object? imageUrls = null,Object? compatibility = null,Object? partNumber = freezed,Object? condition = null,Object? specifications = null,Object? isActive = null,Object? isFeatured = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_ProductModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,partName: null == partName ? _self.partName : partName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double,originalPrice: freezed == originalPrice ? _self.originalPrice : originalPrice // ignore: cast_nullable_to_non_nullable
as double?,stockQuantity: null == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,imageUrls: null == imageUrls ? _self._imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,compatibility: null == compatibility ? _self._compatibility : compatibility // ignore: cast_nullable_to_non_nullable
as List<String>,partNumber: freezed == partNumber ? _self.partNumber : partNumber // ignore: cast_nullable_to_non_nullable
as String?,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,specifications: null == specifications ? _self._specifications : specifications // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
