import 'package:hive/hive.dart';
import 'package:scraki/features/device/domain/entities/device_group_entity.dart';

class DeviceGroupModel extends HiveObject {
  String id;
  String name;
  int colorValue;
  List<String> deviceSerials;
  Map<String, String> deviceEmails;

  DeviceGroupModel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.deviceSerials,
    this.deviceEmails = const {},
  });

  factory DeviceGroupModel.fromEntity(DeviceGroupEntity entity) {
    return DeviceGroupModel(
      id: entity.id,
      name: entity.name,
      colorValue: entity.colorValue,
      deviceSerials: entity.deviceSerials,
      deviceEmails: entity.deviceEmails,
    );
  }

  factory DeviceGroupModel.fromJson(Map<String, dynamic> json) {
    return DeviceGroupModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Group',
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF000000,
      deviceSerials:
          (json['deviceSerials'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      deviceEmails:
          (json['deviceEmails'] as Map<String, dynamic>?)?.map((key, value) {
            final originalKey = key
                .replaceAll('_dot_', '.')
                .replaceAll('_colon_', ':');
            return MapEntry(originalKey, value.toString());
          }) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'deviceSerials': deviceSerials,
      'deviceEmails': deviceEmails.map((key, value) {
        final safeKey = key.replaceAll('.', '_dot_').replaceAll(':', '_colon_');
        return MapEntry(safeKey, value);
      }),
    };
  }

  DeviceGroupEntity toEntity() {
    return DeviceGroupEntity(
      id: id,
      name: name,
      colorValue: colorValue,
      deviceSerials: deviceSerials,
      deviceEmails: deviceEmails,
    );
  }
}

class DeviceGroupModelAdapter extends TypeAdapter<DeviceGroupModel> {
  @override
  final int typeId = 0;

  @override
  DeviceGroupModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeviceGroupModel(
      id: fields[0] as String,
      name: fields[1] as String,
      colorValue: fields[2] as int,
      deviceSerials: (fields[3] as List).cast<String>(),
      deviceEmails: (fields[4] as Map?)?.cast<String, String>() ?? {},
    );
  }

  @override
  void write(BinaryWriter writer, DeviceGroupModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorValue)
      ..writeByte(3)
      ..write(obj.deviceSerials)
      ..writeByte(4)
      ..write(obj.deviceEmails);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceGroupModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
