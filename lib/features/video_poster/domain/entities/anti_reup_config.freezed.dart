// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'anti_reup_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AntiReupConfig {

/// Whether parameters should be randomized within safe ranges
 bool get isRandomized;/// Playback speed multiplier (e.g., 1.05 = 5% faster)
/// Range: 1.0 - 1.15
 double get speedMultiplier;/// Enable visual noise generation
 bool get enableVisualNoise;/// Intensity of visual noise (0.0 - 1.0)
/// Recommended range: 0.03 - 0.1
 double get noiseLevel;/// Intensity of color shifting (Saturation/Contrast/Brightness)
/// Range: 0.0 - 1.0
 double get colorShiftIntensity;/// Whether to shift audio pitch to match speed change
/// (Usually recommended to be TRUE to avoid chipmunk effect if speed is high,
/// but for small changes, maintaining pitch is better)
/// actually for anti-detection, changing pitch slightly is better.
 bool get enableAudioPitchShift;/// Whether to strip all metadata from the source file
 bool get stripMetadata;/// Force output duration directly (in seconds).
/// If null, duration is determined by source video * speedMultiplier.
/// If set, video will be trimmed or looped to match this duration.
 double? get targetDuration;
/// Create a copy of AntiReupConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AntiReupConfigCopyWith<AntiReupConfig> get copyWith => _$AntiReupConfigCopyWithImpl<AntiReupConfig>(this as AntiReupConfig, _$identity);

  /// Serializes this AntiReupConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AntiReupConfig&&(identical(other.isRandomized, isRandomized) || other.isRandomized == isRandomized)&&(identical(other.speedMultiplier, speedMultiplier) || other.speedMultiplier == speedMultiplier)&&(identical(other.enableVisualNoise, enableVisualNoise) || other.enableVisualNoise == enableVisualNoise)&&(identical(other.noiseLevel, noiseLevel) || other.noiseLevel == noiseLevel)&&(identical(other.colorShiftIntensity, colorShiftIntensity) || other.colorShiftIntensity == colorShiftIntensity)&&(identical(other.enableAudioPitchShift, enableAudioPitchShift) || other.enableAudioPitchShift == enableAudioPitchShift)&&(identical(other.stripMetadata, stripMetadata) || other.stripMetadata == stripMetadata)&&(identical(other.targetDuration, targetDuration) || other.targetDuration == targetDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isRandomized,speedMultiplier,enableVisualNoise,noiseLevel,colorShiftIntensity,enableAudioPitchShift,stripMetadata,targetDuration);

@override
String toString() {
  return 'AntiReupConfig(isRandomized: $isRandomized, speedMultiplier: $speedMultiplier, enableVisualNoise: $enableVisualNoise, noiseLevel: $noiseLevel, colorShiftIntensity: $colorShiftIntensity, enableAudioPitchShift: $enableAudioPitchShift, stripMetadata: $stripMetadata, targetDuration: $targetDuration)';
}


}

