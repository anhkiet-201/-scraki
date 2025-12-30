// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scrcpy_options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ScrcpyOptions {
  int get maxSize => throw _privateConstructorUsedError; // 0 means no limit
  int get bitRate => throw _privateConstructorUsedError; // 8Mbps
  int get maxFps => throw _privateConstructorUsedError;
  bool get stayAwake => throw _privateConstructorUsedError;

  /// Create a copy of ScrcpyOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScrcpyOptionsCopyWith<ScrcpyOptions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScrcpyOptionsCopyWith<$Res> {
  factory $ScrcpyOptionsCopyWith(
    ScrcpyOptions value,
    $Res Function(ScrcpyOptions) then,
  ) = _$ScrcpyOptionsCopyWithImpl<$Res, ScrcpyOptions>;
  @useResult
  $Res call({int maxSize, int bitRate, int maxFps, bool stayAwake});
}

/// @nodoc
class _$ScrcpyOptionsCopyWithImpl<$Res, $Val extends ScrcpyOptions>
    implements $ScrcpyOptionsCopyWith<$Res> {
  _$ScrcpyOptionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScrcpyOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxSize = null,
    Object? bitRate = null,
    Object? maxFps = null,
    Object? stayAwake = null,
  }) {
    return _then(
      _value.copyWith(
            maxSize: null == maxSize
                ? _value.maxSize
                : maxSize // ignore: cast_nullable_to_non_nullable
                      as int,
            bitRate: null == bitRate
                ? _value.bitRate
                : bitRate // ignore: cast_nullable_to_non_nullable
                      as int,
            maxFps: null == maxFps
                ? _value.maxFps
                : maxFps // ignore: cast_nullable_to_non_nullable
                      as int,
            stayAwake: null == stayAwake
                ? _value.stayAwake
                : stayAwake // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ScrcpyOptionsImplCopyWith<$Res>
    implements $ScrcpyOptionsCopyWith<$Res> {
  factory _$$ScrcpyOptionsImplCopyWith(
    _$ScrcpyOptionsImpl value,
    $Res Function(_$ScrcpyOptionsImpl) then,
  ) = __$$ScrcpyOptionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int maxSize, int bitRate, int maxFps, bool stayAwake});
}

/// @nodoc
class __$$ScrcpyOptionsImplCopyWithImpl<$Res>
    extends _$ScrcpyOptionsCopyWithImpl<$Res, _$ScrcpyOptionsImpl>
    implements _$$ScrcpyOptionsImplCopyWith<$Res> {
  __$$ScrcpyOptionsImplCopyWithImpl(
    _$ScrcpyOptionsImpl _value,
    $Res Function(_$ScrcpyOptionsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ScrcpyOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxSize = null,
    Object? bitRate = null,
    Object? maxFps = null,
    Object? stayAwake = null,
  }) {
    return _then(
      _$ScrcpyOptionsImpl(
        maxSize: null == maxSize
            ? _value.maxSize
            : maxSize // ignore: cast_nullable_to_non_nullable
                  as int,
        bitRate: null == bitRate
            ? _value.bitRate
            : bitRate // ignore: cast_nullable_to_non_nullable
                  as int,
        maxFps: null == maxFps
            ? _value.maxFps
            : maxFps // ignore: cast_nullable_to_non_nullable
                  as int,
        stayAwake: null == stayAwake
            ? _value.stayAwake
            : stayAwake // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$ScrcpyOptionsImpl implements _ScrcpyOptions {
  const _$ScrcpyOptionsImpl({
    this.maxSize = 0,
    this.bitRate = 8000000,
    this.maxFps = 60,
    this.stayAwake = false,
  });

  @override
  @JsonKey()
  final int maxSize;
  // 0 means no limit
  @override
  @JsonKey()
  final int bitRate;
  // 8Mbps
  @override
  @JsonKey()
  final int maxFps;
  @override
  @JsonKey()
  final bool stayAwake;

  @override
  String toString() {
    return 'ScrcpyOptions(maxSize: $maxSize, bitRate: $bitRate, maxFps: $maxFps, stayAwake: $stayAwake)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScrcpyOptionsImpl &&
            (identical(other.maxSize, maxSize) || other.maxSize == maxSize) &&
            (identical(other.bitRate, bitRate) || other.bitRate == bitRate) &&
            (identical(other.maxFps, maxFps) || other.maxFps == maxFps) &&
            (identical(other.stayAwake, stayAwake) ||
                other.stayAwake == stayAwake));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, maxSize, bitRate, maxFps, stayAwake);

  /// Create a copy of ScrcpyOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScrcpyOptionsImplCopyWith<_$ScrcpyOptionsImpl> get copyWith =>
      __$$ScrcpyOptionsImplCopyWithImpl<_$ScrcpyOptionsImpl>(this, _$identity);
}

abstract class _ScrcpyOptions implements ScrcpyOptions {
  const factory _ScrcpyOptions({
    final int maxSize,
    final int bitRate,
    final int maxFps,
    final bool stayAwake,
  }) = _$ScrcpyOptionsImpl;

  @override
  int get maxSize; // 0 means no limit
  @override
  int get bitRate; // 8Mbps
  @override
  int get maxFps;
  @override
  bool get stayAwake;

  /// Create a copy of ScrcpyOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScrcpyOptionsImplCopyWith<_$ScrcpyOptionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
