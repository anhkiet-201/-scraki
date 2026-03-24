// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_composition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VideoComposition {

 String get id; List<String> get sourceVideoPaths; Duration get targetDuration; bool get randomize; String get stylePreset;// Effects
 double get saturation; double get contrast; double get playbackSpeed; double get zoomIntensity;// Anti-Reup Configuration
 AntiReupConfig get antiReupConfig; int get randomSeed;
/// Create a copy of VideoComposition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoCompositionCopyWith<VideoComposition> get copyWith => _$VideoCompositionCopyWithImpl<VideoComposition>(this as VideoComposition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoComposition&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.sourceVideoPaths, sourceVideoPaths)&&(identical(other.targetDuration, targetDuration) || other.targetDuration == targetDuration)&&(identical(other.randomize, randomize) || other.randomize == randomize)&&(identical(other.stylePreset, stylePreset) || other.stylePreset == stylePreset)&&(identical(other.saturation, saturation) || other.saturation == saturation)&&(identical(other.contrast, contrast) || other.contrast == contrast)&&(identical(other.playbackSpeed, playbackSpeed) || other.playbackSpeed == playbackSpeed)&&(identical(other.zoomIntensity, zoomIntensity) || other.zoomIntensity == zoomIntensity)&&(identical(other.antiReupConfig, antiReupConfig) || other.antiReupConfig == antiReupConfig)&&(identical(other.randomSeed, randomSeed) || other.randomSeed == randomSeed));
}


@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(sourceVideoPaths),targetDuration,randomize,stylePreset,saturation,contrast,playbackSpeed,zoomIntensity,antiReupConfig,randomSeed);

@override
String toString() {
  return 'VideoComposition(id: $id, sourceVideoPaths: $sourceVideoPaths, targetDuration: $targetDuration, randomize: $randomize, stylePreset: $stylePreset, saturation: $saturation, contrast: $contrast, playbackSpeed: $playbackSpeed, zoomIntensity: $zoomIntensity, antiReupConfig: $antiReupConfig, randomSeed: $randomSeed)';
}


}

/// @nodoc
abstract mixin class $VideoCompositionCopyWith<$Res>  {
  factory $VideoCompositionCopyWith(VideoComposition value, $Res Function(VideoComposition) _then) = _$VideoCompositionCopyWithImpl;
@useResult
$Res call({
 String id, List<String> sourceVideoPaths, Duration targetDuration, bool randomize, String stylePreset, double saturation, double contrast, double playbackSpeed, double zoomIntensity, AntiReupConfig antiReupConfig, int randomSeed
});


$AntiReupConfigCopyWith<$Res> get antiReupConfig;

}
/// @nodoc
class _$VideoCompositionCopyWithImpl<$Res>
    implements $VideoCompositionCopyWith<$Res> {
  _$VideoCompositionCopyWithImpl(this._self, this._then);

  final VideoComposition _self;
  final $Res Function(VideoComposition) _then;

/// Create a copy of VideoComposition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sourceVideoPaths = null,Object? targetDuration = null,Object? randomize = null,Object? stylePreset = null,Object? saturation = null,Object? contrast = null,Object? playbackSpeed = null,Object? zoomIntensity = null,Object? antiReupConfig = null,Object? randomSeed = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sourceVideoPaths: null == sourceVideoPaths ? _self.sourceVideoPaths : sourceVideoPaths // ignore: cast_nullable_to_non_nullable
as List<String>,targetDuration: null == targetDuration ? _self.targetDuration : targetDuration // ignore: cast_nullable_to_non_nullable
as Duration,randomize: null == randomize ? _self.randomize : randomize // ignore: cast_nullable_to_non_nullable
as bool,stylePreset: null == stylePreset ? _self.stylePreset : stylePreset // ignore: cast_nullable_to_non_nullable
as String,saturation: null == saturation ? _self.saturation : saturation // ignore: cast_nullable_to_non_nullable
as double,contrast: null == contrast ? _self.contrast : contrast // ignore: cast_nullable_to_non_nullable
as double,playbackSpeed: null == playbackSpeed ? _self.playbackSpeed : playbackSpeed // ignore: cast_nullable_to_non_nullable
as double,zoomIntensity: null == zoomIntensity ? _self.zoomIntensity : zoomIntensity // ignore: cast_nullable_to_non_nullable
as double,antiReupConfig: null == antiReupConfig ? _self.antiReupConfig : antiReupConfig // ignore: cast_nullable_to_non_nullable
as AntiReupConfig,randomSeed: null == randomSeed ? _self.randomSeed : randomSeed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of VideoComposition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AntiReupConfigCopyWith<$Res> get antiReupConfig {
  
  return $AntiReupConfigCopyWith<$Res>(_self.antiReupConfig, (value) {
    return _then(_self.copyWith(antiReupConfig: value));
  });
}
}


