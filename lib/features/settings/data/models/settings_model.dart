import 'package:hive/hive.dart';
import 'package:scraki/features/settings/domain/entities/settings_entity.dart';

/// Hive Model cho Settings
/// TypeId = 1 (DeviceGroupModel dùng typeId = 0)
class SettingsModel extends HiveObject {
  String aiApiKey;
  String posterPhoneNumber;

  SettingsModel({required this.aiApiKey, required this.posterPhoneNumber});

  /// Mapper từ Entity sang Model
  factory SettingsModel.fromEntity(SettingsEntity entity) {
    return SettingsModel(
      aiApiKey: entity.aiApiKey,
      posterPhoneNumber: entity.posterPhoneNumber,
    );
  }

  /// Mapper từ Model sang Entity
  SettingsEntity toEntity() {
    return SettingsEntity(
      aiApiKey: aiApiKey,
      posterPhoneNumber: posterPhoneNumber,
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
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(2) // Số lượng fields
      ..writeByte(0)
      ..write(obj.aiApiKey)
      ..writeByte(1)
      ..write(obj.posterPhoneNumber);
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
