// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_group_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeviceGroupEntity {

 String get id; String get name; int get colorValue; List<String> get deviceSerials;
/// Create a copy of DeviceGroupEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceGroupEntityCopyWith<DeviceGroupEntity> get copyWith => _$DeviceGroupEntityCopyWithImpl<DeviceGroupEntity>(this as DeviceGroupEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceGroupEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&const DeepCollectionEquality().equals(other.deviceSerials, deviceSerials));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,colorValue,const DeepCollectionEquality().hash(deviceSerials));

@override
String toString() {
  return 'DeviceGroupEntity(id: $id, name: $name, colorValue: $colorValue, deviceSerials: $deviceSerials)';
}


}

/// @nodoc
abstract mixin class $DeviceGroupEntityCopyWith<$Res>  {
  factory $DeviceGroupEntityCopyWith(DeviceGroupEntity value, $Res Function(DeviceGroupEntity) _then) = _$DeviceGroupEntityCopyWithImpl;
@useResult
$Res call({
 String id, String name, int colorValue, List<String> deviceSerials
});




}
/// @nodoc
class _$DeviceGroupEntityCopyWithImpl<$Res>
    implements $DeviceGroupEntityCopyWith<$Res> {
  _$DeviceGroupEntityCopyWithImpl(this._self, this._then);

  final DeviceGroupEntity _self;
  final $Res Function(DeviceGroupEntity) _then;

/// Create a copy of DeviceGroupEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? colorValue = null,Object? deviceSerials = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,deviceSerials: null == deviceSerials ? _self.deviceSerials : deviceSerials // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceGroupEntity].
extension DeviceGroupEntityPatterns on DeviceGroupEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceGroupEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceGroupEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceGroupEntity value)  $default,){
final _that = this;
switch (_that) {
case _DeviceGroupEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceGroupEntity value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceGroupEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int colorValue,  List<String> deviceSerials)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceGroupEntity() when $default != null:
return $default(_that.id,_that.name,_that.colorValue,_that.deviceSerials);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int colorValue,  List<String> deviceSerials)  $default,) {final _that = this;
switch (_that) {
case _DeviceGroupEntity():
return $default(_that.id,_that.name,_that.colorValue,_that.deviceSerials);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int colorValue,  List<String> deviceSerials)?  $default,) {final _that = this;
switch (_that) {
case _DeviceGroupEntity() when $default != null:
return $default(_that.id,_that.name,_that.colorValue,_that.deviceSerials);case _:
  return null;

}
}

}

/// @nodoc


class _DeviceGroupEntity extends DeviceGroupEntity {
  const _DeviceGroupEntity({required this.id, required this.name, required this.colorValue, required final  List<String> deviceSerials}): _deviceSerials = deviceSerials,super._();
  

@override final  String id;
@override final  String name;
@override final  int colorValue;
 final  List<String> _deviceSerials;
@override List<String> get deviceSerials {
  if (_deviceSerials is EqualUnmodifiableListView) return _deviceSerials;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deviceSerials);
}


/// Create a copy of DeviceGroupEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceGroupEntityCopyWith<_DeviceGroupEntity> get copyWith => __$DeviceGroupEntityCopyWithImpl<_DeviceGroupEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceGroupEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&const DeepCollectionEquality().equals(other._deviceSerials, _deviceSerials));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,colorValue,const DeepCollectionEquality().hash(_deviceSerials));

@override
String toString() {
  return 'DeviceGroupEntity(id: $id, name: $name, colorValue: $colorValue, deviceSerials: $deviceSerials)';
}


}

/// @nodoc
abstract mixin class _$DeviceGroupEntityCopyWith<$Res> implements $DeviceGroupEntityCopyWith<$Res> {
  factory _$DeviceGroupEntityCopyWith(_DeviceGroupEntity value, $Res Function(_DeviceGroupEntity) _then) = __$DeviceGroupEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int colorValue, List<String> deviceSerials
});




}
/// @nodoc
class __$DeviceGroupEntityCopyWithImpl<$Res>
    implements _$DeviceGroupEntityCopyWith<$Res> {
  __$DeviceGroupEntityCopyWithImpl(this._self, this._then);

  final _DeviceGroupEntity _self;
  final $Res Function(_DeviceGroupEntity) _then;

/// Create a copy of DeviceGroupEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? colorValue = null,Object? deviceSerials = null,}) {
  return _then(_DeviceGroupEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,deviceSerials: null == deviceSerials ? _self._deviceSerials : deviceSerials // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
