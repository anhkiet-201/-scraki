// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scrcpy_options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScrcpyOptions {

 int get maxSize;// 0 means no limit
 int get bitRate;// 8Mbps
 int get maxFps; bool get stayAwake; String get videoCodec; String? get audioCodec; String? get videoSource; String? get audioSource; String? get cameraFacing; String? get crop; String? get portRange; String? get tunnelHost; int? get tunnelPort; int? get audioBitRate; int? get angle; int? get screenOffTimeout; String? get captureOrientation; bool? get captureOrientationLock; bool get control; int? get displayId; String? get newDisplay; int? get displayImePolicy; bool get video; bool get audio; bool? get audioDup; bool? get showTouches; String? get videoCodecOptions; String? get audioCodecOptions; String? get videoEncoder; String? get audioEncoder; String? get cameraId; String? get cameraSize; String? get cameraAr; int? get cameraFps; bool? get forceAdbForward; bool? get powerOffOnClose; bool get clipboardAutosync; bool? get downsizeOnError; bool? get tcpip; String? get tcpipDst; bool get cleanup; bool? get powerOn; bool? get killAdbOnClose; bool? get cameraHighSpeed; bool? get vdDestroyContent; bool? get vdSystemDecorations; bool? get list; String? get logLevel;
/// Create a copy of ScrcpyOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScrcpyOptionsCopyWith<ScrcpyOptions> get copyWith => _$ScrcpyOptionsCopyWithImpl<ScrcpyOptions>(this as ScrcpyOptions, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScrcpyOptions&&(identical(other.maxSize, maxSize) || other.maxSize == maxSize)&&(identical(other.bitRate, bitRate) || other.bitRate == bitRate)&&(identical(other.maxFps, maxFps) || other.maxFps == maxFps)&&(identical(other.stayAwake, stayAwake) || other.stayAwake == stayAwake)&&(identical(other.videoCodec, videoCodec) || other.videoCodec == videoCodec)&&(identical(other.audioCodec, audioCodec) || other.audioCodec == audioCodec)&&(identical(other.videoSource, videoSource) || other.videoSource == videoSource)&&(identical(other.audioSource, audioSource) || other.audioSource == audioSource)&&(identical(other.cameraFacing, cameraFacing) || other.cameraFacing == cameraFacing)&&(identical(other.crop, crop) || other.crop == crop)&&(identical(other.portRange, portRange) || other.portRange == portRange)&&(identical(other.tunnelHost, tunnelHost) || other.tunnelHost == tunnelHost)&&(identical(other.tunnelPort, tunnelPort) || other.tunnelPort == tunnelPort)&&(identical(other.audioBitRate, audioBitRate) || other.audioBitRate == audioBitRate)&&(identical(other.angle, angle) || other.angle == angle)&&(identical(other.screenOffTimeout, screenOffTimeout) || other.screenOffTimeout == screenOffTimeout)&&(identical(other.captureOrientation, captureOrientation) || other.captureOrientation == captureOrientation)&&(identical(other.captureOrientationLock, captureOrientationLock) || other.captureOrientationLock == captureOrientationLock)&&(identical(other.control, control) || other.control == control)&&(identical(other.displayId, displayId) || other.displayId == displayId)&&(identical(other.newDisplay, newDisplay) || other.newDisplay == newDisplay)&&(identical(other.displayImePolicy, displayImePolicy) || other.displayImePolicy == displayImePolicy)&&(identical(other.video, video) || other.video == video)&&(identical(other.audio, audio) || other.audio == audio)&&(identical(other.audioDup, audioDup) || other.audioDup == audioDup)&&(identical(other.showTouches, showTouches) || other.showTouches == showTouches)&&(identical(other.videoCodecOptions, videoCodecOptions) || other.videoCodecOptions == videoCodecOptions)&&(identical(other.audioCodecOptions, audioCodecOptions) || other.audioCodecOptions == audioCodecOptions)&&(identical(other.videoEncoder, videoEncoder) || other.videoEncoder == videoEncoder)&&(identical(other.audioEncoder, audioEncoder) || other.audioEncoder == audioEncoder)&&(identical(other.cameraId, cameraId) || other.cameraId == cameraId)&&(identical(other.cameraSize, cameraSize) || other.cameraSize == cameraSize)&&(identical(other.cameraAr, cameraAr) || other.cameraAr == cameraAr)&&(identical(other.cameraFps, cameraFps) || other.cameraFps == cameraFps)&&(identical(other.forceAdbForward, forceAdbForward) || other.forceAdbForward == forceAdbForward)&&(identical(other.powerOffOnClose, powerOffOnClose) || other.powerOffOnClose == powerOffOnClose)&&(identical(other.clipboardAutosync, clipboardAutosync) || other.clipboardAutosync == clipboardAutosync)&&(identical(other.downsizeOnError, downsizeOnError) || other.downsizeOnError == downsizeOnError)&&(identical(other.tcpip, tcpip) || other.tcpip == tcpip)&&(identical(other.tcpipDst, tcpipDst) || other.tcpipDst == tcpipDst)&&(identical(other.cleanup, cleanup) || other.cleanup == cleanup)&&(identical(other.powerOn, powerOn) || other.powerOn == powerOn)&&(identical(other.killAdbOnClose, killAdbOnClose) || other.killAdbOnClose == killAdbOnClose)&&(identical(other.cameraHighSpeed, cameraHighSpeed) || other.cameraHighSpeed == cameraHighSpeed)&&(identical(other.vdDestroyContent, vdDestroyContent) || other.vdDestroyContent == vdDestroyContent)&&(identical(other.vdSystemDecorations, vdSystemDecorations) || other.vdSystemDecorations == vdSystemDecorations)&&(identical(other.list, list) || other.list == list)&&(identical(other.logLevel, logLevel) || other.logLevel == logLevel));
}