/// @nodoc
abstract mixin class $AntiReupConfigCopyWith<$Res>  {
  factory $AntiReupConfigCopyWith(AntiReupConfig value, $Res Function(AntiReupConfig) _then) = _$AntiReupConfigCopyWithImpl;
@useResult
$Res call({
 bool isRandomized, double speedMultiplier, bool enableVisualNoise, double noiseLevel, double colorShiftIntensity, bool enableAudioPitchShift, bool stripMetadata, double? targetDuration
});




}
/// @nodoc
class _$AntiReupConfigCopyWithImpl<$Res>
    implements $AntiReupConfigCopyWith<$Res> {
  _$AntiReupConfigCopyWithImpl(this._self, this._then);

  final AntiReupConfig _self;
  final $Res Function(AntiReupConfig) _then;

/// Create a copy of AntiReupConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isRandomized = null,Object? speedMultiplier = null,Object? enableVisualNoise = null,Object? noiseLevel = null,Object? colorShiftIntensity = null,Object? enableAudioPitchShift = null,Object? stripMetadata = null,Object? targetDuration = freezed,}) {
  return _then(_self.copyWith(
isRandomized: null == isRandomized ? _self.isRandomized : isRandomized // ignore: cast_nullable_to_non_nullable
as bool,speedMultiplier: null == speedMultiplier ? _self.speedMultiplier : speedMultiplier // ignore: cast_nullable_to_non_nullable
as double,enableVisualNoise: null == enableVisualNoise ? _self.enableVisualNoise : enableVisualNoise // ignore: cast_nullable_to_non_nullable
as bool,noiseLevel: null == noiseLevel ? _self.noiseLevel : noiseLevel // ignore: cast_nullable_to_non_nullable
as double,colorShiftIntensity: null == colorShiftIntensity ? _self.colorShiftIntensity : colorShiftIntensity // ignore: cast_nullable_to_non_nullable
as double,enableAudioPitchShift: null == enableAudioPitchShift ? _self.enableAudioPitchShift : enableAudioPitchShift // ignore: cast_nullable_to_non_nullable
as bool,stripMetadata: null == stripMetadata ? _self.stripMetadata : stripMetadata // ignore: cast_nullable_to_non_nullable
as bool,targetDuration: freezed == targetDuration ? _self.targetDuration : targetDuration // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [AntiReupConfig].
extension AntiReupConfigPatterns on AntiReupConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AntiReupConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AntiReupConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AntiReupConfig value)  $default,){
final _that = this;
switch (_that) {
case _AntiReupConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AntiReupConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AntiReupConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isRandomized,  double speedMultiplier,  bool enableVisualNoise,  double noiseLevel,  double colorShiftIntensity,  bool enableAudioPitchShift,  bool stripMetadata,  double? targetDuration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AntiReupConfig() when $default != null:
return $default(_that.isRandomized,_that.speedMultiplier,_that.enableVisualNoise,_that.noiseLevel,_that.colorShiftIntensity,_that.enableAudioPitchShift,_that.stripMetadata,_that.targetDuration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isRandomized,  double speedMultiplier,  bool enableVisualNoise,  double noiseLevel,  double colorShiftIntensity,  bool enableAudioPitchShift,  bool stripMetadata,  double? targetDuration)  $default,) {final _that = this;
switch (_that) {
case _AntiReupConfig():
return $default(_that.isRandomized,_that.speedMultiplier,_that.enableVisualNoise,_that.noiseLevel,_that.colorShiftIntensity,_that.enableAudioPitchShift,_that.stripMetadata,_that.targetDuration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isRandomized,  double speedMultiplier,  bool enableVisualNoise,  double noiseLevel,  double colorShiftIntensity,  bool enableAudioPitchShift,  bool stripMetadata,  double? targetDuration)?  $default,) {final _that = this;
switch (_that) {
case _AntiReupConfig() when $default != null:
return $default(_that.isRandomized,_that.speedMultiplier,_that.enableVisualNoise,_that.noiseLevel,_that.colorShiftIntensity,_that.enableAudioPitchShift,_that.stripMetadata,_that.targetDuration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AntiReupConfig implements AntiReupConfig {
  const _AntiReupConfig({this.isRandomized = true, this.speedMultiplier = 1.05, this.enableVisualNoise = true, this.noiseLevel = 0.05, this.colorShiftIntensity = 0.05, this.enableAudioPitchShift = true, this.stripMetadata = true, this.targetDuration});
  factory _AntiReupConfig.fromJson(Map<String, dynamic> json) => _$AntiReupConfigFromJson(json);

/// Whether parameters should be randomized within safe ranges
@override@JsonKey() final  bool isRandomized;
/// Playback speed multiplier (e.g., 1.05 = 5% faster)
/// Range: 1.0 - 1.15
@override@JsonKey() final  double speedMultiplier;
/// Enable visual noise generation
@override@JsonKey() final  bool enableVisualNoise;
/// Intensity of visual noise (0.0 - 1.0)
/// Recommended range: 0.03 - 0.1
@override@JsonKey() final  double noiseLevel;
/// Intensity of color shifting (Saturation/Contrast/Brightness)
/// Range: 0.0 - 1.0
@override@JsonKey() final  double colorShiftIntensity;
/// Whether to shift audio pitch to match speed change
/// (Usually recommended to be TRUE to avoid chipmunk effect if speed is high,
/// but for small changes, maintaining pitch is better)
/// actually for anti-detection, changing pitch slightly is better.
@override@JsonKey() final  bool enableAudioPitchShift;
/// Whether to strip all metadata from the source file
@override@JsonKey() final  bool stripMetadata;
/// Force output duration directly (in seconds).
/// If null, duration is determined by source video * speedMultiplier.
/// If set, video will be trimmed or looped to match this duration.
@override final  double? targetDuration;

/// Create a copy of AntiReupConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AntiReupConfigCopyWith<_AntiReupConfig> get copyWith => __$AntiReupConfigCopyWithImpl<_AntiReupConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AntiReupConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AntiReupConfig&&(identical(other.isRandomized, isRandomized) || other.isRandomized == isRandomized)&&(identical(other.speedMultiplier, speedMultiplier) || other.speedMultiplier == speedMultiplier)&&(identical(other.enableVisualNoise, enableVisualNoise) || other.enableVisualNoise == enableVisualNoise)&&(identical(other.noiseLevel, noiseLevel) || other.noiseLevel == noiseLevel)&&(identical(other.colorShiftIntensity, colorShiftIntensity) || other.colorShiftIntensity == colorShiftIntensity)&&(identical(other.enableAudioPitchShift, enableAudioPitchShift) || other.enableAudioPitchShift == enableAudioPitchShift)&&(identical(other.stripMetadata, stripMetadata) || other.stripMetadata == stripMetadata)&&(identical(other.targetDuration, targetDuration) || other.targetDuration == targetDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isRandomized,speedMultiplier,enableVisualNoise,noiseLevel,colorShiftIntensity,enableAudioPitchShift,stripMetadata,targetDuration);

@override
String toString() {
  return 'AntiReupConfig(isRandomized: $isRandomized, speedMultiplier: $speedMultiplier, enableVisualNoise: $enableVisualNoise, noiseLevel: $noiseLevel, colorShiftIntensity: $colorShiftIntensity, enableAudioPitchShift: $enableAudioPitchShift, stripMetadata: $stripMetadata, targetDuration: $targetDuration)';
}


}

/// @nodoc
abstract mixin class _$AntiReupConfigCopyWith<$Res> implements $AntiReupConfigCopyWith<$Res> {
  factory _$AntiReupConfigCopyWith(_AntiReupConfig value, $Res Function(_AntiReupConfig) _then) = __$AntiReupConfigCopyWithImpl;
@override @useResult
$Res call({
 bool isRandomized, double speedMultiplier, bool enableVisualNoise, double noiseLevel, double colorShiftIntensity, bool enableAudioPitchShift, bool stripMetadata, double? targetDuration
});




}
/// @nodoc
class __$AntiReupConfigCopyWithImpl<$Res>
    implements _$AntiReupConfigCopyWith<$Res> {
  __$AntiReupConfigCopyWithImpl(this._self, this._then);

  final _AntiReupConfig _self;
  final $Res Function(_AntiReupConfig) _then;

/// Create a copy of AntiReupConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isRandomized = null,Object? speedMultiplier = null,Object? enableVisualNoise = null,Object? noiseLevel = null,Object? colorShiftIntensity = null,Object? enableAudioPitchShift = null,Object? stripMetadata = null,Object? targetDuration = freezed,}) {
  return _then(_AntiReupConfig(
isRandomized: null == isRandomized ? _self.isRandomized : isRandomized // ignore: cast_nullable_to_non_nullable
as bool,speedMultiplier: null == speedMultiplier ? _self.speedMultiplier : speedMultiplier // ignore: cast_nullable_to_non_nullable
as double,enableVisualNoise: null == enableVisualNoise ? _self.enableVisualNoise : enableVisualNoise // ignore: cast_nullable_to_non_nullable
as bool,noiseLevel: null == noiseLevel ? _self.noiseLevel : noiseLevel // ignore: cast_nullable_to_non_nullable
as double,colorShiftIntensity: null == colorShiftIntensity ? _self.colorShiftIntensity : colorShiftIntensity // ignore: cast_nullable_to_non_nullable
as double,enableAudioPitchShift: null == enableAudioPitchShift ? _self.enableAudioPitchShift : enableAudioPitchShift // ignore: cast_nullable_to_non_nullable
as bool,stripMetadata: null == stripMetadata ? _self.stripMetadata : stripMetadata // ignore: cast_nullable_to_non_nullable
as bool,targetDuration: freezed == targetDuration ? _self.targetDuration : targetDuration // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
