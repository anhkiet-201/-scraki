import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_group_entity.freezed.dart';

@freezed
class DeviceGroupEntity with _$DeviceGroupEntity {
  const factory DeviceGroupEntity({
    required String id,
    required String name,
    required int colorValue,
    required List<String> deviceSerials,
  }) = _DeviceGroupEntity;

  const DeviceGroupEntity._();

  /// Helper factory to create a new group with a generated ID and empty devices.
  factory DeviceGroupEntity.create({
    required String name,
    required int colorValue,
  }) {
    return DeviceGroupEntity(
      id: DateTime.now().millisecondsSinceEpoch
          .toString(), // Simple ID generation
      name: name,
      colorValue: colorValue,
      deviceSerials: [],
    );
  }
}