@override
int get hashCode => Object.hashAll([runtimeType,maxSize,bitRate,maxFps,stayAwake,videoCodec,audioCodec,videoSource,audioSource,cameraFacing,crop,portRange,tunnelHost,tunnelPort,audioBitRate,angle,screenOffTimeout,captureOrientation,captureOrientationLock,control,displayId,newDisplay,displayImePolicy,video,audio,audioDup,showTouches,videoCodecOptions,audioCodecOptions,videoEncoder,audioEncoder,cameraId,cameraSize,cameraAr,cameraFps,forceAdbForward,powerOffOnClose,clipboardAutosync,downsizeOnError,tcpip,tcpipDst,cleanup,powerOn,killAdbOnClose,cameraHighSpeed,vdDestroyContent,vdSystemDecorations,list,logLevel]);

@override
String toString() {
  return 'ScrcpyOptions(maxSize: $maxSize, bitRate: $bitRate, maxFps: $maxFps, stayAwake: $stayAwake, videoCodec: $videoCodec, audioCodec: $audioCodec, videoSource: $videoSource, audioSource: $audioSource, cameraFacing: $cameraFacing, crop: $crop, portRange: $portRange, tunnelHost: $tunnelHost, tunnelPort: $tunnelPort, audioBitRate: $audioBitRate, angle: $angle, screenOffTimeout: $screenOffTimeout, captureOrientation: $captureOrientation, captureOrientationLock: $captureOrientationLock, control: $control, displayId: $displayId, newDisplay: $newDisplay, displayImePolicy: $displayImePolicy, video: $video, audio: $audio, audioDup: $audioDup, showTouches: $showTouches, videoCodecOptions: $videoCodecOptions, audioCodecOptions: $audioCodecOptions, videoEncoder: $videoEncoder, audioEncoder: $audioEncoder, cameraId: $cameraId, cameraSize: $cameraSize, cameraAr: $cameraAr, cameraFps: $cameraFps, forceAdbForward: $forceAdbForward, powerOffOnClose: $powerOffOnClose, clipboardAutosync: $clipboardAutosync, downsizeOnError: $downsizeOnError, tcpip: $tcpip, tcpipDst: $tcpipDst, cleanup: $cleanup, powerOn: $powerOn, killAdbOnClose: $killAdbOnClose, cameraHighSpeed: $cameraHighSpeed, vdDestroyContent: $vdDestroyContent, vdSystemDecorations: $vdSystemDecorations, list: $list, logLevel: $logLevel)';
}


}

