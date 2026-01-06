import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_entity.freezed.dart';

enum DeviceStatus { connected, offline, unauthorized }

enum ConnectionType { usb, tcp }

@freezed
class DeviceEntity with _$DeviceEntity {
  const factory DeviceEntity({
    required String id,
    required String serial,
    required String modelName,
    required DeviceStatus status,
    required ConnectionType connectionType,
  }) = _DeviceEntity;
}
