// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poster_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PosterData _$PosterDataFromJson(Map<String, dynamic> json) {
  return _PosterData.fromJson(json);
}

/// @nodoc
mixin _$PosterData {
  String get jobTitle => throw _privateConstructorUsedError;
  String get companyName => throw _privateConstructorUsedError;
  String get location => throw _privateConstructorUsedError;
  String get salaryRange => throw _privateConstructorUsedError;

  /// Short bullet points (3-5 items)
  List<String> get requirements => throw _privateConstructorUsedError;

  /// Short bullet points (3-5 items)
  List<String> get benefits => throw _privateConstructorUsedError;
  String get contactInfo =>
      throw _privateConstructorUsedError; // Optional: Background image URL or theme color preference
  String? get backgroundUrl => throw _privateConstructorUsedError;
  String? get qrCodeData => throw _privateConstructorUsedError;
  String? get catchyHeadline =>
      throw _privateConstructorUsedError; // Hidden field to store raw content for AI processing
  String? get rawContent =>
      throw _privateConstructorUsedError; // ID/Slug for fetching details
  String? get slug =>
      throw _privateConstructorUsedError; // Images extracted from details
  List<String> get imageUrls =>
      throw _privateConstructorUsedError; // AI generated TikTok Caption
  String? get tikTokCaption => throw _privateConstructorUsedError;

  /// Serializes this PosterData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PosterData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PosterDataCopyWith<PosterData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PosterDataCopyWith<$Res> {
  factory $PosterDataCopyWith(
    PosterData value,
    $Res Function(PosterData) then,
  ) = _$PosterDataCopyWithImpl<$Res, PosterData>;
  @useResult
  $Res call({
    String jobTitle,
    String companyName,
    String location,
    String salaryRange,
    List<String> requirements,
    List<String> benefits,
    String contactInfo,
    String? backgroundUrl,
    String? qrCodeData,
    String? catchyHeadline,
    String? rawContent,
    String? slug,
    List<String> imageUrls,
    String? tikTokCaption,
  });
}