/// @nodoc
abstract mixin class $ScrcpyOptionsCopyWith<$Res>  {
  factory $ScrcpyOptionsCopyWith(ScrcpyOptions value, $Res Function(ScrcpyOptions) _then) = _$ScrcpyOptionsCopyWithImpl;
@useResult
$Res call({
 int maxSize, int bitRate, int maxFps, bool stayAwake, String videoCodec, String? audioCodec, String? videoSource, String? audioSource, String? cameraFacing, String? crop, String? portRange, String? tunnelHost, int? tunnelPort, int? audioBitRate, int? angle, int? screenOffTimeout, String? captureOrientation, bool? captureOrientationLock, bool control, int? displayId, String? newDisplay, int? displayImePolicy, bool video, bool audio, bool? audioDup, bool? showTouches, String? videoCodecOptions, String? audioCodecOptions, String? videoEncoder, String? audioEncoder, String? cameraId, String? cameraSize, String? cameraAr, int? cameraFps, bool? forceAdbForward, bool? powerOffOnClose, bool clipboardAutosync, bool? downsizeOnError, bool? tcpip, String? tcpipDst, bool cleanup, bool? powerOn, bool? killAdbOnClose, bool? cameraHighSpeed, bool? vdDestroyContent, bool? vdSystemDecorations, bool? list, String? logLevel
});




}
/// @nodoc
class _$ScrcpyOptionsCopyWithImpl<$Res>
    implements $ScrcpyOptionsCopyWith<$Res> {
  _$ScrcpyOptionsCopyWithImpl(this._self, this._then);

  final ScrcpyOptions _self;
  final $Res Function(ScrcpyOptions) _then;

/// Create a copy of ScrcpyOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxSize = null,Object? bitRate = null,Object? maxFps = null,Object? stayAwake = null,Object? videoCodec = null,Object? audioCodec = freezed,Object? videoSource = freezed,Object? audioSource = freezed,Object? cameraFacing = freezed,Object? crop = freezed,Object? portRange = freezed,Object? tunnelHost = freezed,Object? tunnelPort = freezed,Object? audioBitRate = freezed,Object? angle = freezed,Object? screenOffTimeout = freezed,Object? captureOrientation = freezed,Object? captureOrientationLock = freezed,Object? control = null,Object? displayId = freezed,Object? newDisplay = freezed,Object? displayImePolicy = freezed,Object? video = null,Object? audio = null,Object? audioDup = freezed,Object? showTouches = freezed,Object? videoCodecOptions = freezed,Object? audioCodecOptions = freezed,Object? videoEncoder = freezed,Object? audioEncoder = freezed,Object? cameraId = freezed,Object? cameraSize = freezed,Object? cameraAr = freezed,Object? cameraFps = freezed,Object? forceAdbForward = freezed,Object? powerOffOnClose = freezed,Object? clipboardAutosync = null,Object? downsizeOnError = freezed,Object? tcpip = freezed,Object? tcpipDst = freezed,Object? cleanup = null,Object? powerOn = freezed,Object? killAdbOnClose = freezed,Object? cameraHighSpeed = freezed,Object? vdDestroyContent = freezed,Object? vdSystemDecorations = freezed,Object? list = freezed,Object? logLevel = freezed,}) {
  return _then(_self.copyWith(
maxSize: null == maxSize ? _self.maxSize : maxSize // ignore: cast_nullable_to_non_nullable
as int,bitRate: null == bitRate ? _self.bitRate : bitRate // ignore: cast_nullable_to_non_nullable
as int,maxFps: null == maxFps ? _self.maxFps : maxFps // ignore: cast_nullable_to_non_nullable
as int,stayAwake: null == stayAwake ? _self.stayAwake : stayAwake // ignore: cast_nullable_to_non_nullable
as bool,videoCodec: null == videoCodec ? _self.videoCodec : videoCodec // ignore: cast_nullable_to_non_nullable
as String,audioCodec: freezed == audioCodec ? _self.audioCodec : audioCodec // ignore: cast_nullable_to_non_nullable
as String?,videoSource: freezed == videoSource ? _self.videoSource : videoSource // ignore: cast_nullable_to_non_nullable
as String?,audioSource: freezed == audioSource ? _self.audioSource : audioSource // ignore: cast_nullable_to_non_nullable
as String?,cameraFacing: freezed == cameraFacing ? _self.cameraFacing : cameraFacing // ignore: cast_nullable_to_non_nullable
as String?,crop: freezed == crop ? _self.crop : crop // ignore: cast_nullable_to_non_nullable
as String?,portRange: freezed == portRange ? _self.portRange : portRange // ignore: cast_nullable_to_non_nullable
as String?,tunnelHost: freezed == tunnelHost ? _self.tunnelHost : tunnelHost // ignore: cast_nullable_to_non_nullable
as String?,tunnelPort: freezed == tunnelPort ? _self.tunnelPort : tunnelPort // ignore: cast_nullable_to_non_nullable
as int?,audioBitRate: freezed == audioBitRate ? _self.audioBitRate : audioBitRate // ignore: cast_nullable_to_non_nullable
as int?,angle: freezed == angle ? _self.angle : angle // ignore: cast_nullable_to_non_nullable
as int?,screenOffTimeout: freezed == screenOffTimeout ? _self.screenOffTimeout : screenOffTimeout // ignore: cast_nullable_to_non_nullable
as int?,captureOrientation: freezed == captureOrientation ? _self.captureOrientation : captureOrientation // ignore: cast_nullable_to_non_nullable
as String?,captureOrientationLock: freezed == captureOrientationLock ? _self.captureOrientationLock : captureOrientationLock // ignore: cast_nullable_to_non_nullable
as bool?,control: null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as bool,displayId: freezed == displayId ? _self.displayId : displayId // ignore: cast_nullable_to_non_nullable
as int?,newDisplay: freezed == newDisplay ? _self.newDisplay : newDisplay // ignore: cast_nullable_to_non_nullable
as String?,displayImePolicy: freezed == displayImePolicy ? _self.displayImePolicy : displayImePolicy // ignore: cast_nullable_to_non_nullable
as int?,video: null == video ? _self.video : video // ignore: cast_nullable_to_non_nullable
as bool,audio: null == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as bool,audioDup: freezed == audioDup ? _self.audioDup : audioDup // ignore: cast_nullable_to_non_nullable
as bool?,showTouches: freezed == showTouches ? _self.showTouches : showTouches // ignore: cast_nullable_to_non_nullable
as bool?,videoCodecOptions: freezed == videoCodecOptions ? _self.videoCodecOptions : videoCodecOptions // ignore: cast_nullable_to_non_nullable
as String?,audioCodecOptions: freezed == audioCodecOptions ? _self.audioCodecOptions : audioCodecOptions // ignore: cast_nullable_to_non_nullable
as String?,videoEncoder: freezed == videoEncoder ? _self.videoEncoder : videoEncoder // ignore: cast_nullable_to_non_nullable
as String?,audioEncoder: freezed == audioEncoder ? _self.audioEncoder : audioEncoder // ignore: cast_nullable_to_non_nullable
as String?,cameraId: freezed == cameraId ? _self.cameraId : cameraId // ignore: cast_nullable_to_non_nullable
as String?,cameraSize: freezed == cameraSize ? _self.cameraSize : cameraSize // ignore: cast_nullable_to_non_nullable
as String?,cameraAr: freezed == cameraAr ? _self.cameraAr : cameraAr // ignore: cast_nullable_to_non_nullable
as String?,cameraFps: freezed == cameraFps ? _self.cameraFps : cameraFps // ignore: cast_nullable_to_non_nullable
as int?,forceAdbForward: freezed == forceAdbForward ? _self.forceAdbForward : forceAdbForward // ignore: cast_nullable_to_non_nullable
as bool?,powerOffOnClose: freezed == powerOffOnClose ? _self.powerOffOnClose : powerOffOnClose // ignore: cast_nullable_to_non_nullable
as bool?,clipboardAutosync: null == clipboardAutosync ? _self.clipboardAutosync : clipboardAutosync // ignore: cast_nullable_to_non_nullable
as bool,downsizeOnError: freezed == downsizeOnError ? _self.downsizeOnError : downsizeOnError // ignore: cast_nullable_to_non_nullable
as bool?,tcpip: freezed == tcpip ? _self.tcpip : tcpip // ignore: cast_nullable_to_non_nullable
as bool?,tcpipDst: freezed == tcpipDst ? _self.tcpipDst : tcpipDst // ignore: cast_nullable_to_non_nullable
as String?,cleanup: null == cleanup ? _self.cleanup : cleanup // ignore: cast_nullable_to_non_nullable
as bool,powerOn: freezed == powerOn ? _self.powerOn : powerOn // ignore: cast_nullable_to_non_nullable
as bool?,killAdbOnClose: freezed == killAdbOnClose ? _self.killAdbOnClose : killAdbOnClose // ignore: cast_nullable_to_non_nullable
as bool?,cameraHighSpeed: freezed == cameraHighSpeed ? _self.cameraHighSpeed : cameraHighSpeed // ignore: cast_nullable_to_non_nullable
as bool?,vdDestroyContent: freezed == vdDestroyContent ? _self.vdDestroyContent : vdDestroyContent // ignore: cast_nullable_to_non_nullable
as bool?,vdSystemDecorations: freezed == vdSystemDecorations ? _self.vdSystemDecorations : vdSystemDecorations // ignore: cast_nullable_to_non_nullable
as bool?,list: freezed == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as bool?,logLevel: freezed == logLevel ? _self.logLevel : logLevel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScrcpyOptions].
extension ScrcpyOptionsPatterns on ScrcpyOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScrcpyOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScrcpyOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScrcpyOptions value)  $default,){
final _that = this;
switch (_that) {
case _ScrcpyOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScrcpyOptions value)?  $default,){
final _that = this;
switch (_that) {
case _ScrcpyOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int maxSize,  int bitRate,  int maxFps,  bool stayAwake,  String videoCodec,  String? audioCodec,  String? videoSource,  String? audioSource,  String? cameraFacing,  String? crop,  String? portRange,  String? tunnelHost,  int? tunnelPort,  int? audioBitRate,  int? angle,  int? screenOffTimeout,  String? captureOrientation,  bool? captureOrientationLock,  bool control,  int? displayId,  String? newDisplay,  int? displayImePolicy,  bool video,  bool audio,  bool? audioDup,  bool? showTouches,  String? videoCodecOptions,  String? audioCodecOptions,  String? videoEncoder,  String? audioEncoder,  String? cameraId,  String? cameraSize,  String? cameraAr,  int? cameraFps,  bool? forceAdbForward,  bool? powerOffOnClose,  bool clipboardAutosync,  bool? downsizeOnError,  bool? tcpip,  String? tcpipDst,  bool cleanup,  bool? powerOn,  bool? killAdbOnClose,  bool? cameraHighSpeed,  bool? vdDestroyContent,  bool? vdSystemDecorations,  bool? list,  String? logLevel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScrcpyOptions() when $default != null:
return $default(_that.maxSize,_that.bitRate,_that.maxFps,_that.stayAwake,_that.videoCodec,_that.audioCodec,_that.videoSource,_that.audioSource,_that.cameraFacing,_that.crop,_that.portRange,_that.tunnelHost,_that.tunnelPort,_that.audioBitRate,_that.angle,_that.screenOffTimeout,_that.captureOrientation,_that.captureOrientationLock,_that.control,_that.displayId,_that.newDisplay,_that.displayImePolicy,_that.video,_that.audio,_that.audioDup,_that.showTouches,_that.videoCodecOptions,_that.audioCodecOptions,_that.videoEncoder,_that.audioEncoder,_that.cameraId,_that.cameraSize,_that.cameraAr,_that.cameraFps,_that.forceAdbForward,_that.powerOffOnClose,_that.clipboardAutosync,_that.downsizeOnError,_that.tcpip,_that.tcpipDst,_that.cleanup,_that.powerOn,_that.killAdbOnClose,_that.cameraHighSpeed,_that.vdDestroyContent,_that.vdSystemDecorations,_that.list,_that.logLevel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int maxSize,  int bitRate,  int maxFps,  bool stayAwake,  String videoCodec,  String? audioCodec,  String? videoSource,  String? audioSource,  String? cameraFacing,  String? crop,  String? portRange,  String? tunnelHost,  int? tunnelPort,  int? audioBitRate,  int? angle,  int? screenOffTimeout,  String? captureOrientation,  bool? captureOrientationLock,  bool control,  int? displayId,  String? newDisplay,  int? displayImePolicy,  bool video,  bool audio,  bool? audioDup,  bool? showTouches,  String? videoCodecOptions,  String? audioCodecOptions,  String? videoEncoder,  String? audioEncoder,  String? cameraId,  String? cameraSize,  String? cameraAr,  int? cameraFps,  bool? forceAdbForward,  bool? powerOffOnClose,  bool clipboardAutosync,  bool? downsizeOnError,  bool? tcpip,  String? tcpipDst,  bool cleanup,  bool? powerOn,  bool? killAdbOnClose,  bool? cameraHighSpeed,  bool? vdDestroyContent,  bool? vdSystemDecorations,  bool? list,  String? logLevel)  $default,) {final _that = this;
switch (_that) {
case _ScrcpyOptions():
return $default(_that.maxSize,_that.bitRate,_that.maxFps,_that.stayAwake,_that.videoCodec,_that.audioCodec,_that.videoSource,_that.audioSource,_that.cameraFacing,_that.crop,_that.portRange,_that.tunnelHost,_that.tunnelPort,_that.audioBitRate,_that.angle,_that.screenOffTimeout,_that.captureOrientation,_that.captureOrientationLock,_that.control,_that.displayId,_that.newDisplay,_that.displayImePolicy,_that.video,_that.audio,_that.audioDup,_that.showTouches,_that.videoCodecOptions,_that.audioCodecOptions,_that.videoEncoder,_that.audioEncoder,_that.cameraId,_that.cameraSize,_that.cameraAr,_that.cameraFps,_that.forceAdbForward,_that.powerOffOnClose,_that.clipboardAutosync,_that.downsizeOnError,_that.tcpip,_that.tcpipDst,_that.cleanup,_that.powerOn,_that.killAdbOnClose,_that.cameraHighSpeed,_that.vdDestroyContent,_that.vdSystemDecorations,_that.list,_that.logLevel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int maxSize,  int bitRate,  int maxFps,  bool stayAwake,  String videoCodec,  String? audioCodec,  String? videoSource,  String? audioSource,  String? cameraFacing,  String? crop,  String? portRange,  String? tunnelHost,  int? tunnelPort,  int? audioBitRate,  int? angle,  int? screenOffTimeout,  String? captureOrientation,  bool? captureOrientationLock,  bool control,  int? displayId,  String? newDisplay,  int? displayImePolicy,  bool video,  bool audio,  bool? audioDup,  bool? showTouches,  String? videoCodecOptions,  String? audioCodecOptions,  String? videoEncoder,  String? audioEncoder,  String? cameraId,  String? cameraSize,  String? cameraAr,  int? cameraFps,  bool? forceAdbForward,  bool? powerOffOnClose,  bool clipboardAutosync,  bool? downsizeOnError,  bool? tcpip,  String? tcpipDst,  bool cleanup,  bool? powerOn,  bool? killAdbOnClose,  bool? cameraHighSpeed,  bool? vdDestroyContent,  bool? vdSystemDecorations,  bool? list,  String? logLevel)?  $default,) {final _that = this;
switch (_that) {
case _ScrcpyOptions() when $default != null:
return $default(_that.maxSize,_that.bitRate,_that.maxFps,_that.stayAwake,_that.videoCodec,_that.audioCodec,_that.videoSource,_that.audioSource,_that.cameraFacing,_that.crop,_that.portRange,_that.tunnelHost,_that.tunnelPort,_that.audioBitRate,_that.angle,_that.screenOffTimeout,_that.captureOrientation,_that.captureOrientationLock,_that.control,_that.displayId,_that.newDisplay,_that.displayImePolicy,_that.video,_that.audio,_that.audioDup,_that.showTouches,_that.videoCodecOptions,_that.audioCodecOptions,_that.videoEncoder,_that.audioEncoder,_that.cameraId,_that.cameraSize,_that.cameraAr,_that.cameraFps,_that.forceAdbForward,_that.powerOffOnClose,_that.clipboardAutosync,_that.downsizeOnError,_that.tcpip,_that.tcpipDst,_that.cleanup,_that.powerOn,_that.killAdbOnClose,_that.cameraHighSpeed,_that.vdDestroyContent,_that.vdSystemDecorations,_that.list,_that.logLevel);case _:
  return null;

}
}

}

/// @nodoc


class _ScrcpyOptions implements ScrcpyOptions {
  const _ScrcpyOptions({this.maxSize = 0, this.bitRate = 8000000, this.maxFps = 60, this.stayAwake = false, this.videoCodec = 'h265', this.audioCodec, this.videoSource, this.audioSource, this.cameraFacing, this.crop, this.portRange, this.tunnelHost, this.tunnelPort, this.audioBitRate, this.angle, this.screenOffTimeout, this.captureOrientation, this.captureOrientationLock, this.control = true, this.displayId, this.newDisplay, this.displayImePolicy, this.video = true, this.audio = false, this.audioDup, this.showTouches, this.videoCodecOptions, this.audioCodecOptions, this.videoEncoder, this.audioEncoder, this.cameraId, this.cameraSize, this.cameraAr, this.cameraFps, this.forceAdbForward, this.powerOffOnClose, this.clipboardAutosync = true, this.downsizeOnError, this.tcpip, this.tcpipDst, this.cleanup = false, this.powerOn, this.killAdbOnClose, this.cameraHighSpeed, this.vdDestroyContent, this.vdSystemDecorations, this.list, this.logLevel});
  

@override@JsonKey() final  int maxSize;
// 0 means no limit
@override@JsonKey() final  int bitRate;
// 8Mbps
@override@JsonKey() final  int maxFps;
@override@JsonKey() final  bool stayAwake;
@override@JsonKey() final  String videoCodec;
@override final  String? audioCodec;
@override final  String? videoSource;
@override final  String? audioSource;
@override final  String? cameraFacing;
@override final  String? crop;
@override final  String? portRange;
@override final  String? tunnelHost;
@override final  int? tunnelPort;
@override final  int? audioBitRate;
@override final  int? angle;
@override final  int? screenOffTimeout;
@override final  String? captureOrientation;
@override final  bool? captureOrientationLock;
@override@JsonKey() final  bool control;
@override final  int? displayId;
@override final  String? newDisplay;
@override final  int? displayImePolicy;
@override@JsonKey() final  bool video;
@override@JsonKey() final  bool audio;
@override final  bool? audioDup;
@override final  bool? showTouches;
@override final  String? videoCodecOptions;
@override final  String? audioCodecOptions;
@override final  String? videoEncoder;
@override final  String? audioEncoder;
@override final  String? cameraId;
@override final  String? cameraSize;
@override final  String? cameraAr;
@override final  int? cameraFps;
@override final  bool? forceAdbForward;
@override final  bool? powerOffOnClose;
@override@JsonKey() final  bool clipboardAutosync;
@override final  bool? downsizeOnError;
@override final  bool? tcpip;
@override final  String? tcpipDst;
@override@JsonKey() final  bool cleanup;
@override final  bool? powerOn;
@override final  bool? killAdbOnClose;
@override final  bool? cameraHighSpeed;
@override final  bool? vdDestroyContent;
@override final  bool? vdSystemDecorations;
@override final  bool? list;
@override final  String? logLevel;

/// Create a copy of ScrcpyOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScrcpyOptionsCopyWith<_ScrcpyOptions> get copyWith => __$ScrcpyOptionsCopyWithImpl<_ScrcpyOptions>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScrcpyOptions&&(identical(other.maxSize, maxSize) || other.maxSize == maxSize)&&(identical(other.bitRate, bitRate) || other.bitRate == bitRate)&&(identical(other.maxFps, maxFps) || other.maxFps == maxFps)&&(identical(other.stayAwake, stayAwake) || other.stayAwake == stayAwake)&&(identical(other.videoCodec, videoCodec) || other.videoCodec == videoCodec)&&(identical(other.audioCodec, audioCodec) || other.audioCodec == audioCodec)&&(identical(other.videoSource, videoSource) || other.videoSource == videoSource)&&(identical(other.audioSource, audioSource) || other.audioSource == audioSource)&&(identical(other.cameraFacing, cameraFacing) || other.cameraFacing == cameraFacing)&&(identical(other.crop, crop) || other.crop == crop)&&(identical(other.portRange, portRange) || other.portRange == portRange)&&(identical(other.tunnelHost, tunnelHost) || other.tunnelHost == tunnelHost)&&(identical(other.tunnelPort, tunnelPort) || other.tunnelPort == tunnelPort)&&(identical(other.audioBitRate, audioBitRate) || other.audioBitRate == audioBitRate)&&(identical(other.angle, angle) || other.angle == angle)&&(identical(other.screenOffTimeout, screenOffTimeout) || other.screenOffTimeout == screenOffTimeout)&&(identical(other.captureOrientation, captureOrientation) || other.captureOrientation == captureOrientation)&&(identical(other.captureOrientationLock, captureOrientationLock) || other.captureOrientationLock == captureOrientationLock)&&(identical(other.control, control) || other.control == control)&&(identical(other.displayId, displayId) || other.displayId == displayId)&&(identical(other.newDisplay, newDisplay) || other.newDisplay == newDisplay)&&(identical(other.displayImePolicy, displayImePolicy) || other.displayImePolicy == displayImePolicy)&&(identical(other.video, video) || other.video == video)&&(identical(other.audio, audio) || other.audio == audio)&&(identical(other.audioDup, audioDup) || other.audioDup == audioDup)&&(identical(other.showTouches, showTouches) || other.showTouches == showTouches)&&(identical(other.videoCodecOptions, videoCodecOptions) || other.videoCodecOptions == videoCodecOptions)&&(identical(other.audioCodecOptions, audioCodecOptions) || other.audioCodecOptions == audioCodecOptions)&&(identical(other.videoEncoder, videoEncoder) || other.videoEncoder == videoEncoder)&&(identical(other.audioEncoder, audioEncoder) || other.audioEncoder == audioEncoder)&&(identical(other.cameraId, cameraId) || other.cameraId == cameraId)&&(identical(other.cameraSize, cameraSize) || other.cameraSize == cameraSize)&&(identical(other.cameraAr, cameraAr) || other.cameraAr == cameraAr)&&(identical(other.cameraFps, cameraFps) || other.cameraFps == cameraFps)&&(identical(other.forceAdbForward, forceAdbForward) || other.forceAdbForward == forceAdbForward)&&(identical(other.powerOffOnClose, powerOffOnClose) || other.powerOffOnClose == powerOffOnClose)&&(identical(other.clipboardAutosync, clipboardAutosync) || other.clipboardAutosync == clipboardAutosync)&&(identical(other.downsizeOnError, downsizeOnError) || other.downsizeOnError == downsizeOnError)&&(identical(other.tcpip, tcpip) || other.tcpip == tcpip)&&(identical(other.tcpipDst, tcpipDst) || other.tcpipDst == tcpipDst)&&(identical(other.cleanup, cleanup) || other.cleanup == cleanup)&&(identical(other.powerOn, powerOn) || other.powerOn == powerOn)&&(identical(other.killAdbOnClose, killAdbOnClose) || other.killAdbOnClose == killAdbOnClose)&&(identical(other.cameraHighSpeed, cameraHighSpeed) || other.cameraHighSpeed == cameraHighSpeed)&&(identical(other.vdDestroyContent, vdDestroyContent) || other.vdDestroyContent == vdDestroyContent)&&(identical(other.vdSystemDecorations, vdSystemDecorations) || other.vdSystemDecorations == vdSystemDecorations)&&(identical(other.list, list) || other.list == list)&&(identical(other.logLevel, logLevel) || other.logLevel == logLevel));
}


@override
int get hashCode => Object.hashAll([runtimeType,maxSize,bitRate,maxFps,stayAwake,videoCodec,audioCodec,videoSource,audioSource,cameraFacing,crop,portRange,tunnelHost,tunnelPort,audioBitRate,angle,screenOffTimeout,captureOrientation,captureOrientationLock,control,displayId,newDisplay,displayImePolicy,video,audio,audioDup,showTouches,videoCodecOptions,audioCodecOptions,videoEncoder,audioEncoder,cameraId,cameraSize,cameraAr,cameraFps,forceAdbForward,powerOffOnClose,clipboardAutosync,downsizeOnError,tcpip,tcpipDst,cleanup,powerOn,killAdbOnClose,cameraHighSpeed,vdDestroyContent,vdSystemDecorations,list,logLevel]);

@override
String toString() {
  return 'ScrcpyOptions(maxSize: $maxSize, bitRate: $bitRate, maxFps: $maxFps, stayAwake: $stayAwake, videoCodec: $videoCodec, audioCodec: $audioCodec, videoSource: $videoSource, audioSource: $audioSource, cameraFacing: $cameraFacing, crop: $crop, portRange: $portRange, tunnelHost: $tunnelHost, tunnelPort: $tunnelPort, audioBitRate: $audioBitRate, angle: $angle, screenOffTimeout: $screenOffTimeout, captureOrientation: $captureOrientation, captureOrientationLock: $captureOrientationLock, control: $control, displayId: $displayId, newDisplay: $newDisplay, displayImePolicy: $displayImePolicy, video: $video, audio: $audio, audioDup: $audioDup, showTouches: $showTouches, videoCodecOptions: $videoCodecOptions, audioCodecOptions: $audioCodecOptions, videoEncoder: $videoEncoder, audioEncoder: $audioEncoder, cameraId: $cameraId, cameraSize: $cameraSize, cameraAr: $cameraAr, cameraFps: $cameraFps, forceAdbForward: $forceAdbForward, powerOffOnClose: $powerOffOnClose, clipboardAutosync: $clipboardAutosync, downsizeOnError: $downsizeOnError, tcpip: $tcpip, tcpipDst: $tcpipDst, cleanup: $cleanup, powerOn: $powerOn, killAdbOnClose: $killAdbOnClose, cameraHighSpeed: $cameraHighSpeed, vdDestroyContent: $vdDestroyContent, vdSystemDecorations: $vdSystemDecorations, list: $list, logLevel: $logLevel)';
}


}

