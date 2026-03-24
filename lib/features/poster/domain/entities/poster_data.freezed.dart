// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poster_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PosterData {

 String get jobTitle; String get companyName; String get location; String get salaryRange;/// Short bullet points (3-5 items)
 List<String> get requirements;/// Short bullet points (3-5 items)
 List<String> get benefits; String get contactInfo;// Optional: Background image URL or theme color preference
 String? get backgroundUrl; String? get qrCodeData; String? get catchyHeadline;// Hidden field to store raw content for AI processing
 String? get rawContent;// ID/Slug for fetching details
 String? get slug;// Images extracted from details
 List<String> get imageUrls;// AI generated TikTok Caption
 String? get tikTokCaption;
/// Create a copy of PosterData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PosterDataCopyWith<PosterData> get copyWith => _$PosterDataCopyWithImpl<PosterData>(this as PosterData, _$identity);

  /// Serializes this PosterData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PosterData&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.location, location) || other.location == location)&&(identical(other.salaryRange, salaryRange) || other.salaryRange == salaryRange)&&const DeepCollectionEquality().equals(other.requirements, requirements)&&const DeepCollectionEquality().equals(other.benefits, benefits)&&(identical(other.contactInfo, contactInfo) || other.contactInfo == contactInfo)&&(identical(other.backgroundUrl, backgroundUrl) || other.backgroundUrl == backgroundUrl)&&(identical(other.qrCodeData, qrCodeData) || other.qrCodeData == qrCodeData)&&(identical(other.catchyHeadline, catchyHeadline) || other.catchyHeadline == catchyHeadline)&&(identical(other.rawContent, rawContent) || other.rawContent == rawContent)&&(identical(other.slug, slug) || other.slug == slug)&&const DeepCollectionEquality().equals(other.imageUrls, imageUrls)&&(identical(other.tikTokCaption, tikTokCaption) || other.tikTokCaption == tikTokCaption));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jobTitle,companyName,location,salaryRange,const DeepCollectionEquality().hash(requirements),const DeepCollectionEquality().hash(benefits),contactInfo,backgroundUrl,qrCodeData,catchyHeadline,rawContent,slug,const DeepCollectionEquality().hash(imageUrls),tikTokCaption);

@override
String toString() {
  return 'PosterData(jobTitle: $jobTitle, companyName: $companyName, location: $location, salaryRange: $salaryRange, requirements: $requirements, benefits: $benefits, contactInfo: $contactInfo, backgroundUrl: $backgroundUrl, qrCodeData: $qrCodeData, catchyHeadline: $catchyHeadline, rawContent: $rawContent, slug: $slug, imageUrls: $imageUrls, tikTokCaption: $tikTokCaption)';
}


}