/// @nodoc
class _$PosterDataCopyWithImpl<$Res, $Val extends PosterData>
    implements $PosterDataCopyWith<$Res> {
  _$PosterDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PosterData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? jobTitle = null,
    Object? companyName = null,
    Object? location = null,
    Object? salaryRange = null,
    Object? requirements = null,
    Object? benefits = null,
    Object? contactInfo = null,
    Object? backgroundUrl = freezed,
    Object? qrCodeData = freezed,
    Object? catchyHeadline = freezed,
    Object? rawContent = freezed,
    Object? slug = freezed,
    Object? imageUrls = null,
    Object? tikTokCaption = freezed,
  }) {
    return _then(
      _value.copyWith(
            jobTitle: null == jobTitle
                ? _value.jobTitle
                : jobTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            companyName: null == companyName
                ? _value.companyName
                : companyName // ignore: cast_nullable_to_non_nullable
                      as String,
            location: null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String,
            salaryRange: null == salaryRange
                ? _value.salaryRange
                : salaryRange // ignore: cast_nullable_to_non_nullable
                      as String,
            requirements: null == requirements
                ? _value.requirements
                : requirements // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            benefits: null == benefits
                ? _value.benefits
                : benefits // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            contactInfo: null == contactInfo
                ? _value.contactInfo
                : contactInfo // ignore: cast_nullable_to_non_nullable
                      as String,
            backgroundUrl: freezed == backgroundUrl
                ? _value.backgroundUrl
                : backgroundUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            qrCodeData: freezed == qrCodeData
                ? _value.qrCodeData
                : qrCodeData // ignore: cast_nullable_to_non_nullable
                      as String?,
            catchyHeadline: freezed == catchyHeadline
                ? _value.catchyHeadline
                : catchyHeadline // ignore: cast_nullable_to_non_nullable
                      as String?,
            rawContent: freezed == rawContent
                ? _value.rawContent
                : rawContent // ignore: cast_nullable_to_non_nullable
                      as String?,
            slug: freezed == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String?,
            imageUrls: null == imageUrls
                ? _value.imageUrls
                : imageUrls // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            tikTokCaption: freezed == tikTokCaption
                ? _value.tikTokCaption
                : tikTokCaption // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PosterDataImplCopyWith<$Res>
    implements $PosterDataCopyWith<$Res> {
  factory _$$PosterDataImplCopyWith(
    _$PosterDataImpl value,
    $Res Function(_$PosterDataImpl) then,
  ) = __$$PosterDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String jobTitle,
    String companyName,
    String location,
    String salaryRange,
    List<String> requirements,
    List<String> benefits,
    String contactInfo,
    String? backgroundUrl,
    String? qrCodeData,
    String? catchyHeadline,
    String? rawContent,
    String? slug,
    List<String> imageUrls,
    String? tikTokCaption,
  });
}

/// @nodoc
class __$$PosterDataImplCopyWithImpl<$Res>
    extends _$PosterDataCopyWithImpl<$Res, _$PosterDataImpl>
    implements _$$PosterDataImplCopyWith<$Res> {
  __$$PosterDataImplCopyWithImpl(
    _$PosterDataImpl _value,
    $Res Function(_$PosterDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PosterData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? jobTitle = null,
    Object? companyName = null,
    Object? location = null,
    Object? salaryRange = null,
    Object? requirements = null,
    Object? benefits = null,
    Object? contactInfo = null,
    Object? backgroundUrl = freezed,
    Object? qrCodeData = freezed,
    Object? catchyHeadline = freezed,
    Object? rawContent = freezed,
    Object? slug = freezed,
    Object? imageUrls = null,
    Object? tikTokCaption = freezed,
  }) {
    return _then(
      _$PosterDataImpl(
        jobTitle: null == jobTitle
            ? _value.jobTitle
            : jobTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        companyName: null == companyName
            ? _value.companyName
            : companyName // ignore: cast_nullable_to_non_nullable
                  as String,
        location: null == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String,
        salaryRange: null == salaryRange
            ? _value.salaryRange
            : salaryRange // ignore: cast_nullable_to_non_nullable
                  as String,
        requirements: null == requirements
            ? _value._requirements
            : requirements // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        benefits: null == benefits
            ? _value._benefits
            : benefits // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        contactInfo: null == contactInfo
            ? _value.contactInfo
            : contactInfo // ignore: cast_nullable_to_non_nullable
                  as String,
        backgroundUrl: freezed == backgroundUrl
            ? _value.backgroundUrl
            : backgroundUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        qrCodeData: freezed == qrCodeData
            ? _value.qrCodeData
            : qrCodeData // ignore: cast_nullable_to_non_nullable
                  as String?,
        catchyHeadline: freezed == catchyHeadline
            ? _value.catchyHeadline
            : catchyHeadline // ignore: cast_nullable_to_non_nullable
                  as String?,
        rawContent: freezed == rawContent
            ? _value.rawContent
            : rawContent // ignore: cast_nullable_to_non_nullable
                  as String?,
        slug: freezed == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String?,
        imageUrls: null == imageUrls
            ? _value._imageUrls
            : imageUrls // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        tikTokCaption: freezed == tikTokCaption
            ? _value.tikTokCaption
            : tikTokCaption // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PosterDataImpl implements _PosterData {
  const _$PosterDataImpl({
    required this.jobTitle,
    required this.companyName,
    required this.location,
    required this.salaryRange,
    final List<String> requirements = const [],
    final List<String> benefits = const [],
    required this.contactInfo,
    this.backgroundUrl,
    this.qrCodeData,
    this.catchyHeadline,
    this.rawContent,
    this.slug,
    final List<String> imageUrls = const [],
    this.tikTokCaption,
  }) : _requirements = requirements,
       _benefits = benefits,
       _imageUrls = imageUrls;

  factory _$PosterDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$PosterDataImplFromJson(json);

  @override
  final String jobTitle;
  @override
  final String companyName;
  @override
  final String location;
  @override
  final String salaryRange;

  /// Short bullet points (3-5 items)
  final List<String> _requirements;

  /// Short bullet points (3-5 items)
  @override
  @JsonKey()
  List<String> get requirements {
    if (_requirements is EqualUnmodifiableListView) return _requirements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requirements);
  }

  /// Short bullet points (3-5 items)
  final List<String> _benefits;

  /// Short bullet points (3-5 items)
  @override
  @JsonKey()
  List<String> get benefits {
    if (_benefits is EqualUnmodifiableListView) return _benefits;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_benefits);
  }

  @override
  final String contactInfo;
  // Optional: Background image URL or theme color preference
  @override
  final String? backgroundUrl;
  @override
  final String? qrCodeData;
  @override
  final String? catchyHeadline;
  // Hidden field to store raw content for AI processing
  @override
  final String? rawContent;
  // ID/Slug for fetching details
  @override
  final String? slug;
  // Images extracted from details
  final List<String> _imageUrls;
  // Images extracted from details
  @override
  @JsonKey()
  List<String> get imageUrls {
    if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_imageUrls);
  }

  // AI generated TikTok Caption
  @override
  final String? tikTokCaption;

  @override
  String toString() {
    return 'PosterData(jobTitle: $jobTitle, companyName: $companyName, location: $location, salaryRange: $salaryRange, requirements: $requirements, benefits: $benefits, contactInfo: $contactInfo, backgroundUrl: $backgroundUrl, qrCodeData: $qrCodeData, catchyHeadline: $catchyHeadline, rawContent: $rawContent, slug: $slug, imageUrls: $imageUrls, tikTokCaption: $tikTokCaption)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PosterDataImpl &&
            (identical(other.jobTitle, jobTitle) ||
                other.jobTitle == jobTitle) &&
            (identical(other.companyName, companyName) ||
                other.companyName == companyName) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.salaryRange, salaryRange) ||
                other.salaryRange == salaryRange) &&
            const DeepCollectionEquality().equals(
              other._requirements,
              _requirements,
            ) &&
            const DeepCollectionEquality().equals(other._benefits, _benefits) &&
            (identical(other.contactInfo, contactInfo) ||
                other.contactInfo == contactInfo) &&
            (identical(other.backgroundUrl, backgroundUrl) ||
                other.backgroundUrl == backgroundUrl) &&
            (identical(other.qrCodeData, qrCodeData) ||
                other.qrCodeData == qrCodeData) &&
            (identical(other.catchyHeadline, catchyHeadline) ||
                other.catchyHeadline == catchyHeadline) &&
            (identical(other.rawContent, rawContent) ||
                other.rawContent == rawContent) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            const DeepCollectionEquality().equals(
              other._imageUrls,
              _imageUrls,
            ) &&
            (identical(other.tikTokCaption, tikTokCaption) ||
                other.tikTokCaption == tikTokCaption));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    jobTitle,
    companyName,
    location,
    salaryRange,
    const DeepCollectionEquality().hash(_requirements),
    const DeepCollectionEquality().hash(_benefits),
    contactInfo,
    backgroundUrl,
    qrCodeData,
    catchyHeadline,
    rawContent,
    slug,
    const DeepCollectionEquality().hash(_imageUrls),
    tikTokCaption,
  );

  /// Create a copy of PosterData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PosterDataImplCopyWith<_$PosterDataImpl> get copyWith =>
      __$$PosterDataImplCopyWithImpl<_$PosterDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PosterDataImplToJson(this);
  }
}