/// @nodoc
abstract mixin class _$ScrcpyOptionsCopyWith<$Res> implements $ScrcpyOptionsCopyWith<$Res> {
  factory _$ScrcpyOptionsCopyWith(_ScrcpyOptions value, $Res Function(_ScrcpyOptions) _then) = __$ScrcpyOptionsCopyWithImpl;
@override @useResult
$Res call({
 int maxSize, int bitRate, int maxFps, bool stayAwake, String videoCodec, String? audioCodec, String? videoSource, String? audioSource, String? cameraFacing, String? crop, String? portRange, String? tunnelHost, int? tunnelPort, int? audioBitRate, int? angle, int? screenOffTimeout, String? captureOrientation, bool? captureOrientationLock, bool control, int? displayId, String? newDisplay, int? displayImePolicy, bool video, bool audio, bool? audioDup, bool? showTouches, String? videoCodecOptions, String? audioCodecOptions, String? videoEncoder, String? audioEncoder, String? cameraId, String? cameraSize, String? cameraAr, int? cameraFps, bool? forceAdbForward, bool? powerOffOnClose, bool clipboardAutosync, bool? downsizeOnError, bool? tcpip, String? tcpipDst, bool cleanup, bool? powerOn, bool? killAdbOnClose, bool? cameraHighSpeed, bool? vdDestroyContent, bool? vdSystemDecorations, bool? list, String? logLevel
});




}
/// @nodoc
class __$ScrcpyOptionsCopyWithImpl<$Res>
    implements _$ScrcpyOptionsCopyWith<$Res> {
  __$ScrcpyOptionsCopyWithImpl(this._self, this._then);

  final _ScrcpyOptions _self;
  final $Res Function(_ScrcpyOptions) _then;

/// Create a copy of ScrcpyOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxSize = null,Object? bitRate = null,Object? maxFps = null,Object? stayAwake = null,Object? videoCodec = null,Object? audioCodec = freezed,Object? videoSource = freezed,Object? audioSource = freezed,Object? cameraFacing = freezed,Object? crop = freezed,Object? portRange = freezed,Object? tunnelHost = freezed,Object? tunnelPort = freezed,Object? audioBitRate = freezed,Object? angle = freezed,Object? screenOffTimeout = freezed,Object? captureOrientation = freezed,Object? captureOrientationLock = freezed,Object? control = null,Object? displayId = freezed,Object? newDisplay = freezed,Object? displayImePolicy = freezed,Object? video = null,Object? audio = null,Object? audioDup = freezed,Object? showTouches = freezed,Object? videoCodecOptions = freezed,Object? audioCodecOptions = freezed,Object? videoEncoder = freezed,Object? audioEncoder = freezed,Object? cameraId = freezed,Object? cameraSize = freezed,Object? cameraAr = freezed,Object? cameraFps = freezed,Object? forceAdbForward = freezed,Object? powerOffOnClose = freezed,Object? clipboardAutosync = null,Object? downsizeOnError = freezed,Object? tcpip = freezed,Object? tcpipDst = freezed,Object? cleanup = null,Object? powerOn = freezed,Object? killAdbOnClose = freezed,Object? cameraHighSpeed = freezed,Object? vdDestroyContent = freezed,Object? vdSystemDecorations = freezed,Object? list = freezed,Object? logLevel = freezed,}) {
  return _then(_ScrcpyOptions(
maxSize: null == maxSize ? _self.maxSize : maxSize // ignore: cast_nullable_to_non_nullable
as int,bitRate: null == bitRate ? _self.bitRate : bitRate // ignore: cast_nullable_to_non_nullable
as int,maxFps: null == maxFps ? _self.maxFps : maxFps // ignore: cast_nullable_to_non_nullable
as int,stayAwake: null == stayAwake ? _self.stayAwake : stayAwake // ignore: cast_nullable_to_non_nullable
as bool,videoCodec: null == videoCodec ? _self.videoCodec : videoCodec // ignore: cast_nullable_to_non_nullable
as String,audioCodec: freezed == audioCodec ? _self.audioCodec : audioCodec // ignore: cast_nullable_to_non_nullable
as String?,videoSource: freezed == videoSource ? _self.videoSource : videoSource // ignore: cast_nullable_to_non_nullable
as String?,audioSource: freezed == audioSource ? _self.audioSource : audioSource // ignore: cast_nullable_to_non_nullable
as String?,cameraFacing: freezed == cameraFacing ? _self.cameraFacing : cameraFacing // ignore: cast_nullable_to_non_nullable
as String?,crop: freezed == crop ? _self.crop : crop // ignore: cast_nullable_to_non_nullable
as String?,portRange: freezed == portRange ? _self.portRange : portRange // ignore: cast_nullable_to_non_nullable
as String?,tunnelHost: freezed == tunnelHost ? _self.tunnelHost : tunnelHost // ignore: cast_nullable_to_non_nullable
as String?,tunnelPort: freezed == tunnelPort ? _self.tunnelPort : tunnelPort // ignore: cast_nullable_to_non_nullable
as int?,audioBitRate: freezed == audioBitRate ? _self.audioBitRate : audioBitRate // ignore: cast_nullable_to_non_nullable
as int?,angle: freezed == angle ? _self.angle : angle // ignore: cast_nullable_to_non_nullable
as int?,screenOffTimeout: freezed == screenOffTimeout ? _self.screenOffTimeout : screenOffTimeout // ignore: cast_nullable_to_non_nullable
as int?,captureOrientation: freezed == captureOrientation ? _self.captureOrientation : captureOrientation // ignore: cast_nullable_to_non_nullable
as String?,captureOrientationLock: freezed == captureOrientationLock ? _self.captureOrientationLock : captureOrientationLock // ignore: cast_nullable_to_non_nullable
as bool?,control: null == control ? _self.control : control // ignore: cast_nullable_to_non_nullable
as bool,displayId: freezed == displayId ? _self.displayId : displayId // ignore: cast_nullable_to_non_nullable
as int?,newDisplay: freezed == newDisplay ? _self.newDisplay : newDisplay // ignore: cast_nullable_to_non_nullable
as String?,displayImePolicy: freezed == displayImePolicy ? _self.displayImePolicy : displayImePolicy // ignore: cast_nullable_to_non_nullable
as int?,video: null == video ? _self.video : video // ignore: cast_nullable_to_non_nullable
as bool,audio: null == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as bool,audioDup: freezed == audioDup ? _self.audioDup : audioDup // ignore: cast_nullable_to_non_nullable
as bool?,showTouches: freezed == showTouches ? _self.showTouches : showTouches // ignore: cast_nullable_to_non_nullable
as bool?,videoCodecOptions: freezed == videoCodecOptions ? _self.videoCodecOptions : videoCodecOptions // ignore: cast_nullable_to_non_nullable
as String?,audioCodecOptions: freezed == audioCodecOptions ? _self.audioCodecOptions : audioCodecOptions // ignore: cast_nullable_to_non_nullable
as String?,videoEncoder: freezed == videoEncoder ? _self.videoEncoder : videoEncoder // ignore: cast_nullable_to_non_nullable
as String?,audioEncoder: freezed == audioEncoder ? _self.audioEncoder : audioEncoder // ignore: cast_nullable_to_non_nullable
as String?,cameraId: freezed == cameraId ? _self.cameraId : cameraId // ignore: cast_nullable_to_non_nullable
as String?,cameraSize: freezed == cameraSize ? _self.cameraSize : cameraSize // ignore: cast_nullable_to_non_nullable
as String?,cameraAr: freezed == cameraAr ? _self.cameraAr : cameraAr // ignore: cast_nullable_to_non_nullable
as String?,cameraFps: freezed == cameraFps ? _self.cameraFps : cameraFps // ignore: cast_nullable_to_non_nullable
as int?,forceAdbForward: freezed == forceAdbForward ? _self.forceAdbForward : forceAdbForward // ignore: cast_nullable_to_non_nullable
as bool?,powerOffOnClose: freezed == powerOffOnClose ? _self.powerOffOnClose : powerOffOnClose // ignore: cast_nullable_to_non_nullable
as bool?,clipboardAutosync: null == clipboardAutosync ? _self.clipboardAutosync : clipboardAutosync // ignore: cast_nullable_to_non_nullable
as bool,downsizeOnError: freezed == downsizeOnError ? _self.downsizeOnError : downsizeOnError // ignore: cast_nullable_to_non_nullable
as bool?,tcpip: freezed == tcpip ? _self.tcpip : tcpip // ignore: cast_nullable_to_non_nullable
as bool?,tcpipDst: freezed == tcpipDst ? _self.tcpipDst : tcpipDst // ignore: cast_nullable_to_non_nullable
as String?,cleanup: null == cleanup ? _self.cleanup : cleanup // ignore: cast_nullable_to_non_nullable
as bool,powerOn: freezed == powerOn ? _self.powerOn : powerOn // ignore: cast_nullable_to_non_nullable
as bool?,killAdbOnClose: freezed == killAdbOnClose ? _self.killAdbOnClose : killAdbOnClose // ignore: cast_nullable_to_non_nullable
as bool?,cameraHighSpeed: freezed == cameraHighSpeed ? _self.cameraHighSpeed : cameraHighSpeed // ignore: cast_nullable_to_non_nullable
as bool?,vdDestroyContent: freezed == vdDestroyContent ? _self.vdDestroyContent : vdDestroyContent // ignore: cast_nullable_to_non_nullable
as bool?,vdSystemDecorations: freezed == vdSystemDecorations ? _self.vdSystemDecorations : vdSystemDecorations // ignore: cast_nullable_to_non_nullable
as bool?,list: freezed == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as bool?,logLevel: freezed == logLevel ? _self.logLevel : logLevel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
