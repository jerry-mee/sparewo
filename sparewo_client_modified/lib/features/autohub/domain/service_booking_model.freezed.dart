// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_booking_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServiceBooking {

 String? get id; String get userId; String get userEmail; String get userName; String? get userPhone; String get vehicleBrand; String get vehicleModel; int get vehicleYear; List<String> get services; String get serviceDescription;@TimestampConverter() DateTime get pickupDate; String get pickupTime; String get pickupLocation; String get status; String? get bookingNumber; String? get notes;@NullableTimestampConverter() DateTime? get createdAt;@NullableTimestampConverter() DateTime? get updatedAt;
/// Create a copy of ServiceBooking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceBookingCopyWith<ServiceBooking> get copyWith => _$ServiceBookingCopyWithImpl<ServiceBooking>(this as ServiceBooking, _$identity);

  /// Serializes this ServiceBooking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceBooking&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userEmail, userEmail) || other.userEmail == userEmail)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userPhone, userPhone) || other.userPhone == userPhone)&&(identical(other.vehicleBrand, vehicleBrand) || other.vehicleBrand == vehicleBrand)&&(identical(other.vehicleModel, vehicleModel) || other.vehicleModel == vehicleModel)&&(identical(other.vehicleYear, vehicleYear) || other.vehicleYear == vehicleYear)&&const DeepCollectionEquality().equals(other.services, services)&&(identical(other.serviceDescription, serviceDescription) || other.serviceDescription == serviceDescription)&&(identical(other.pickupDate, pickupDate) || other.pickupDate == pickupDate)&&(identical(other.pickupTime, pickupTime) || other.pickupTime == pickupTime)&&(identical(other.pickupLocation, pickupLocation) || other.pickupLocation == pickupLocation)&&(identical(other.status, status) || other.status == status)&&(identical(other.bookingNumber, bookingNumber) || other.bookingNumber == bookingNumber)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,userEmail,userName,userPhone,vehicleBrand,vehicleModel,vehicleYear,const DeepCollectionEquality().hash(services),serviceDescription,pickupDate,pickupTime,pickupLocation,status,bookingNumber,notes,createdAt,updatedAt);

