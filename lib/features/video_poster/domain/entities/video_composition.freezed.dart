// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_composition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$VideoComposition {
  String get id => throw _privateConstructorUsedError;
  List<String> get sourceVideoPaths => throw _privateConstructorUsedError;
  PosterData get posterData => throw _privateConstructorUsedError;
  Duration get targetDuration => throw _privateConstructorUsedError;
  bool get randomize => throw _privateConstructorUsedError;
  String get stylePreset =>
      throw _privateConstructorUsedError; // Positioning (Relative 0.0 to 1.0)
  double get titleX => throw _privateConstructorUsedError;
  double get titleY => throw _privateConstructorUsedError;
  double get salaryX => throw _privateConstructorUsedError;
  double get salaryY => throw _privateConstructorUsedError;
  double get companyX => throw _privateConstructorUsedError;
  double get companyY => throw _privateConstructorUsedError; // Effects
  double get saturation => throw _privateConstructorUsedError;
  double get contrast => throw _privateConstructorUsedError;
  double get playbackSpeed => throw _privateConstructorUsedError;
  double get zoomIntensity =>
      throw _privateConstructorUsedError; // Anti-Reup Randomization
  double get noiseLevel => throw _privateConstructorUsedError;
  double get hueShift => throw _privateConstructorUsedError;
  double get brightnessDelta => throw _privateConstructorUsedError;
  int get randomSeed => throw _privateConstructorUsedError;

  /// Create a copy of VideoComposition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VideoCompositionCopyWith<VideoComposition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VideoCompositionCopyWith<$Res> {
  factory $VideoCompositionCopyWith(
    VideoComposition value,
    $Res Function(VideoComposition) then,
  ) = _$VideoCompositionCopyWithImpl<$Res, VideoComposition>;
  @useResult
  $Res call({
    String id,
    List<String> sourceVideoPaths,
    PosterData posterData,
    Duration targetDuration,
    bool randomize,
    String stylePreset,
    double titleX,
    double titleY,
    double salaryX,
    double salaryY,
    double companyX,
    double companyY,
    double saturation,
    double contrast,
    double playbackSpeed,
    double zoomIntensity,
    double noiseLevel,
    double hueShift,
    double brightnessDelta,
    int randomSeed,
  });

  $PosterDataCopyWith<$Res> get posterData;
}

