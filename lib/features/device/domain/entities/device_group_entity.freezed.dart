// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_group_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DeviceGroupEntity {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get colorValue => throw _privateConstructorUsedError;
  List<String> get deviceSerials => throw _privateConstructorUsedError;

  /// Create a copy of DeviceGroupEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeviceGroupEntityCopyWith<DeviceGroupEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceGroupEntityCopyWith<$Res> {
  factory $DeviceGroupEntityCopyWith(
    DeviceGroupEntity value,
    $Res Function(DeviceGroupEntity) then,
  ) = _$DeviceGroupEntityCopyWithImpl<$Res, DeviceGroupEntity>;
  @useResult
  $Res call({
    String id,
    String name,
    int colorValue,
    List<String> deviceSerials,
  });
}

/// @nodoc
class _$DeviceGroupEntityCopyWithImpl<$Res, $Val extends DeviceGroupEntity>
    implements $DeviceGroupEntityCopyWith<$Res> {
  _$DeviceGroupEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeviceGroupEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? colorValue = null,
    Object? deviceSerials = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            colorValue: null == colorValue
                ? _value.colorValue
                : colorValue // ignore: cast_nullable_to_non_nullable
                      as int,
            deviceSerials: null == deviceSerials
                ? _value.deviceSerials
                : deviceSerials // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeviceGroupEntityImplCopyWith<$Res>
    implements $DeviceGroupEntityCopyWith<$Res> {
  factory _$$DeviceGroupEntityImplCopyWith(
    _$DeviceGroupEntityImpl value,
    $Res Function(_$DeviceGroupEntityImpl) then,
  ) = __$$DeviceGroupEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    int colorValue,
    List<String> deviceSerials,
  });
}

/// @nodoc
class __$$DeviceGroupEntityImplCopyWithImpl<$Res>
    extends _$DeviceGroupEntityCopyWithImpl<$Res, _$DeviceGroupEntityImpl>
    implements _$$DeviceGroupEntityImplCopyWith<$Res> {
  __$$DeviceGroupEntityImplCopyWithImpl(
    _$DeviceGroupEntityImpl _value,
    $Res Function(_$DeviceGroupEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeviceGroupEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? colorValue = null,
    Object? deviceSerials = null,
  }) {
    return _then(
      _$DeviceGroupEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        colorValue: null == colorValue
            ? _value.colorValue
            : colorValue // ignore: cast_nullable_to_non_nullable
                  as int,
        deviceSerials: null == deviceSerials
            ? _value._deviceSerials
            : deviceSerials // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc

class _$DeviceGroupEntityImpl extends _DeviceGroupEntity {
  const _$DeviceGroupEntityImpl({
    required this.id,
    required this.name,
    required this.colorValue,
    required final List<String> deviceSerials,
  }) : _deviceSerials = deviceSerials,
       super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final int colorValue;
  final List<String> _deviceSerials;
  @override
  List<String> get deviceSerials {
    if (_deviceSerials is EqualUnmodifiableListView) return _deviceSerials;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_deviceSerials);
  }

  @override
  String toString() {
    return 'DeviceGroupEntity(id: $id, name: $name, colorValue: $colorValue, deviceSerials: $deviceSerials)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceGroupEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.colorValue, colorValue) ||
                other.colorValue == colorValue) &&
            const DeepCollectionEquality().equals(
              other._deviceSerials,
              _deviceSerials,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    colorValue,
    const DeepCollectionEquality().hash(_deviceSerials),
  );

  /// Create a copy of DeviceGroupEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceGroupEntityImplCopyWith<_$DeviceGroupEntityImpl> get copyWith =>
      __$$DeviceGroupEntityImplCopyWithImpl<_$DeviceGroupEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _DeviceGroupEntity extends DeviceGroupEntity {
  const factory _DeviceGroupEntity({
    required final String id,
    required final String name,
    required final int colorValue,
    required final List<String> deviceSerials,
  }) = _$DeviceGroupEntityImpl;
  const _DeviceGroupEntity._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  int get colorValue;
  @override
  List<String> get deviceSerials;

  /// Create a copy of DeviceGroupEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeviceGroupEntityImplCopyWith<_$DeviceGroupEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
