// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'car_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CarModel {

 String get id; String get userId; String get make; String get model; int get year; String? get plateNumber; String? get vin; String? get color; String? get engineType; String? get transmission; int? get mileage;// Image Fields (Ensuring they are present for build_runner)
 String? get frontImageUrl; String? get sideImageUrl;@NullableTimestampConverter() DateTime? get lastServiceDate;@NullableTimestampConverter() DateTime? get insuranceExpiryDate; bool get isDefault;@TimestampConverter() DateTime get createdAt;@NullableTimestampConverter() DateTime? get updatedAt;
/// Create a copy of CarModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CarModelCopyWith<CarModel> get copyWith => _$CarModelCopyWithImpl<CarModel>(this as CarModel, _$identity);

  /// Serializes this CarModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CarModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.make, make) || other.make == make)&&(identical(other.model, model) || other.model == model)&&(identical(other.year, year) || other.year == year)&&(identical(other.plateNumber, plateNumber) || other.plateNumber == plateNumber)&&(identical(other.vin, vin) || other.vin == vin)&&(identical(other.color, color) || other.color == color)&&(identical(other.engineType, engineType) || other.engineType == engineType)&&(identical(other.transmission, transmission) || other.transmission == transmission)&&(identical(other.mileage, mileage) || other.mileage == mileage)&&(identical(other.frontImageUrl, frontImageUrl) || other.frontImageUrl == frontImageUrl)&&(identical(other.sideImageUrl, sideImageUrl) || other.sideImageUrl == sideImageUrl)&&(identical(other.lastServiceDate, lastServiceDate) || other.lastServiceDate == lastServiceDate)&&(identical(other.insuranceExpiryDate, insuranceExpiryDate) || other.insuranceExpiryDate == insuranceExpiryDate)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,make,model,year,plateNumber,vin,color,engineType,transmission,mileage,frontImageUrl,sideImageUrl,lastServiceDate,insuranceExpiryDate,isDefault,createdAt,updatedAt);

