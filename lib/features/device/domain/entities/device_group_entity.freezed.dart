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

 String get id; String get name; int get colorValue; List<String> get deviceSerials; Map<String, String> get deviceEmails; Map<String, String> get deviceNicknames;
/// Create a copy of DeviceGroupEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceGroupEntityCopyWith<DeviceGroupEntity> get copyWith => _$DeviceGroupEntityCopyWithImpl<DeviceGroupEntity>(this as DeviceGroupEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceGroupEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&const DeepCollectionEquality().equals(other.deviceSerials, deviceSerials)&&const DeepCollectionEquality().equals(other.deviceEmails, deviceEmails)&&const DeepCollectionEquality().equals(other.deviceNicknames, deviceNicknames));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,colorValue,const DeepCollectionEquality().hash(deviceSerials),const DeepCollectionEquality().hash(deviceEmails),const DeepCollectionEquality().hash(deviceNicknames));

@override
String toString() {
  return 'DeviceGroupEntity(id: $id, name: $name, colorValue: $colorValue, deviceSerials: $deviceSerials, deviceEmails: $deviceEmails, deviceNicknames: $deviceNicknames)';
}


}

/// @nodoc
abstract mixin class $DeviceGroupEntityCopyWith<$Res>  {
  factory $DeviceGroupEntityCopyWith(DeviceGroupEntity value, $Res Function(DeviceGroupEntity) _then) = _$DeviceGroupEntityCopyWithImpl;
@useResult
$Res call({
 String id, String name, int colorValue, List<String> deviceSerials, Map<String, String> deviceEmails, Map<String, String> deviceNicknames
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? colorValue = null,Object? deviceSerials = null,Object? deviceEmails = null,Object? deviceNicknames = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,deviceSerials: null == deviceSerials ? _self.deviceSerials : deviceSerials // ignore: cast_nullable_to_non_nullable
as List<String>,deviceEmails: null == deviceEmails ? _self.deviceEmails : deviceEmails // ignore: cast_nullable_to_non_nullable
as Map<String, String>,deviceNicknames: null == deviceNicknames ? _self.deviceNicknames : deviceNicknames // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int colorValue,  List<String> deviceSerials,  Map<String, String> deviceEmails,  Map<String, String> deviceNicknames)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceGroupEntity() when $default != null:
return $default(_that.id,_that.name,_that.colorValue,_that.deviceSerials,_that.deviceEmails,_that.deviceNicknames);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int colorValue,  List<String> deviceSerials,  Map<String, String> deviceEmails,  Map<String, String> deviceNicknames)  $default,) {final _that = this;
switch (_that) {
case _DeviceGroupEntity():
return $default(_that.id,_that.name,_that.colorValue,_that.deviceSerials,_that.deviceEmails,_that.deviceNicknames);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int colorValue,  List<String> deviceSerials,  Map<String, String> deviceEmails,  Map<String, String> deviceNicknames)?  $default,) {final _that = this;
switch (_that) {
case _DeviceGroupEntity() when $default != null:
return $default(_that.id,_that.name,_that.colorValue,_that.deviceSerials,_that.deviceEmails,_that.deviceNicknames);case _:
  return null;

}
}

}

/// @nodoc


class _DeviceGroupEntity extends DeviceGroupEntity {
  const _DeviceGroupEntity({required this.id, required this.name, required this.colorValue, required final  List<String> deviceSerials, final  Map<String, String> deviceEmails = const <String, String>{}, final  Map<String, String> deviceNicknames = const <String, String>{}}): _deviceSerials = deviceSerials,_deviceEmails = deviceEmails,_deviceNicknames = deviceNicknames,super._();
  

@override final  String id;
@override final  String name;
@override final  int colorValue;
 final  List<String> _deviceSerials;
@override List<String> get deviceSerials {
  if (_deviceSerials is EqualUnmodifiableListView) return _deviceSerials;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deviceSerials);
}

 final  Map<String, String> _deviceEmails;
@override@JsonKey() Map<String, String> get deviceEmails {
  if (_deviceEmails is EqualUnmodifiableMapView) return _deviceEmails;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_deviceEmails);
}

 final  Map<String, String> _deviceNicknames;
@override@JsonKey() Map<String, String> get deviceNicknames {
  if (_deviceNicknames is EqualUnmodifiableMapView) return _deviceNicknames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_deviceNicknames);
}


/// Create a copy of DeviceGroupEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceGroupEntityCopyWith<_DeviceGroupEntity> get copyWith => __$DeviceGroupEntityCopyWithImpl<_DeviceGroupEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceGroupEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&const DeepCollectionEquality().equals(other._deviceSerials, _deviceSerials)&&const DeepCollectionEquality().equals(other._deviceEmails, _deviceEmails)&&const DeepCollectionEquality().equals(other._deviceNicknames, _deviceNicknames));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,colorValue,const DeepCollectionEquality().hash(_deviceSerials),const DeepCollectionEquality().hash(_deviceEmails),const DeepCollectionEquality().hash(_deviceNicknames));

@override
String toString() {
  return 'DeviceGroupEntity(id: $id, name: $name, colorValue: $colorValue, deviceSerials: $deviceSerials, deviceEmails: $deviceEmails, deviceNicknames: $deviceNicknames)';
}


}

/// @nodoc
abstract mixin class _$DeviceGroupEntityCopyWith<$Res> implements $DeviceGroupEntityCopyWith<$Res> {
  factory _$DeviceGroupEntityCopyWith(_DeviceGroupEntity value, $Res Function(_DeviceGroupEntity) _then) = __$DeviceGroupEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int colorValue, List<String> deviceSerials, Map<String, String> deviceEmails, Map<String, String> deviceNicknames
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? colorValue = null,Object? deviceSerials = null,Object? deviceEmails = null,Object? deviceNicknames = null,}) {
  return _then(_DeviceGroupEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,deviceSerials: null == deviceSerials ? _self._deviceSerials : deviceSerials // ignore: cast_nullable_to_non_nullable
as List<String>,deviceEmails: null == deviceEmails ? _self._deviceEmails : deviceEmails // ignore: cast_nullable_to_non_nullable
as Map<String, String>,deviceNicknames: null == deviceNicknames ? _self._deviceNicknames : deviceNicknames // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
