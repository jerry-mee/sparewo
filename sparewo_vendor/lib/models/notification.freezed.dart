// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VendorNotification _$VendorNotificationFromJson(Map<String, dynamic> json) {
  return _VendorNotification.fromJson(json);
}

/// @nodoc
mixin _$VendorNotification {
  String get id => throw _privateConstructorUsedError;
  String get vendorId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  NotificationType get type => throw _privateConstructorUsedError;
  Map<String, dynamic> get data => throw _privateConstructorUsedError;
  bool get isRead => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get readAt => throw _privateConstructorUsedError;

  /// Serializes this VendorNotification to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VendorNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VendorNotificationCopyWith<VendorNotification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VendorNotificationCopyWith<$Res> {
  factory $VendorNotificationCopyWith(
          VendorNotification value, $Res Function(VendorNotification) then) =
      _$VendorNotificationCopyWithImpl<$Res, VendorNotification>;
  @useResult
  $Res call(
      {String id,
      String vendorId,
      String title,
      String message,
      NotificationType type,
      Map<String, dynamic> data,
      bool isRead,
      String? imageUrl,
      DateTime createdAt,
      DateTime? readAt});
}

/// @nodoc
class _$VendorNotificationCopyWithImpl<$Res, $Val extends VendorNotification>
    implements $VendorNotificationCopyWith<$Res> {
  _$VendorNotificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VendorNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vendorId = null,
    Object? title = null,
    Object? message = null,
    Object? type = null,
    Object? data = null,
    Object? isRead = null,
    Object? imageUrl = freezed,
    Object? createdAt = null,
    Object? readAt = freezed,
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
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as NotificationType,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      readAt: freezed == readAt
          ? _value.readAt
          : readAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VendorNotificationImplCopyWith<$Res>
    implements $VendorNotificationCopyWith<$Res> {
  factory _$$VendorNotificationImplCopyWith(_$VendorNotificationImpl value,
          $Res Function(_$VendorNotificationImpl) then) =
      __$$VendorNotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String vendorId,
      String title,
      String message,
      NotificationType type,
      Map<String, dynamic> data,
      bool isRead,
      String? imageUrl,
      DateTime createdAt,
      DateTime? readAt});
}

/// @nodoc
class __$$VendorNotificationImplCopyWithImpl<$Res>
    extends _$VendorNotificationCopyWithImpl<$Res, _$VendorNotificationImpl>
    implements _$$VendorNotificationImplCopyWith<$Res> {
  __$$VendorNotificationImplCopyWithImpl(_$VendorNotificationImpl _value,
      $Res Function(_$VendorNotificationImpl) _then)
      : super(_value, _then);

  /// Create a copy of VendorNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vendorId = null,
    Object? title = null,
    Object? message = null,
    Object? type = null,
    Object? data = null,
    Object? isRead = null,
    Object? imageUrl = freezed,
    Object? createdAt = null,
    Object? readAt = freezed,
  }) {
    return _then(_$VendorNotificationImpl(
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
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as NotificationType,
      data: null == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      readAt: freezed == readAt
          ? _value.readAt
          : readAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VendorNotificationImpl extends _VendorNotification {
  const _$VendorNotificationImpl(
      {required this.id,
      required this.vendorId,
      required this.title,
      required this.message,
      required this.type,
      required final Map<String, dynamic> data,
      this.isRead = false,
      this.imageUrl,
      required this.createdAt,
      this.readAt})
      : _data = data,
        super._();

  factory _$VendorNotificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$VendorNotificationImplFromJson(json);

  @override
  final String id;
  @override
  final String vendorId;
  @override
  final String title;
  @override
  final String message;
  @override
  final NotificationType type;
  final Map<String, dynamic> _data;
  @override
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  @override
  @JsonKey()
  final bool isRead;
  @override
  final String? imageUrl;
  @override
  final DateTime createdAt;
  @override
  final DateTime? readAt;

  @override
  String toString() {
    return 'VendorNotification(id: $id, vendorId: $vendorId, title: $title, message: $message, type: $type, data: $data, isRead: $isRead, imageUrl: $imageUrl, createdAt: $createdAt, readAt: $readAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VendorNotificationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.vendorId, vendorId) ||
                other.vendorId == vendorId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.readAt, readAt) || other.readAt == readAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      vendorId,
      title,
      message,
      type,
      const DeepCollectionEquality().hash(_data),
      isRead,
      imageUrl,
      createdAt,
      readAt);

  /// Create a copy of VendorNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VendorNotificationImplCopyWith<_$VendorNotificationImpl> get copyWith =>
      __$$VendorNotificationImplCopyWithImpl<_$VendorNotificationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VendorNotificationImplToJson(
      this,
    );
  }
}

abstract class _VendorNotification extends VendorNotification {
  const factory _VendorNotification(
      {required final String id,
      required final String vendorId,
      required final String title,
      required final String message,
      required final NotificationType type,
      required final Map<String, dynamic> data,
      final bool isRead,
      final String? imageUrl,
      required final DateTime createdAt,
      final DateTime? readAt}) = _$VendorNotificationImpl;
  const _VendorNotification._() : super._();

  factory _VendorNotification.fromJson(Map<String, dynamic> json) =
      _$VendorNotificationImpl.fromJson;

  @override
  String get id;
  @override
  String get vendorId;
  @override
  String get title;
  @override
  String get message;
  @override
  NotificationType get type;
  @override
  Map<String, dynamic> get data;
  @override
  bool get isRead;
  @override
  String? get imageUrl;
  @override
  DateTime get createdAt;
  @override
  DateTime? get readAt;

  /// Create a copy of VendorNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VendorNotificationImplCopyWith<_$VendorNotificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