/// @nodoc
class _$VideoCompositionCopyWithImpl<$Res, $Val extends VideoComposition>
    implements $VideoCompositionCopyWith<$Res> {
  _$VideoCompositionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VideoComposition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sourceVideoPaths = null,
    Object? posterData = null,
    Object? targetDuration = null,
    Object? randomize = null,
    Object? stylePreset = null,
    Object? titleX = null,
    Object? titleY = null,
    Object? salaryX = null,
    Object? salaryY = null,
    Object? companyX = null,
    Object? companyY = null,
    Object? saturation = null,
    Object? contrast = null,
    Object? playbackSpeed = null,
    Object? zoomIntensity = null,
    Object? noiseLevel = null,
    Object? hueShift = null,
    Object? brightnessDelta = null,
    Object? randomSeed = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            sourceVideoPaths: null == sourceVideoPaths
                ? _value.sourceVideoPaths
                : sourceVideoPaths // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            posterData: null == posterData
                ? _value.posterData
                : posterData // ignore: cast_nullable_to_non_nullable
                      as PosterData,
            targetDuration: null == targetDuration
                ? _value.targetDuration
                : targetDuration // ignore: cast_nullable_to_non_nullable
                      as Duration,
            randomize: null == randomize
                ? _value.randomize
                : randomize // ignore: cast_nullable_to_non_nullable
                      as bool,
            stylePreset: null == stylePreset
                ? _value.stylePreset
                : stylePreset // ignore: cast_nullable_to_non_nullable
                      as String,
            titleX: null == titleX
                ? _value.titleX
                : titleX // ignore: cast_nullable_to_non_nullable
                      as double,
            titleY: null == titleY
                ? _value.titleY
                : titleY // ignore: cast_nullable_to_non_nullable
                      as double,
            salaryX: null == salaryX
                ? _value.salaryX
                : salaryX // ignore: cast_nullable_to_non_nullable
                      as double,
            salaryY: null == salaryY
                ? _value.salaryY
                : salaryY // ignore: cast_nullable_to_non_nullable
                      as double,
            companyX: null == companyX
                ? _value.companyX
                : companyX // ignore: cast_nullable_to_non_nullable
                      as double,
            companyY: null == companyY
                ? _value.companyY
                : companyY // ignore: cast_nullable_to_non_nullable
                      as double,
            saturation: null == saturation
                ? _value.saturation
                : saturation // ignore: cast_nullable_to_non_nullable
                      as double,
            contrast: null == contrast
                ? _value.contrast
                : contrast // ignore: cast_nullable_to_non_nullable
                      as double,
            playbackSpeed: null == playbackSpeed
                ? _value.playbackSpeed
                : playbackSpeed // ignore: cast_nullable_to_non_nullable
                      as double,
            zoomIntensity: null == zoomIntensity
                ? _value.zoomIntensity
                : zoomIntensity // ignore: cast_nullable_to_non_nullable
                      as double,
            noiseLevel: null == noiseLevel
                ? _value.noiseLevel
                : noiseLevel // ignore: cast_nullable_to_non_nullable
                      as double,
            hueShift: null == hueShift
                ? _value.hueShift
                : hueShift // ignore: cast_nullable_to_non_nullable
                      as double,
            brightnessDelta: null == brightnessDelta
                ? _value.brightnessDelta
                : brightnessDelta // ignore: cast_nullable_to_non_nullable
                      as double,
            randomSeed: null == randomSeed
                ? _value.randomSeed
                : randomSeed // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }

  /// Create a copy of VideoComposition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PosterDataCopyWith<$Res> get posterData {
    return $PosterDataCopyWith<$Res>(_value.posterData, (value) {
      return _then(_value.copyWith(posterData: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VideoCompositionImplCopyWith<$Res>
    implements $VideoCompositionCopyWith<$Res> {
  factory _$$VideoCompositionImplCopyWith(
    _$VideoCompositionImpl value,
    $Res Function(_$VideoCompositionImpl) then,
  ) = __$$VideoCompositionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    List<String> sourceVideoPaths,
    PosterData posterData,
    Duration targetDuration,
    bool randomize,
    String stylePreset,
    double titleX,
    double titleY,
    double salaryX,
    double salaryY,
    double companyX,
    double companyY,
    double saturation,
    double contrast,
    double playbackSpeed,
    double zoomIntensity,
    double noiseLevel,
    double hueShift,
    double brightnessDelta,
    int randomSeed,
  });

  @override
  $PosterDataCopyWith<$Res> get posterData;
}

/// @nodoc
class __$$VideoCompositionImplCopyWithImpl<$Res>
    extends _$VideoCompositionCopyWithImpl<$Res, _$VideoCompositionImpl>
    implements _$$VideoCompositionImplCopyWith<$Res> {
  __$$VideoCompositionImplCopyWithImpl(
    _$VideoCompositionImpl _value,
    $Res Function(_$VideoCompositionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VideoComposition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sourceVideoPaths = null,
    Object? posterData = null,
    Object? targetDuration = null,
    Object? randomize = null,
    Object? stylePreset = null,
    Object? titleX = null,
    Object? titleY = null,
    Object? salaryX = null,
    Object? salaryY = null,
    Object? companyX = null,
    Object? companyY = null,
    Object? saturation = null,
    Object? contrast = null,
    Object? playbackSpeed = null,
    Object? zoomIntensity = null,
    Object? noiseLevel = null,
    Object? hueShift = null,
    Object? brightnessDelta = null,
    Object? randomSeed = null,
  }) {
    return _then(
      _$VideoCompositionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        sourceVideoPaths: null == sourceVideoPaths
            ? _value._sourceVideoPaths
            : sourceVideoPaths // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        posterData: null == posterData
            ? _value.posterData
            : posterData // ignore: cast_nullable_to_non_nullable
                  as PosterData,
        targetDuration: null == targetDuration
            ? _value.targetDuration
            : targetDuration // ignore: cast_nullable_to_non_nullable
                  as Duration,
        randomize: null == randomize
            ? _value.randomize
            : randomize // ignore: cast_nullable_to_non_nullable
                  as bool,
        stylePreset: null == stylePreset
            ? _value.stylePreset
            : stylePreset // ignore: cast_nullable_to_non_nullable
                  as String,
        titleX: null == titleX
            ? _value.titleX
            : titleX // ignore: cast_nullable_to_non_nullable
                  as double,
        titleY: null == titleY
            ? _value.titleY
            : titleY // ignore: cast_nullable_to_non_nullable
                  as double,
        salaryX: null == salaryX
            ? _value.salaryX
            : salaryX // ignore: cast_nullable_to_non_nullable
                  as double,
        salaryY: null == salaryY
            ? _value.salaryY
            : salaryY // ignore: cast_nullable_to_non_nullable
                  as double,
        companyX: null == companyX
            ? _value.companyX
            : companyX // ignore: cast_nullable_to_non_nullable
                  as double,
        companyY: null == companyY
            ? _value.companyY
            : companyY // ignore: cast_nullable_to_non_nullable
                  as double,
        saturation: null == saturation
            ? _value.saturation
            : saturation // ignore: cast_nullable_to_non_nullable
                  as double,
        contrast: null == contrast
            ? _value.contrast
            : contrast // ignore: cast_nullable_to_non_nullable
                  as double,
        playbackSpeed: null == playbackSpeed
            ? _value.playbackSpeed
            : playbackSpeed // ignore: cast_nullable_to_non_nullable
                  as double,
        zoomIntensity: null == zoomIntensity
            ? _value.zoomIntensity
            : zoomIntensity // ignore: cast_nullable_to_non_nullable
                  as double,
        noiseLevel: null == noiseLevel
            ? _value.noiseLevel
            : noiseLevel // ignore: cast_nullable_to_non_nullable
                  as double,
        hueShift: null == hueShift
            ? _value.hueShift
            : hueShift // ignore: cast_nullable_to_non_nullable
                  as double,
        brightnessDelta: null == brightnessDelta
            ? _value.brightnessDelta
            : brightnessDelta // ignore: cast_nullable_to_non_nullable
                  as double,
        randomSeed: null == randomSeed
            ? _value.randomSeed
            : randomSeed // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$VideoCompositionImpl implements _VideoComposition {
  const _$VideoCompositionImpl({
    required this.id,
    required final List<String> sourceVideoPaths,
    required this.posterData,
    this.targetDuration = const Duration(seconds: 20),
    this.randomize = true,
    this.stylePreset = 'default',
    this.titleX = 0.5,
    this.titleY = 0.15,
    this.salaryX = 0.5,
    this.salaryY = 0.25,
    this.companyX = 0.5,
    this.companyY = 0.85,
    this.saturation = 1.2,
    this.contrast = 1.0,
    this.playbackSpeed = 1.0,
    this.zoomIntensity = 0.0,
    this.noiseLevel = 0.0,
    this.hueShift = 0.0,
    this.brightnessDelta = 0.0,
    this.randomSeed = 0,
  }) : _sourceVideoPaths = sourceVideoPaths;

  @override
  final String id;
  final List<String> _sourceVideoPaths;
  @override
  List<String> get sourceVideoPaths {
    if (_sourceVideoPaths is EqualUnmodifiableListView)
      return _sourceVideoPaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sourceVideoPaths);
  }

  @override
  final PosterData posterData;
  @override
  @JsonKey()
  final Duration targetDuration;
  @override
  @JsonKey()
  final bool randomize;
  @override
  @JsonKey()
  final String stylePreset;
  // Positioning (Relative 0.0 to 1.0)
  @override
  @JsonKey()
  final double titleX;
  @override
  @JsonKey()
  final double titleY;
  @override
  @JsonKey()
  final double salaryX;
  @override
  @JsonKey()
  final double salaryY;
  @override
  @JsonKey()
  final double companyX;
  @override
  @JsonKey()
  final double companyY;
  // Effects
  @override
  @JsonKey()
  final double saturation;
  @override
  @JsonKey()
  final double contrast;
  @override
  @JsonKey()
  final double playbackSpeed;
  @override
  @JsonKey()
  final double zoomIntensity;
  // Anti-Reup Randomization
  @override
  @JsonKey()
  final double noiseLevel;
  @override
  @JsonKey()
  final double hueShift;
  @override
  @JsonKey()
  final double brightnessDelta;
  @override
  @JsonKey()
  final int randomSeed;

  @override
  String toString() {
    return 'VideoComposition(id: $id, sourceVideoPaths: $sourceVideoPaths, posterData: $posterData, targetDuration: $targetDuration, randomize: $randomize, stylePreset: $stylePreset, titleX: $titleX, titleY: $titleY, salaryX: $salaryX, salaryY: $salaryY, companyX: $companyX, companyY: $companyY, saturation: $saturation, contrast: $contrast, playbackSpeed: $playbackSpeed, zoomIntensity: $zoomIntensity, noiseLevel: $noiseLevel, hueShift: $hueShift, brightnessDelta: $brightnessDelta, randomSeed: $randomSeed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoCompositionImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(
              other._sourceVideoPaths,
              _sourceVideoPaths,
            ) &&
            (identical(other.posterData, posterData) ||
                other.posterData == posterData) &&
            (identical(other.targetDuration, targetDuration) ||
                other.targetDuration == targetDuration) &&
            (identical(other.randomize, randomize) ||
                other.randomize == randomize) &&
            (identical(other.stylePreset, stylePreset) ||
                other.stylePreset == stylePreset) &&
            (identical(other.titleX, titleX) || other.titleX == titleX) &&
            (identical(other.titleY, titleY) || other.titleY == titleY) &&
            (identical(other.salaryX, salaryX) || other.salaryX == salaryX) &&
            (identical(other.salaryY, salaryY) || other.salaryY == salaryY) &&
            (identical(other.companyX, companyX) ||
                other.companyX == companyX) &&
            (identical(other.companyY, companyY) ||
                other.companyY == companyY) &&
            (identical(other.saturation, saturation) ||
                other.saturation == saturation) &&
            (identical(other.contrast, contrast) ||
                other.contrast == contrast) &&
            (identical(other.playbackSpeed, playbackSpeed) ||
                other.playbackSpeed == playbackSpeed) &&
            (identical(other.zoomIntensity, zoomIntensity) ||
                other.zoomIntensity == zoomIntensity) &&
            (identical(other.noiseLevel, noiseLevel) ||
                other.noiseLevel == noiseLevel) &&
            (identical(other.hueShift, hueShift) ||
                other.hueShift == hueShift) &&
            (identical(other.brightnessDelta, brightnessDelta) ||
                other.brightnessDelta == brightnessDelta) &&
            (identical(other.randomSeed, randomSeed) ||
                other.randomSeed == randomSeed));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    const DeepCollectionEquality().hash(_sourceVideoPaths),
    posterData,
    targetDuration,
    randomize,
    stylePreset,
    titleX,
    titleY,
    salaryX,
    salaryY,
    companyX,
    companyY,
    saturation,
    contrast,
    playbackSpeed,
    zoomIntensity,
    noiseLevel,
    hueShift,
    brightnessDelta,
    randomSeed,
  ]);

  /// Create a copy of VideoComposition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoCompositionImplCopyWith<_$VideoCompositionImpl> get copyWith =>
      __$$VideoCompositionImplCopyWithImpl<_$VideoCompositionImpl>(
        this,
        _$identity,
      );
}

abstract class _VideoComposition implements VideoComposition {
  const factory _VideoComposition({
    required final String id,
    required final List<String> sourceVideoPaths,
    required final PosterData posterData,
    final Duration targetDuration,
    final bool randomize,
    final String stylePreset,
    final double titleX,
    final double titleY,
    final double salaryX,
    final double salaryY,
    final double companyX,
    final double companyY,
    final double saturation,
    final double contrast,
    final double playbackSpeed,
    final double zoomIntensity,
    final double noiseLevel,
    final double hueShift,
    final double brightnessDelta,
    final int randomSeed,
  }) = _$VideoCompositionImpl;

  @override
  String get id;
  @override
  List<String> get sourceVideoPaths;
  @override
  PosterData get posterData;
  @override
  Duration get targetDuration;
  @override
  bool get randomize;
  @override
  String get stylePreset; // Positioning (Relative 0.0 to 1.0)
  @override
  double get titleX;
  @override
  double get titleY;
  @override
  double get salaryX;
  @override
  double get salaryY;
  @override
  double get companyX;
  @override
  double get companyY; // Effects
  @override
  double get saturation;
  @override
  double get contrast;
  @override
  double get playbackSpeed;
  @override
  double get zoomIntensity; // Anti-Reup Randomization
  @override
  double get noiseLevel;
  @override
  double get hueShift;
  @override
  double get brightnessDelta;
  @override
  int get randomSeed;

  /// Create a copy of VideoComposition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoCompositionImplCopyWith<_$VideoCompositionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