abstract class _PosterData implements PosterData {
  const factory _PosterData({
    required final String jobTitle,
    required final String companyName,
    required final String location,
    required final String salaryRange,
    final List<String> requirements,
    final List<String> benefits,
    required final String contactInfo,
    final String? backgroundUrl,
    final String? qrCodeData,
    final String? catchyHeadline,
    final String? rawContent,
    final String? slug,
    final List<String> imageUrls,
    final String? tikTokCaption,
  }) = _$PosterDataImpl;

  factory _PosterData.fromJson(Map<String, dynamic> json) =
      _$PosterDataImpl.fromJson;

  @override
  String get jobTitle;
  @override
  String get companyName;
  @override
  String get location;
  @override
  String get salaryRange;

  /// Short bullet points (3-5 items)
  @override
  List<String> get requirements;

  /// Short bullet points (3-5 items)
  @override
  List<String> get benefits;
  @override
  String get contactInfo; // Optional: Background image URL or theme color preference
  @override
  String? get backgroundUrl;
  @override
  String? get qrCodeData;
  @override
  String? get catchyHeadline; // Hidden field to store raw content for AI processing
  @override
  String? get rawContent; // ID/Slug for fetching details
  @override
  String? get slug; // Images extracted from details
  @override
  List<String> get imageUrls; // AI generated TikTok Caption
  @override
  String? get tikTokCaption;

  /// Create a copy of PosterData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PosterDataImplCopyWith<_$PosterDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