/// @nodoc
abstract mixin class $PosterDataCopyWith<$Res>  {
  factory $PosterDataCopyWith(PosterData value, $Res Function(PosterData) _then) = _$PosterDataCopyWithImpl;
@useResult
$Res call({
 String jobTitle, String companyName, String location, String salaryRange, List<String> requirements, List<String> benefits, String contactInfo, String? backgroundUrl, String? qrCodeData, String? catchyHeadline, String? rawContent, String? slug, List<String> imageUrls, String? tikTokCaption
});




}
/// @nodoc
class _$PosterDataCopyWithImpl<$Res>
    implements $PosterDataCopyWith<$Res> {
  _$PosterDataCopyWithImpl(this._self, this._then);

  final PosterData _self;
  final $Res Function(PosterData) _then;

/// Create a copy of PosterData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobTitle = null,Object? companyName = null,Object? location = null,Object? salaryRange = null,Object? requirements = null,Object? benefits = null,Object? contactInfo = null,Object? backgroundUrl = freezed,Object? qrCodeData = freezed,Object? catchyHeadline = freezed,Object? rawContent = freezed,Object? slug = freezed,Object? imageUrls = null,Object? tikTokCaption = freezed,}) {
  return _then(_self.copyWith(
jobTitle: null == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,salaryRange: null == salaryRange ? _self.salaryRange : salaryRange // ignore: cast_nullable_to_non_nullable
as String,requirements: null == requirements ? _self.requirements : requirements // ignore: cast_nullable_to_non_nullable
as List<String>,benefits: null == benefits ? _self.benefits : benefits // ignore: cast_nullable_to_non_nullable
as List<String>,contactInfo: null == contactInfo ? _self.contactInfo : contactInfo // ignore: cast_nullable_to_non_nullable
as String,backgroundUrl: freezed == backgroundUrl ? _self.backgroundUrl : backgroundUrl // ignore: cast_nullable_to_non_nullable
as String?,qrCodeData: freezed == qrCodeData ? _self.qrCodeData : qrCodeData // ignore: cast_nullable_to_non_nullable
as String?,catchyHeadline: freezed == catchyHeadline ? _self.catchyHeadline : catchyHeadline // ignore: cast_nullable_to_non_nullable
as String?,rawContent: freezed == rawContent ? _self.rawContent : rawContent // ignore: cast_nullable_to_non_nullable
as String?,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,imageUrls: null == imageUrls ? _self.imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,tikTokCaption: freezed == tikTokCaption ? _self.tikTokCaption : tikTokCaption // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PosterData].
extension PosterDataPatterns on PosterData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PosterData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PosterData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PosterData value)  $default,){
final _that = this;
switch (_that) {
case _PosterData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PosterData value)?  $default,){
final _that = this;
switch (_that) {
case _PosterData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String jobTitle,  String companyName,  String location,  String salaryRange,  List<String> requirements,  List<String> benefits,  String contactInfo,  String? backgroundUrl,  String? qrCodeData,  String? catchyHeadline,  String? rawContent,  String? slug,  List<String> imageUrls,  String? tikTokCaption)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PosterData() when $default != null:
return $default(_that.jobTitle,_that.companyName,_that.location,_that.salaryRange,_that.requirements,_that.benefits,_that.contactInfo,_that.backgroundUrl,_that.qrCodeData,_that.catchyHeadline,_that.rawContent,_that.slug,_that.imageUrls,_that.tikTokCaption);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String jobTitle,  String companyName,  String location,  String salaryRange,  List<String> requirements,  List<String> benefits,  String contactInfo,  String? backgroundUrl,  String? qrCodeData,  String? catchyHeadline,  String? rawContent,  String? slug,  List<String> imageUrls,  String? tikTokCaption)  $default,) {final _that = this;
switch (_that) {
case _PosterData():
return $default(_that.jobTitle,_that.companyName,_that.location,_that.salaryRange,_that.requirements,_that.benefits,_that.contactInfo,_that.backgroundUrl,_that.qrCodeData,_that.catchyHeadline,_that.rawContent,_that.slug,_that.imageUrls,_that.tikTokCaption);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String jobTitle,  String companyName,  String location,  String salaryRange,  List<String> requirements,  List<String> benefits,  String contactInfo,  String? backgroundUrl,  String? qrCodeData,  String? catchyHeadline,  String? rawContent,  String? slug,  List<String> imageUrls,  String? tikTokCaption)?  $default,) {final _that = this;
switch (_that) {
case _PosterData() when $default != null:
return $default(_that.jobTitle,_that.companyName,_that.location,_that.salaryRange,_that.requirements,_that.benefits,_that.contactInfo,_that.backgroundUrl,_that.qrCodeData,_that.catchyHeadline,_that.rawContent,_that.slug,_that.imageUrls,_that.tikTokCaption);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PosterData implements PosterData {
  const _PosterData({required this.jobTitle, required this.companyName, required this.location, required this.salaryRange, final  List<String> requirements = const <String>[], final  List<String> benefits = const <String>[], required this.contactInfo, this.backgroundUrl, this.qrCodeData, this.catchyHeadline, this.rawContent, this.slug, final  List<String> imageUrls = const <String>[], this.tikTokCaption}): _requirements = requirements,_benefits = benefits,_imageUrls = imageUrls;
  factory _PosterData.fromJson(Map<String, dynamic> json) => _$PosterDataFromJson(json);

@override final  String jobTitle;
@override final  String companyName;
@override final  String location;
@override final  String salaryRange;
/// Short bullet points (3-5 items)
 final  List<String> _requirements;
/// Short bullet points (3-5 items)
@override@JsonKey() List<String> get requirements {
  if (_requirements is EqualUnmodifiableListView) return _requirements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requirements);
}

/// Short bullet points (3-5 items)
 final  List<String> _benefits;
/// Short bullet points (3-5 items)
@override@JsonKey() List<String> get benefits {
  if (_benefits is EqualUnmodifiableListView) return _benefits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_benefits);
}

@override final  String contactInfo;
// Optional: Background image URL or theme color preference
@override final  String? backgroundUrl;
@override final  String? qrCodeData;
@override final  String? catchyHeadline;
// Hidden field to store raw content for AI processing
@override final  String? rawContent;
// ID/Slug for fetching details
@override final  String? slug;
// Images extracted from details
 final  List<String> _imageUrls;
// Images extracted from details
@override@JsonKey() List<String> get imageUrls {
  if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_imageUrls);
}

