// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeviceEntity {

 String get id; String get serial; String get modelName; DeviceStatus get status; ConnectionType get connectionType;
/// Create a copy of DeviceEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceEntityCopyWith<DeviceEntity> get copyWith => _$DeviceEntityCopyWithImpl<DeviceEntity>(this as DeviceEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.serial, serial) || other.serial == serial)&&(identical(other.modelName, modelName) || other.modelName == modelName)&&(identical(other.status, status) || other.status == status)&&(identical(other.connectionType, connectionType) || other.connectionType == connectionType));
}


@override
int get hashCode => Object.hash(runtimeType,id,serial,modelName,status,connectionType);

@override
String toString() {
  return 'DeviceEntity(id: $id, serial: $serial, modelName: $modelName, status: $status, connectionType: $connectionType)';
}


}

/// @nodoc
abstract mixin class $DeviceEntityCopyWith<$Res>  {
  factory $DeviceEntityCopyWith(DeviceEntity value, $Res Function(DeviceEntity) _then) = _$DeviceEntityCopyWithImpl;
@useResult
$Res call({
 String id, String serial, String modelName, DeviceStatus status, ConnectionType connectionType
});




}
/// @nodoc
class _$DeviceEntityCopyWithImpl<$Res>
    implements $DeviceEntityCopyWith<$Res> {
  _$DeviceEntityCopyWithImpl(this._self, this._then);

  final DeviceEntity _self;
  final $Res Function(DeviceEntity) _then;

/// Create a copy of DeviceEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? serial = null,Object? modelName = null,Object? status = null,Object? connectionType = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serial: null == serial ? _self.serial : serial // ignore: cast_nullable_to_non_nullable
as String,modelName: null == modelName ? _self.modelName : modelName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DeviceStatus,connectionType: null == connectionType ? _self.connectionType : connectionType // ignore: cast_nullable_to_non_nullable
as ConnectionType,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceEntity].
extension DeviceEntityPatterns on DeviceEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceEntity value)  $default,){
final _that = this;
switch (_that) {
case _DeviceEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceEntity value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String serial,  String modelName,  DeviceStatus status,  ConnectionType connectionType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceEntity() when $default != null:
return $default(_that.id,_that.serial,_that.modelName,_that.status,_that.connectionType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String serial,  String modelName,  DeviceStatus status,  ConnectionType connectionType)  $default,) {final _that = this;
switch (_that) {
case _DeviceEntity():
return $default(_that.id,_that.serial,_that.modelName,_that.status,_that.connectionType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String serial,  String modelName,  DeviceStatus status,  ConnectionType connectionType)?  $default,) {final _that = this;
switch (_that) {
case _DeviceEntity() when $default != null:
return $default(_that.id,_that.serial,_that.modelName,_that.status,_that.connectionType);case _:
  return null;

}
}

}

/// @nodoc


class _DeviceEntity implements DeviceEntity {
  const _DeviceEntity({required this.id, required this.serial, required this.modelName, required this.status, required this.connectionType});
  

@override final  String id;
@override final  String serial;
@override final  String modelName;
@override final  DeviceStatus status;
@override final  ConnectionType connectionType;

/// Create a copy of DeviceEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceEntityCopyWith<_DeviceEntity> get copyWith => __$DeviceEntityCopyWithImpl<_DeviceEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.serial, serial) || other.serial == serial)&&(identical(other.modelName, modelName) || other.modelName == modelName)&&(identical(other.status, status) || other.status == status)&&(identical(other.connectionType, connectionType) || other.connectionType == connectionType));
}


@override
int get hashCode => Object.hash(runtimeType,id,serial,modelName,status,connectionType);

@override
String toString() {
  return 'DeviceEntity(id: $id, serial: $serial, modelName: $modelName, status: $status, connectionType: $connectionType)';
}


}

/// @nodoc
abstract mixin class _$DeviceEntityCopyWith<$Res> implements $DeviceEntityCopyWith<$Res> {
  factory _$DeviceEntityCopyWith(_DeviceEntity value, $Res Function(_DeviceEntity) _then) = __$DeviceEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String serial, String modelName, DeviceStatus status, ConnectionType connectionType
});




}
/// @nodoc
class __$DeviceEntityCopyWithImpl<$Res>
    implements _$DeviceEntityCopyWith<$Res> {
  __$DeviceEntityCopyWithImpl(this._self, this._then);

  final _DeviceEntity _self;
  final $Res Function(_DeviceEntity) _then;

/// Create a copy of DeviceEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? serial = null,Object? modelName = null,Object? status = null,Object? connectionType = null,}) {
  return _then(_DeviceEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serial: null == serial ? _self.serial : serial // ignore: cast_nullable_to_non_nullable
as String,modelName: null == modelName ? _self.modelName : modelName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DeviceStatus,connectionType: null == connectionType ? _self.connectionType : connectionType // ignore: cast_nullable_to_non_nullable
as ConnectionType,
  ));
}


}

// dart format on
