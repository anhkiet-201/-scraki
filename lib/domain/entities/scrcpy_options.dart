import 'package:freezed_annotation/freezed_annotation.dart';

part 'scrcpy_options.freezed.dart';

@freezed
class ScrcpyOptions with _$ScrcpyOptions {
  const factory ScrcpyOptions({
    @Default(0) int maxSize, // 0 means no limit
    @Default(8000000) int bitRate, // 8Mbps
    @Default(60) int maxFps,
    @Default(false) bool stayAwake,
  }) = _ScrcpyOptions;
}
