import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_nickname_entity.freezed.dart';

@freezed
class DeviceNicknameEntity with _$DeviceNicknameEntity {
  const factory DeviceNicknameEntity({
    @Default({}) Map<String, String> nicknames,
  }) = _DeviceNicknameEntity;

  const DeviceNicknameEntity._();
}