@override
String toString() {
  return 'ServiceBooking(id: $id, userId: $userId, userEmail: $userEmail, userName: $userName, userPhone: $userPhone, vehicleBrand: $vehicleBrand, vehicleModel: $vehicleModel, vehicleYear: $vehicleYear, services: $services, serviceDescription: $serviceDescription, pickupDate: $pickupDate, pickupTime: $pickupTime, pickupLocation: $pickupLocation, status: $status, bookingNumber: $bookingNumber, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ServiceBookingCopyWith<$Res>  {
  factory $ServiceBookingCopyWith(ServiceBooking value, $Res Function(ServiceBooking) _then) = _$ServiceBookingCopyWithImpl;
@useResult
$Res call({
 String? id, String userId, String userEmail, String userName, String? userPhone, String vehicleBrand, String vehicleModel, int vehicleYear, List<String> services, String serviceDescription,@TimestampConverter() DateTime pickupDate, String pickupTime, String pickupLocation, String status, String? bookingNumber, String? notes,@NullableTimestampConverter() DateTime? createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$ServiceBookingCopyWithImpl<$Res>
    implements $ServiceBookingCopyWith<$Res> {
  _$ServiceBookingCopyWithImpl(this._self, this._then);

  final ServiceBooking _self;
  final $Res Function(ServiceBooking) _then;

/// Create a copy of ServiceBooking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? userId = null,Object? userEmail = null,Object? userName = null,Object? userPhone = freezed,Object? vehicleBrand = null,Object? vehicleModel = null,Object? vehicleYear = null,Object? services = null,Object? serviceDescription = null,Object? pickupDate = null,Object? pickupTime = null,Object? pickupLocation = null,Object? status = null,Object? bookingNumber = freezed,Object? notes = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userEmail: null == userEmail ? _self.userEmail : userEmail // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userPhone: freezed == userPhone ? _self.userPhone : userPhone // ignore: cast_nullable_to_non_nullable
as String?,vehicleBrand: null == vehicleBrand ? _self.vehicleBrand : vehicleBrand // ignore: cast_nullable_to_non_nullable
as String,vehicleModel: null == vehicleModel ? _self.vehicleModel : vehicleModel // ignore: cast_nullable_to_non_nullable
as String,vehicleYear: null == vehicleYear ? _self.vehicleYear : vehicleYear // ignore: cast_nullable_to_non_nullable
as int,services: null == services ? _self.services : services // ignore: cast_nullable_to_non_nullable
as List<String>,serviceDescription: null == serviceDescription ? _self.serviceDescription : serviceDescription // ignore: cast_nullable_to_non_nullable
as String,pickupDate: null == pickupDate ? _self.pickupDate : pickupDate // ignore: cast_nullable_to_non_nullable
as DateTime,pickupTime: null == pickupTime ? _self.pickupTime : pickupTime // ignore: cast_nullable_to_non_nullable
as String,pickupLocation: null == pickupLocation ? _self.pickupLocation : pickupLocation // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,bookingNumber: freezed == bookingNumber ? _self.bookingNumber : bookingNumber // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceBooking].
extension ServiceBookingPatterns on ServiceBooking {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceBooking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceBooking() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceBooking value)  $default,){
final _that = this;
switch (_that) {
case _ServiceBooking():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceBooking value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceBooking() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String userId,  String userEmail,  String userName,  String? userPhone,  String vehicleBrand,  String vehicleModel,  int vehicleYear,  List<String> services,  String serviceDescription, @TimestampConverter()  DateTime pickupDate,  String pickupTime,  String pickupLocation,  String status,  String? bookingNumber,  String? notes, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceBooking() when $default != null:
return $default(_that.id,_that.userId,_that.userEmail,_that.userName,_that.userPhone,_that.vehicleBrand,_that.vehicleModel,_that.vehicleYear,_that.services,_that.serviceDescription,_that.pickupDate,_that.pickupTime,_that.pickupLocation,_that.status,_that.bookingNumber,_that.notes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String userId,  String userEmail,  String userName,  String? userPhone,  String vehicleBrand,  String vehicleModel,  int vehicleYear,  List<String> services,  String serviceDescription, @TimestampConverter()  DateTime pickupDate,  String pickupTime,  String pickupLocation,  String status,  String? bookingNumber,  String? notes, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ServiceBooking():
return $default(_that.id,_that.userId,_that.userEmail,_that.userName,_that.userPhone,_that.vehicleBrand,_that.vehicleModel,_that.vehicleYear,_that.services,_that.serviceDescription,_that.pickupDate,_that.pickupTime,_that.pickupLocation,_that.status,_that.bookingNumber,_that.notes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String userId,  String userEmail,  String userName,  String? userPhone,  String vehicleBrand,  String vehicleModel,  int vehicleYear,  List<String> services,  String serviceDescription, @TimestampConverter()  DateTime pickupDate,  String pickupTime,  String pickupLocation,  String status,  String? bookingNumber,  String? notes, @NullableTimestampConverter()  DateTime? createdAt, @NullableTimestampConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ServiceBooking() when $default != null:
return $default(_that.id,_that.userId,_that.userEmail,_that.userName,_that.userPhone,_that.vehicleBrand,_that.vehicleModel,_that.vehicleYear,_that.services,_that.serviceDescription,_that.pickupDate,_that.pickupTime,_that.pickupLocation,_that.status,_that.bookingNumber,_that.notes,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceBooking implements ServiceBooking {
  const _ServiceBooking({this.id, required this.userId, required this.userEmail, required this.userName, this.userPhone, required this.vehicleBrand, required this.vehicleModel, required this.vehicleYear, required final  List<String> services, required this.serviceDescription, @TimestampConverter() required this.pickupDate, required this.pickupTime, required this.pickupLocation, this.status = 'pending', this.bookingNumber, this.notes, @NullableTimestampConverter() this.createdAt, @NullableTimestampConverter() this.updatedAt}): _services = services;
  factory _ServiceBooking.fromJson(Map<String, dynamic> json) => _$ServiceBookingFromJson(json);

@override final  String? id;
@override final  String userId;
@override final  String userEmail;
@override final  String userName;
@override final  String? userPhone;
@override final  String vehicleBrand;
@override final  String vehicleModel;
@override final  int vehicleYear;
 final  List<String> _services;
@override List<String> get services {
  if (_services is EqualUnmodifiableListView) return _services;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_services);
}

@override final  String serviceDescription;
@override@TimestampConverter() final  DateTime pickupDate;
@override final  String pickupTime;
@override final  String pickupLocation;
@override@JsonKey() final  String status;
@override final  String? bookingNumber;
@override final  String? notes;
@override@NullableTimestampConverter() final  DateTime? createdAt;
@override@NullableTimestampConverter() final  DateTime? updatedAt;

/// Create a copy of ServiceBooking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceBookingCopyWith<_ServiceBooking> get copyWith => __$ServiceBookingCopyWithImpl<_ServiceBooking>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceBookingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceBooking&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userEmail, userEmail) || other.userEmail == userEmail)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userPhone, userPhone) || other.userPhone == userPhone)&&(identical(other.vehicleBrand, vehicleBrand) || other.vehicleBrand == vehicleBrand)&&(identical(other.vehicleModel, vehicleModel) || other.vehicleModel == vehicleModel)&&(identical(other.vehicleYear, vehicleYear) || other.vehicleYear == vehicleYear)&&const DeepCollectionEquality().equals(other._services, _services)&&(identical(other.serviceDescription, serviceDescription) || other.serviceDescription == serviceDescription)&&(identical(other.pickupDate, pickupDate) || other.pickupDate == pickupDate)&&(identical(other.pickupTime, pickupTime) || other.pickupTime == pickupTime)&&(identical(other.pickupLocation, pickupLocation) || other.pickupLocation == pickupLocation)&&(identical(other.status, status) || other.status == status)&&(identical(other.bookingNumber, bookingNumber) || other.bookingNumber == bookingNumber)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,userEmail,userName,userPhone,vehicleBrand,vehicleModel,vehicleYear,const DeepCollectionEquality().hash(_services),serviceDescription,pickupDate,pickupTime,pickupLocation,status,bookingNumber,notes,createdAt,updatedAt);

@override
String toString() {
  return 'ServiceBooking(id: $id, userId: $userId, userEmail: $userEmail, userName: $userName, userPhone: $userPhone, vehicleBrand: $vehicleBrand, vehicleModel: $vehicleModel, vehicleYear: $vehicleYear, services: $services, serviceDescription: $serviceDescription, pickupDate: $pickupDate, pickupTime: $pickupTime, pickupLocation: $pickupLocation, status: $status, bookingNumber: $bookingNumber, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ServiceBookingCopyWith<$Res> implements $ServiceBookingCopyWith<$Res> {
  factory _$ServiceBookingCopyWith(_ServiceBooking value, $Res Function(_ServiceBooking) _then) = __$ServiceBookingCopyWithImpl;
@override @useResult
$Res call({
 String? id, String userId, String userEmail, String userName, String? userPhone, String vehicleBrand, String vehicleModel, int vehicleYear, List<String> services, String serviceDescription,@TimestampConverter() DateTime pickupDate, String pickupTime, String pickupLocation, String status, String? bookingNumber, String? notes,@NullableTimestampConverter() DateTime? createdAt,@NullableTimestampConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$ServiceBookingCopyWithImpl<$Res>
    implements _$ServiceBookingCopyWith<$Res> {
  __$ServiceBookingCopyWithImpl(this._self, this._then);

  final _ServiceBooking _self;
  final $Res Function(_ServiceBooking) _then;

/// Create a copy of ServiceBooking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? userId = null,Object? userEmail = null,Object? userName = null,Object? userPhone = freezed,Object? vehicleBrand = null,Object? vehicleModel = null,Object? vehicleYear = null,Object? services = null,Object? serviceDescription = null,Object? pickupDate = null,Object? pickupTime = null,Object? pickupLocation = null,Object? status = null,Object? bookingNumber = freezed,Object? notes = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_ServiceBooking(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userEmail: null == userEmail ? _self.userEmail : userEmail // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userPhone: freezed == userPhone ? _self.userPhone : userPhone // ignore: cast_nullable_to_non_nullable
as String?,vehicleBrand: null == vehicleBrand ? _self.vehicleBrand : vehicleBrand // ignore: cast_nullable_to_non_nullable
as String,vehicleModel: null == vehicleModel ? _self.vehicleModel : vehicleModel // ignore: cast_nullable_to_non_nullable
as String,vehicleYear: null == vehicleYear ? _self.vehicleYear : vehicleYear // ignore: cast_nullable_to_non_nullable
as int,services: null == services ? _self._services : services // ignore: cast_nullable_to_non_nullable
as List<String>,serviceDescription: null == serviceDescription ? _self.serviceDescription : serviceDescription // ignore: cast_nullable_to_non_nullable
as String,pickupDate: null == pickupDate ? _self.pickupDate : pickupDate // ignore: cast_nullable_to_non_nullable
as DateTime,pickupTime: null == pickupTime ? _self.pickupTime : pickupTime // ignore: cast_nullable_to_non_nullable
as String,pickupLocation: null == pickupLocation ? _self.pickupLocation : pickupLocation // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,bookingNumber: freezed == bookingNumber ? _self.bookingNumber : bookingNumber // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