/// Adds pattern-matching-related methods to [VideoComposition].
extension VideoCompositionPatterns on VideoComposition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoComposition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoComposition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoComposition value)  $default,){
final _that = this;
switch (_that) {
case _VideoComposition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoComposition value)?  $default,){
final _that = this;
switch (_that) {
case _VideoComposition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  List<String> sourceVideoPaths,  Duration targetDuration,  bool randomize,  String stylePreset,  double saturation,  double contrast,  double playbackSpeed,  double zoomIntensity,  AntiReupConfig antiReupConfig,  int randomSeed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoComposition() when $default != null:
return $default(_that.id,_that.sourceVideoPaths,_that.targetDuration,_that.randomize,_that.stylePreset,_that.saturation,_that.contrast,_that.playbackSpeed,_that.zoomIntensity,_that.antiReupConfig,_that.randomSeed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  List<String> sourceVideoPaths,  Duration targetDuration,  bool randomize,  String stylePreset,  double saturation,  double contrast,  double playbackSpeed,  double zoomIntensity,  AntiReupConfig antiReupConfig,  int randomSeed)  $default,) {final _that = this;
switch (_that) {
case _VideoComposition():
return $default(_that.id,_that.sourceVideoPaths,_that.targetDuration,_that.randomize,_that.stylePreset,_that.saturation,_that.contrast,_that.playbackSpeed,_that.zoomIntensity,_that.antiReupConfig,_that.randomSeed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  List<String> sourceVideoPaths,  Duration targetDuration,  bool randomize,  String stylePreset,  double saturation,  double contrast,  double playbackSpeed,  double zoomIntensity,  AntiReupConfig antiReupConfig,  int randomSeed)?  $default,) {final _that = this;
switch (_that) {
case _VideoComposition() when $default != null:
return $default(_that.id,_that.sourceVideoPaths,_that.targetDuration,_that.randomize,_that.stylePreset,_that.saturation,_that.contrast,_that.playbackSpeed,_that.zoomIntensity,_that.antiReupConfig,_that.randomSeed);case _:
  return null;

}
}

}

/// @nodoc


class _VideoComposition implements VideoComposition {
  const _VideoComposition({required this.id, required final  List<String> sourceVideoPaths, this.targetDuration = const Duration(seconds: 20), this.randomize = true, this.stylePreset = 'default', this.saturation = 1.2, this.contrast = 1.0, this.playbackSpeed = 1.0, this.zoomIntensity = 0.0, this.antiReupConfig = const AntiReupConfig(), this.randomSeed = 0}): _sourceVideoPaths = sourceVideoPaths;
  

@override final  String id;
 final  List<String> _sourceVideoPaths;
@override List<String> get sourceVideoPaths {
  if (_sourceVideoPaths is EqualUnmodifiableListView) return _sourceVideoPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sourceVideoPaths);
}

@override@JsonKey() final  Duration targetDuration;
@override@JsonKey() final  bool randomize;
@override@JsonKey() final  String stylePreset;
// Effects
@override@JsonKey() final  double saturation;
@override@JsonKey() final  double contrast;
@override@JsonKey() final  double playbackSpeed;
@override@JsonKey() final  double zoomIntensity;
// Anti-Reup Configuration
@override@JsonKey() final  AntiReupConfig antiReupConfig;
@override@JsonKey() final  int randomSeed;

/// Create a copy of VideoComposition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoCompositionCopyWith<_VideoComposition> get copyWith => __$VideoCompositionCopyWithImpl<_VideoComposition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoComposition&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._sourceVideoPaths, _sourceVideoPaths)&&(identical(other.targetDuration, targetDuration) || other.targetDuration == targetDuration)&&(identical(other.randomize, randomize) || other.randomize == randomize)&&(identical(other.stylePreset, stylePreset) || other.stylePreset == stylePreset)&&(identical(other.saturation, saturation) || other.saturation == saturation)&&(identical(other.contrast, contrast) || other.contrast == contrast)&&(identical(other.playbackSpeed, playbackSpeed) || other.playbackSpeed == playbackSpeed)&&(identical(other.zoomIntensity, zoomIntensity) || other.zoomIntensity == zoomIntensity)&&(identical(other.antiReupConfig, antiReupConfig) || other.antiReupConfig == antiReupConfig)&&(identical(other.randomSeed, randomSeed) || other.randomSeed == randomSeed));
}


