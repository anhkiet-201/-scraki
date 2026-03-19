// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_nickname_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DeviceNicknameEntity {
  Map<String, String> get nicknames => throw _privateConstructorUsedError;

  /// Create a copy of DeviceNicknameEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeviceNicknameEntityCopyWith<DeviceNicknameEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceNicknameEntityCopyWith<$Res> {
  factory $DeviceNicknameEntityCopyWith(
    DeviceNicknameEntity value,
    $Res Function(DeviceNicknameEntity) then,
  ) = _$DeviceNicknameEntityCopyWithImpl<$Res, DeviceNicknameEntity>;
  @useResult
  $Res call({Map<String, String> nicknames});
}

/// @nodoc
class _$DeviceNicknameEntityCopyWithImpl<
  $Res,
  $Val extends DeviceNicknameEntity
>
    implements $DeviceNicknameEntityCopyWith<$Res> {
  _$DeviceNicknameEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeviceNicknameEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? nicknames = null}) {
    return _then(
      _value.copyWith(
            nicknames: null == nicknames
                ? _value.nicknames
                : nicknames // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeviceNicknameEntityImplCopyWith<$Res>
    implements $DeviceNicknameEntityCopyWith<$Res> {
  factory _$$DeviceNicknameEntityImplCopyWith(
    _$DeviceNicknameEntityImpl value,
    $Res Function(_$DeviceNicknameEntityImpl) then,
  ) = __$$DeviceNicknameEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, String> nicknames});
}

/// @nodoc
class __$$DeviceNicknameEntityImplCopyWithImpl<$Res>
    extends _$DeviceNicknameEntityCopyWithImpl<$Res, _$DeviceNicknameEntityImpl>
    implements _$$DeviceNicknameEntityImplCopyWith<$Res> {
  __$$DeviceNicknameEntityImplCopyWithImpl(
    _$DeviceNicknameEntityImpl _value,
    $Res Function(_$DeviceNicknameEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeviceNicknameEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? nicknames = null}) {
    return _then(
      _$DeviceNicknameEntityImpl(
        nicknames: null == nicknames
            ? _value._nicknames
            : nicknames // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
      ),
    );
  }
}

/// @nodoc

class _$DeviceNicknameEntityImpl extends _DeviceNicknameEntity {
  const _$DeviceNicknameEntityImpl({
    final Map<String, String> nicknames = const {},
  }) : _nicknames = nicknames,
       super._();

  final Map<String, String> _nicknames;
  @override
  @JsonKey()
  Map<String, String> get nicknames {
    if (_nicknames is EqualUnmodifiableMapView) return _nicknames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_nicknames);
  }

  @override
  String toString() {
    return 'DeviceNicknameEntity(nicknames: $nicknames)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceNicknameEntityImpl &&
            const DeepCollectionEquality().equals(
              other._nicknames,
              _nicknames,
            ));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_nicknames));

  /// Create a copy of DeviceNicknameEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceNicknameEntityImplCopyWith<_$DeviceNicknameEntityImpl>
  get copyWith =>
      __$$DeviceNicknameEntityImplCopyWithImpl<_$DeviceNicknameEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _DeviceNicknameEntity extends DeviceNicknameEntity {
  const factory _DeviceNicknameEntity({final Map<String, String> nicknames}) =
      _$DeviceNicknameEntityImpl;
  const _DeviceNicknameEntity._() : super._();

  @override
  Map<String, String> get nicknames;

  /// Create a copy of DeviceNicknameEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeviceNicknameEntityImplCopyWith<_$DeviceNicknameEntityImpl>
  get copyWith => throw _privateConstructorUsedError;
}
