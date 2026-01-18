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
  String get stylePreset => throw _privateConstructorUsedError;

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

  @override
  String toString() {
    return 'VideoComposition(id: $id, sourceVideoPaths: $sourceVideoPaths, posterData: $posterData, targetDuration: $targetDuration, randomize: $randomize, stylePreset: $stylePreset)';
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
                other.stylePreset == stylePreset));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    const DeepCollectionEquality().hash(_sourceVideoPaths),
    posterData,
    targetDuration,
    randomize,
    stylePreset,
  );

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
  String get stylePreset;

  /// Create a copy of VideoComposition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoCompositionImplCopyWith<_$VideoCompositionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