// AI generated TikTok Caption
@override final  String? tikTokCaption;

/// Create a copy of PosterData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PosterDataCopyWith<_PosterData> get copyWith => __$PosterDataCopyWithImpl<_PosterData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PosterDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PosterData&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.location, location) || other.location == location)&&(identical(other.salaryRange, salaryRange) || other.salaryRange == salaryRange)&&const DeepCollectionEquality().equals(other._requirements, _requirements)&&const DeepCollectionEquality().equals(other._benefits, _benefits)&&(identical(other.contactInfo, contactInfo) || other.contactInfo == contactInfo)&&(identical(other.backgroundUrl, backgroundUrl) || other.backgroundUrl == backgroundUrl)&&(identical(other.qrCodeData, qrCodeData) || other.qrCodeData == qrCodeData)&&(identical(other.catchyHeadline, catchyHeadline) || other.catchyHeadline == catchyHeadline)&&(identical(other.rawContent, rawContent) || other.rawContent == rawContent)&&(identical(other.slug, slug) || other.slug == slug)&&const DeepCollectionEquality().equals(other._imageUrls, _imageUrls)&&(identical(other.tikTokCaption, tikTokCaption) || other.tikTokCaption == tikTokCaption));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jobTitle,companyName,location,salaryRange,const DeepCollectionEquality().hash(_requirements),const DeepCollectionEquality().hash(_benefits),contactInfo,backgroundUrl,qrCodeData,catchyHeadline,rawContent,slug,const DeepCollectionEquality().hash(_imageUrls),tikTokCaption);

@override
String toString() {
  return 'PosterData(jobTitle: $jobTitle, companyName: $companyName, location: $location, salaryRange: $salaryRange, requirements: $requirements, benefits: $benefits, contactInfo: $contactInfo, backgroundUrl: $backgroundUrl, qrCodeData: $qrCodeData, catchyHeadline: $catchyHeadline, rawContent: $rawContent, slug: $slug, imageUrls: $imageUrls, tikTokCaption: $tikTokCaption)';
}


}

/// @nodoc
abstract mixin class _$PosterDataCopyWith<$Res> implements $PosterDataCopyWith<$Res> {
  factory _$PosterDataCopyWith(_PosterData value, $Res Function(_PosterData) _then) = __$PosterDataCopyWithImpl;
@override @useResult
$Res call({
 String jobTitle, String companyName, String location, String salaryRange, List<String> requirements, List<String> benefits, String contactInfo, String? backgroundUrl, String? qrCodeData, String? catchyHeadline, String? rawContent, String? slug, List<String> imageUrls, String? tikTokCaption
});




}
/// @nodoc
class __$PosterDataCopyWithImpl<$Res>
    implements _$PosterDataCopyWith<$Res> {
  __$PosterDataCopyWithImpl(this._self, this._then);

  final _PosterData _self;
  final $Res Function(_PosterData) _then;

/// Create a copy of PosterData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobTitle = null,Object? companyName = null,Object? location = null,Object? salaryRange = null,Object? requirements = null,Object? benefits = null,Object? contactInfo = null,Object? backgroundUrl = freezed,Object? qrCodeData = freezed,Object? catchyHeadline = freezed,Object? rawContent = freezed,Object? slug = freezed,Object? imageUrls = null,Object? tikTokCaption = freezed,}) {
  return _then(_PosterData(
jobTitle: null == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,salaryRange: null == salaryRange ? _self.salaryRange : salaryRange // ignore: cast_nullable_to_non_nullable
as String,requirements: null == requirements ? _self._requirements : requirements // ignore: cast_nullable_to_non_nullable
as List<String>,benefits: null == benefits ? _self._benefits : benefits // ignore: cast_nullable_to_non_nullable
as List<String>,contactInfo: null == contactInfo ? _self.contactInfo : contactInfo // ignore: cast_nullable_to_non_nullable
as String,backgroundUrl: freezed == backgroundUrl ? _self.backgroundUrl : backgroundUrl // ignore: cast_nullable_to_non_nullable
as String?,qrCodeData: freezed == qrCodeData ? _self.qrCodeData : qrCodeData // ignore: cast_nullable_to_non_nullable
as String?,catchyHeadline: freezed == catchyHeadline ? _self.catchyHeadline : catchyHeadline // ignore: cast_nullable_to_non_nullable
as String?,rawContent: freezed == rawContent ? _self.rawContent : rawContent // ignore: cast_nullable_to_non_nullable
as String?,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,imageUrls: null == imageUrls ? _self._imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,tikTokCaption: freezed == tikTokCaption ? _self.tikTokCaption : tikTokCaption // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
