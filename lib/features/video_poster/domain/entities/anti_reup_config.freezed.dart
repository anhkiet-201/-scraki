// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'anti_reup_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AntiReupConfig _$AntiReupConfigFromJson(Map<String, dynamic> json) {
  return _AntiReupConfig.fromJson(json);
}

/// @nodoc
mixin _$AntiReupConfig {
  /// Whether parameters should be randomized within safe ranges
  bool get isRandomized => throw _privateConstructorUsedError;

  /// Playback speed multiplier (e.g., 1.05 = 5% faster)
  /// Range: 1.0 - 1.15
  double get speedMultiplier => throw _privateConstructorUsedError;

  /// Enable visual noise generation
  bool get enableVisualNoise => throw _privateConstructorUsedError;

  /// Intensity of visual noise (0.0 - 1.0)
  /// Recommended range: 0.03 - 0.1
  double get noiseLevel => throw _privateConstructorUsedError;

  /// Intensity of color shifting (Saturation/Contrast/Brightness)
  /// Range: 0.0 - 1.0
  double get colorShiftIntensity => throw _privateConstructorUsedError;

  /// Whether to shift audio pitch to match speed change
  /// (Usually recommended to be TRUE to avoid chipmunk effect if speed is high,
  /// but for small changes, maintaining pitch is better)
  /// actually for anti-detection, changing pitch slightly is better.
  bool get enableAudioPitchShift => throw _privateConstructorUsedError;

  /// Whether to strip all metadata from the source file
  bool get stripMetadata => throw _privateConstructorUsedError;

  /// Serializes this AntiReupConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AntiReupConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AntiReupConfigCopyWith<AntiReupConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AntiReupConfigCopyWith<$Res> {
  factory $AntiReupConfigCopyWith(
    AntiReupConfig value,
    $Res Function(AntiReupConfig) then,
  ) = _$AntiReupConfigCopyWithImpl<$Res, AntiReupConfig>;
  @useResult
  $Res call({
    bool isRandomized,
    double speedMultiplier,
    bool enableVisualNoise,
    double noiseLevel,
    double colorShiftIntensity,
    bool enableAudioPitchShift,
    bool stripMetadata,
  });
}