@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_sourceVideoPaths),targetDuration,randomize,stylePreset,saturation,contrast,playbackSpeed,zoomIntensity,antiReupConfig,randomSeed);

@override
String toString() {
  return 'VideoComposition(id: $id, sourceVideoPaths: $sourceVideoPaths, targetDuration: $targetDuration, randomize: $randomize, stylePreset: $stylePreset, saturation: $saturation, contrast: $contrast, playbackSpeed: $playbackSpeed, zoomIntensity: $zoomIntensity, antiReupConfig: $antiReupConfig, randomSeed: $randomSeed)';
}


}

/// @nodoc
abstract mixin class _$VideoCompositionCopyWith<$Res> implements $VideoCompositionCopyWith<$Res> {
  factory _$VideoCompositionCopyWith(_VideoComposition value, $Res Function(_VideoComposition) _then) = __$VideoCompositionCopyWithImpl;
@override @useResult
$Res call({
 String id, List<String> sourceVideoPaths, Duration targetDuration, bool randomize, String stylePreset, double saturation, double contrast, double playbackSpeed, double zoomIntensity, AntiReupConfig antiReupConfig, int randomSeed
});


@override $AntiReupConfigCopyWith<$Res> get antiReupConfig;

}
/// @nodoc
class __$VideoCompositionCopyWithImpl<$Res>
    implements _$VideoCompositionCopyWith<$Res> {
  __$VideoCompositionCopyWithImpl(this._self, this._then);

  final _VideoComposition _self;
  final $Res Function(_VideoComposition) _then;

/// Create a copy of VideoComposition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sourceVideoPaths = null,Object? targetDuration = null,Object? randomize = null,Object? stylePreset = null,Object? saturation = null,Object? contrast = null,Object? playbackSpeed = null,Object? zoomIntensity = null,Object? antiReupConfig = null,Object? randomSeed = null,}) {
  return _then(_VideoComposition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sourceVideoPaths: null == sourceVideoPaths ? _self._sourceVideoPaths : sourceVideoPaths // ignore: cast_nullable_to_non_nullable
as List<String>,targetDuration: null == targetDuration ? _self.targetDuration : targetDuration // ignore: cast_nullable_to_non_nullable
as Duration,randomize: null == randomize ? _self.randomize : randomize // ignore: cast_nullable_to_non_nullable
as bool,stylePreset: null == stylePreset ? _self.stylePreset : stylePreset // ignore: cast_nullable_to_non_nullable
as String,saturation: null == saturation ? _self.saturation : saturation // ignore: cast_nullable_to_non_nullable
as double,contrast: null == contrast ? _self.contrast : contrast // ignore: cast_nullable_to_non_nullable
as double,playbackSpeed: null == playbackSpeed ? _self.playbackSpeed : playbackSpeed // ignore: cast_nullable_to_non_nullable
as double,zoomIntensity: null == zoomIntensity ? _self.zoomIntensity : zoomIntensity // ignore: cast_nullable_to_non_nullable
as double,antiReupConfig: null == antiReupConfig ? _self.antiReupConfig : antiReupConfig // ignore: cast_nullable_to_non_nullable
as AntiReupConfig,randomSeed: null == randomSeed ? _self.randomSeed : randomSeed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of VideoComposition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AntiReupConfigCopyWith<$Res> get antiReupConfig {
  
  return $AntiReupConfigCopyWith<$Res>(_self.antiReupConfig, (value) {
    return _then(_self.copyWith(antiReupConfig: value));
  });
}
}

// dart format on
