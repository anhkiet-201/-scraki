import 'package:hive/hive.dart';
import 'package:scraki/features/settings/domain/entities/settings_entity.dart';

/// Hive Model cho Settings
/// TypeId = 1 (DeviceGroupModel dùng typeId = 0)
class SettingsModel extends HiveObject {
  String aiApiKey;
  String posterPhoneNumber;
  String deviceGroupCollection;
  String ipRange;
  int maxDevices;

  SettingsModel({
    required this.aiApiKey,
    required this.posterPhoneNumber,
    this.deviceGroupCollection = 'device_groups',
    this.ipRange = '10.10.0.0',
    this.maxDevices = 100,
  });

  /// Mapper từ Entity sang Model
  factory SettingsModel.fromEntity(SettingsEntity entity) {
    return SettingsModel(
      aiApiKey: entity.aiApiKey,
      posterPhoneNumber: entity.posterPhoneNumber,
      deviceGroupCollection: entity.deviceGroupCollection,
      ipRange: entity.ipRange,
      maxDevices: entity.maxDevices,
    );
  }

  /// Mapper từ Model sang Entity
  SettingsEntity toEntity() {
    return SettingsEntity(
      aiApiKey: aiApiKey,
      posterPhoneNumber: posterPhoneNumber,
      deviceGroupCollection: deviceGroupCollection,
      ipRange: ipRange,
      maxDevices: maxDevices,
    );
  }
}

/// TypeAdapter cho Hive serialization
/// IMPORTANT: typeId = 1 để tránh xung đột với DeviceGroupModelAdapter (typeId = 0)
class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 1;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      aiApiKey: fields[0] as String? ?? '',
      posterPhoneNumber: fields[1] as String? ?? '',
      // Backward compatible: dữ liệu cũ (2-4 fields) sẽ fallback về default
      deviceGroupCollection: fields[2] as String? ?? 'device_groups',
      ipRange: fields[3] as String? ?? '10.10.0.0',
      maxDevices: fields[4] as int? ?? 100,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(5) // Tăng lên 5 fields
      ..writeByte(0)
      ..write(obj.aiApiKey)
      ..writeByte(1)
      ..write(obj.posterPhoneNumber)
      ..writeByte(2)
      ..write(obj.deviceGroupCollection)
      ..writeByte(3)
      ..write(obj.ipRange)
      ..writeByte(4)
      ..write(obj.maxDevices);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