/// @nodoc
class _$AntiReupConfigCopyWithImpl<$Res, $Val extends AntiReupConfig>
    implements $AntiReupConfigCopyWith<$Res> {
  _$AntiReupConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AntiReupConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isRandomized = null,
    Object? speedMultiplier = null,
    Object? enableVisualNoise = null,
    Object? noiseLevel = null,
    Object? colorShiftIntensity = null,
    Object? enableAudioPitchShift = null,
    Object? stripMetadata = null,
  }) {
    return _then(
      _value.copyWith(
            isRandomized: null == isRandomized
                ? _value.isRandomized
                : isRandomized // ignore: cast_nullable_to_non_nullable
                      as bool,
            speedMultiplier: null == speedMultiplier
                ? _value.speedMultiplier
                : speedMultiplier // ignore: cast_nullable_to_non_nullable
                      as double,
            enableVisualNoise: null == enableVisualNoise
                ? _value.enableVisualNoise
                : enableVisualNoise // ignore: cast_nullable_to_non_nullable
                      as bool,
            noiseLevel: null == noiseLevel
                ? _value.noiseLevel
                : noiseLevel // ignore: cast_nullable_to_non_nullable
                      as double,
            colorShiftIntensity: null == colorShiftIntensity
                ? _value.colorShiftIntensity
                : colorShiftIntensity // ignore: cast_nullable_to_non_nullable
                      as double,
            enableAudioPitchShift: null == enableAudioPitchShift
                ? _value.enableAudioPitchShift
                : enableAudioPitchShift // ignore: cast_nullable_to_non_nullable
                      as bool,
            stripMetadata: null == stripMetadata
                ? _value.stripMetadata
                : stripMetadata // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AntiReupConfigImplCopyWith<$Res>
    implements $AntiReupConfigCopyWith<$Res> {
  factory _$$AntiReupConfigImplCopyWith(
    _$AntiReupConfigImpl value,
    $Res Function(_$AntiReupConfigImpl) then,
  ) = __$$AntiReupConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isRandomized,
    double speedMultiplier,
    bool enableVisualNoise,
    double noiseLevel,
    double colorShiftIntensity,
    bool enableAudioPitchShift,
    bool stripMetadata,
  });
}

/// @nodoc
class __$$AntiReupConfigImplCopyWithImpl<$Res>
    extends _$AntiReupConfigCopyWithImpl<$Res, _$AntiReupConfigImpl>
    implements _$$AntiReupConfigImplCopyWith<$Res> {
  __$$AntiReupConfigImplCopyWithImpl(
    _$AntiReupConfigImpl _value,
    $Res Function(_$AntiReupConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AntiReupConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isRandomized = null,
    Object? speedMultiplier = null,
    Object? enableVisualNoise = null,
    Object? noiseLevel = null,
    Object? colorShiftIntensity = null,
    Object? enableAudioPitchShift = null,
    Object? stripMetadata = null,
  }) {
    return _then(
      _$AntiReupConfigImpl(
        isRandomized: null == isRandomized
            ? _value.isRandomized
            : isRandomized // ignore: cast_nullable_to_non_nullable
                  as bool,
        speedMultiplier: null == speedMultiplier
            ? _value.speedMultiplier
            : speedMultiplier // ignore: cast_nullable_to_non_nullable
                  as double,
        enableVisualNoise: null == enableVisualNoise
            ? _value.enableVisualNoise
            : enableVisualNoise // ignore: cast_nullable_to_non_nullable
                  as bool,
        noiseLevel: null == noiseLevel
            ? _value.noiseLevel
            : noiseLevel // ignore: cast_nullable_to_non_nullable
                  as double,
        colorShiftIntensity: null == colorShiftIntensity
            ? _value.colorShiftIntensity
            : colorShiftIntensity // ignore: cast_nullable_to_non_nullable
                  as double,
        enableAudioPitchShift: null == enableAudioPitchShift
            ? _value.enableAudioPitchShift
            : enableAudioPitchShift // ignore: cast_nullable_to_non_nullable
                  as bool,
        stripMetadata: null == stripMetadata
            ? _value.stripMetadata
            : stripMetadata // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AntiReupConfigImpl implements _AntiReupConfig {
  const _$AntiReupConfigImpl({
    this.isRandomized = true,
    this.speedMultiplier = 1.05,
    this.enableVisualNoise = true,
    this.noiseLevel = 0.05,
    this.colorShiftIntensity = 0.05,
    this.enableAudioPitchShift = true,
    this.stripMetadata = true,
  });

  factory _$AntiReupConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$AntiReupConfigImplFromJson(json);

  /// Whether parameters should be randomized within safe ranges
  @override
  @JsonKey()
  final bool isRandomized;

  /// Playback speed multiplier (e.g., 1.05 = 5% faster)
  /// Range: 1.0 - 1.15
  @override
  @JsonKey()
  final double speedMultiplier;

  /// Enable visual noise generation
  @override
  @JsonKey()
  final bool enableVisualNoise;

  /// Intensity of visual noise (0.0 - 1.0)
  /// Recommended range: 0.03 - 0.1
  @override
  @JsonKey()
  final double noiseLevel;

  /// Intensity of color shifting (Saturation/Contrast/Brightness)
  /// Range: 0.0 - 1.0
  @override
  @JsonKey()
  final double colorShiftIntensity;

  /// Whether to shift audio pitch to match speed change
  /// (Usually recommended to be TRUE to avoid chipmunk effect if speed is high,
  /// but for small changes, maintaining pitch is better)
  /// actually for anti-detection, changing pitch slightly is better.
  @override
  @JsonKey()
  final bool enableAudioPitchShift;

  /// Whether to strip all metadata from the source file
  @override
  @JsonKey()
  final bool stripMetadata;

  @override
  String toString() {
    return 'AntiReupConfig(isRandomized: $isRandomized, speedMultiplier: $speedMultiplier, enableVisualNoise: $enableVisualNoise, noiseLevel: $noiseLevel, colorShiftIntensity: $colorShiftIntensity, enableAudioPitchShift: $enableAudioPitchShift, stripMetadata: $stripMetadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AntiReupConfigImpl &&
            (identical(other.isRandomized, isRandomized) ||
                other.isRandomized == isRandomized) &&
            (identical(other.speedMultiplier, speedMultiplier) ||
                other.speedMultiplier == speedMultiplier) &&
            (identical(other.enableVisualNoise, enableVisualNoise) ||
                other.enableVisualNoise == enableVisualNoise) &&
            (identical(other.noiseLevel, noiseLevel) ||
                other.noiseLevel == noiseLevel) &&
            (identical(other.colorShiftIntensity, colorShiftIntensity) ||
                other.colorShiftIntensity == colorShiftIntensity) &&
            (identical(other.enableAudioPitchShift, enableAudioPitchShift) ||
                other.enableAudioPitchShift == enableAudioPitchShift) &&
            (identical(other.stripMetadata, stripMetadata) ||
                other.stripMetadata == stripMetadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    isRandomized,
    speedMultiplier,
    enableVisualNoise,
    noiseLevel,
    colorShiftIntensity,
    enableAudioPitchShift,
    stripMetadata,
  );

  /// Create a copy of AntiReupConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AntiReupConfigImplCopyWith<_$AntiReupConfigImpl> get copyWith =>
      __$$AntiReupConfigImplCopyWithImpl<_$AntiReupConfigImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AntiReupConfigImplToJson(this);
  }
}

abstract class _AntiReupConfig implements AntiReupConfig {
  const factory _AntiReupConfig({
    final bool isRandomized,
    final double speedMultiplier,
    final bool enableVisualNoise,
    final double noiseLevel,
    final double colorShiftIntensity,
    final bool enableAudioPitchShift,
    final bool stripMetadata,
  }) = _$AntiReupConfigImpl;

  factory _AntiReupConfig.fromJson(Map<String, dynamic> json) =
      _$AntiReupConfigImpl.fromJson;

  /// Whether parameters should be randomized within safe ranges
  @override
  bool get isRandomized;

  /// Playback speed multiplier (e.g., 1.05 = 5% faster)
  /// Range: 1.0 - 1.15
  @override
  double get speedMultiplier;

  /// Enable visual noise generation
  @override
  bool get enableVisualNoise;

  /// Intensity of visual noise (0.0 - 1.0)
  /// Recommended range: 0.03 - 0.1
  @override
  double get noiseLevel;

  /// Intensity of color shifting (Saturation/Contrast/Brightness)
  /// Range: 0.0 - 1.0
  @override
  double get colorShiftIntensity;

  /// Whether to shift audio pitch to match speed change
  /// (Usually recommended to be TRUE to avoid chipmunk effect if speed is high,
  /// but for small changes, maintaining pitch is better)
  /// actually for anti-detection, changing pitch slightly is better.
  @override
  bool get enableAudioPitchShift;

  /// Whether to strip all metadata from the source file
  @override
  bool get stripMetadata;

  /// Create a copy of AntiReupConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AntiReupConfigImplCopyWith<_$AntiReupConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