@override
String toString() {
  return 'CarModel(id: $id, userId: $userId, make: $make, model: $model, year: $year, plateNumber: $plateNumber, vin: $vin, color: $color, engineType: $engineType, transmission: $transmission, mileage: $mileage, frontImageUrl: $frontImageUrl, sideImageUrl: $sideImageUrl, lastServiceDate: $lastServiceDate, insuranceExpiryDate: $insuranceExpiryDate, isDefault: $isDefault, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CarModelCopyWith<$Res>  {
  factory $CarModelCopyWith(CarModel value, $Res Function(CarModel) _then) = _$CarModelCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String make, String model, int year, String? plateNumber, String? vin, String? color, String? engineType, String? transmission, int? mileage, String? frontImageUrl, String? sideImageUrl,@NullableTimestampConverter() DateTime? lastServiceDate,@NullableTimestampConverter() DateTime? insuranceExpiryDate, bool isDefault,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$CarModelCopyWithImpl<$Res>
    implements $CarModelCopyWith<$Res> {
  _$CarModelCopyWithImpl(this._self, this._then);

  final CarModel _self;
  final $Res Function(CarModel) _then;

/// Create a copy of CarModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? make = null,Object? model = null,Object? year = null,Object? plateNumber = freezed,Object? vin = freezed,Object? color = freezed,Object? engineType = freezed,Object? transmission = freezed,Object? mileage = freezed,Object? frontImageUrl = freezed,Object? sideImageUrl = freezed,Object? lastServiceDate = freezed,Object? insuranceExpiryDate = freezed,Object? isDefault = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,make: null == make ? _self.make : make // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,plateNumber: freezed == plateNumber ? _self.plateNumber : plateNumber // ignore: cast_nullable_to_non_nullable
as String?,vin: freezed == vin ? _self.vin : vin // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,engineType: freezed == engineType ? _self.engineType : engineType // ignore: cast_nullable_to_non_nullable
as String?,transmission: freezed == transmission ? _self.transmission : transmission // ignore: cast_nullable_to_non_nullable
as String?,mileage: freezed == mileage ? _self.mileage : mileage // ignore: cast_nullable_to_non_nullable
as int?,frontImageUrl: freezed == frontImageUrl ? _self.frontImageUrl : frontImageUrl // ignore: cast_nullable_to_non_nullable
as String?,sideImageUrl: freezed == sideImageUrl ? _self.sideImageUrl : sideImageUrl // ignore: cast_nullable_to_non_nullable
as String?,lastServiceDate: freezed == lastServiceDate ? _self.lastServiceDate : lastServiceDate // ignore: cast_nullable_to_non_nullable
as DateTime?,insuranceExpiryDate: freezed == insuranceExpiryDate ? _self.insuranceExpiryDate : insuranceExpiryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CarModel].
extension CarModelPatterns on CarModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CarModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CarModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CarModel value)  $default,){
final _that = this;
switch (_that) {
case _CarModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CarModel value)?  $default,){
final _that = this;
switch (_that) {
case _CarModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String make,  String model,  int year,  String? plateNumber,  String? vin,  String? color,  String? engineType,  String? transmission,  int? mileage,  String? frontImageUrl,  String? sideImageUrl, @NullableTimestampConverter()  DateTime? lastServiceDate, @NullableTimestampConverter()  DateTime? insuranceExpiryDate,  bool isDefault, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CarModel() when $default != null:
return $default(_that.id,_that.userId,_that.make,_that.model,_that.year,_that.plateNumber,_that.vin,_that.color,_that.engineType,_that.transmission,_that.mileage,_that.frontImageUrl,_that.sideImageUrl,_that.lastServiceDate,_that.insuranceExpiryDate,_that.isDefault,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String make,  String model,  int year,  String? plateNumber,  String? vin,  String? color,  String? engineType,  String? transmission,  int? mileage,  String? frontImageUrl,  String? sideImageUrl, @NullableTimestampConverter()  DateTime? lastServiceDate, @NullableTimestampConverter()  DateTime? insuranceExpiryDate,  bool isDefault, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CarModel():
return $default(_that.id,_that.userId,_that.make,_that.model,_that.year,_that.plateNumber,_that.vin,_that.color,_that.engineType,_that.transmission,_that.mileage,_that.frontImageUrl,_that.sideImageUrl,_that.lastServiceDate,_that.insuranceExpiryDate,_that.isDefault,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String make,  String model,  int year,  String? plateNumber,  String? vin,  String? color,  String? engineType,  String? transmission,  int? mileage,  String? frontImageUrl,  String? sideImageUrl, @NullableTimestampConverter()  DateTime? lastServiceDate, @NullableTimestampConverter()  DateTime? insuranceExpiryDate,  bool isDefault, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CarModel() when $default != null:
return $default(_that.id,_that.userId,_that.make,_that.model,_that.year,_that.plateNumber,_that.vin,_that.color,_that.engineType,_that.transmission,_that.mileage,_that.frontImageUrl,_that.sideImageUrl,_that.lastServiceDate,_that.insuranceExpiryDate,_that.isDefault,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CarModel extends CarModel {
  const _CarModel({required this.id, required this.userId, required this.make, required this.model, required this.year, this.plateNumber, this.vin, this.color, this.engineType, this.transmission, this.mileage, this.frontImageUrl, this.sideImageUrl, @NullableTimestampConverter() this.lastServiceDate, @NullableTimestampConverter() this.insuranceExpiryDate, this.isDefault = false, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.updatedAt}): super._();
  factory _CarModel.fromJson(Map<String, dynamic> json) => _$CarModelFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String make;
@override final  String model;
@override final  int year;
@override final  String? plateNumber;
@override final  String? vin;
@override final  String? color;
@override final  String? engineType;
@override final  String? transmission;
@override final  int? mileage;
// Image Fields (Ensuring they are present for build_runner)
@override final  String? frontImageUrl;
@override final  String? sideImageUrl;
@override@NullableTimestampConverter() final  DateTime? lastServiceDate;
@override@NullableTimestampConverter() final  DateTime? insuranceExpiryDate;
@override@JsonKey() final  bool isDefault;
@override@TimestampConverter() final  DateTime createdAt;
@override@NullableTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of CarModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CarModelCopyWith<_CarModel> get copyWith => __$CarModelCopyWithImpl<_CarModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CarModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CarModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.make, make) || other.make == make)&&(identical(other.model, model) || other.model == model)&&(identical(other.year, year) || other.year == year)&&(identical(other.plateNumber, plateNumber) || other.plateNumber == plateNumber)&&(identical(other.vin, vin) || other.vin == vin)&&(identical(other.color, color) || other.color == color)&&(identical(other.engineType, engineType) || other.engineType == engineType)&&(identical(other.transmission, transmission) || other.transmission == transmission)&&(identical(other.mileage, mileage) || other.mileage == mileage)&&(identical(other.frontImageUrl, frontImageUrl) || other.frontImageUrl == frontImageUrl)&&(identical(other.sideImageUrl, sideImageUrl) || other.sideImageUrl == sideImageUrl)&&(identical(other.lastServiceDate, lastServiceDate) || other.lastServiceDate == lastServiceDate)&&(identical(other.insuranceExpiryDate, insuranceExpiryDate) || other.insuranceExpiryDate == insuranceExpiryDate)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,make,model,year,plateNumber,vin,color,engineType,transmission,mileage,frontImageUrl,sideImageUrl,lastServiceDate,insuranceExpiryDate,isDefault,createdAt,updatedAt);

@override
String toString() {
  return 'CarModel(id: $id, userId: $userId, make: $make, model: $model, year: $year, plateNumber: $plateNumber, vin: $vin, color: $color, engineType: $engineType, transmission: $transmission, mileage: $mileage, frontImageUrl: $frontImageUrl, sideImageUrl: $sideImageUrl, lastServiceDate: $lastServiceDate, insuranceExpiryDate: $insuranceExpiryDate, isDefault: $isDefault, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CarModelCopyWith<$Res> implements $CarModelCopyWith<$Res> {
  factory _$CarModelCopyWith(_CarModel value, $Res Function(_CarModel) _then) = __$CarModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String make, String model, int year, String? plateNumber, String? vin, String? color, String? engineType, String? transmission, int? mileage, String? frontImageUrl, String? sideImageUrl,@NullableTimestampConverter() DateTime? lastServiceDate,@NullableTimestampConverter() DateTime? insuranceExpiryDate, bool isDefault,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$CarModelCopyWithImpl<$Res>
    implements _$CarModelCopyWith<$Res> {
  __$CarModelCopyWithImpl(this._self, this._then);

  final _CarModel _self;
  final $Res Function(_CarModel) _then;

/// Create a copy of CarModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? make = null,Object? model = null,Object? year = null,Object? plateNumber = freezed,Object? vin = freezed,Object? color = freezed,Object? engineType = freezed,Object? transmission = freezed,Object? mileage = freezed,Object? frontImageUrl = freezed,Object? sideImageUrl = freezed,Object? lastServiceDate = freezed,Object? insuranceExpiryDate = freezed,Object? isDefault = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_CarModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,make: null == make ? _self.make : make // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,plateNumber: freezed == plateNumber ? _self.plateNumber : plateNumber // ignore: cast_nullable_to_non_nullable
as String?,vin: freezed == vin ? _self.vin : vin // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,engineType: freezed == engineType ? _self.engineType : engineType // ignore: cast_nullable_to_non_nullable
as String?,transmission: freezed == transmission ? _self.transmission : transmission // ignore: cast_nullable_to_non_nullable
as String?,mileage: freezed == mileage ? _self.mileage : mileage // ignore: cast_nullable_to_non_nullable
as int?,frontImageUrl: freezed == frontImageUrl ? _self.frontImageUrl : frontImageUrl // ignore: cast_nullable_to_non_nullable
as String?,sideImageUrl: freezed == sideImageUrl ? _self.sideImageUrl : sideImageUrl // ignore: cast_nullable_to_non_nullable
as String?,lastServiceDate: freezed == lastServiceDate ? _self.lastServiceDate : lastServiceDate // ignore: cast_nullable_to_non_nullable
as DateTime?,insuranceExpiryDate: freezed == insuranceExpiryDate ? _self.insuranceExpiryDate : insuranceExpiryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
