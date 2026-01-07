import 'package:hive/hive.dart';
import 'package:scraki/features/device/domain/entities/device_group_entity.dart';

class DeviceGroupModel extends HiveObject {
  String id;
  String name;
  int colorValue;
  List<String> deviceSerials;

  DeviceGroupModel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.deviceSerials,
  });

  factory DeviceGroupModel.fromEntity(DeviceGroupEntity entity) {
    return DeviceGroupModel(
      id: entity.id,
      name: entity.name,
      colorValue: entity.colorValue,
      deviceSerials: entity.deviceSerials,
    );
  }

  DeviceGroupEntity toEntity() {
    return DeviceGroupEntity(
      id: id,
      name: name,
      colorValue: colorValue,
      deviceSerials: deviceSerials,
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
    );
  }

  @override
  void write(BinaryWriter writer, DeviceGroupModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorValue)
      ..writeByte(3)
      ..write(obj.deviceSerials);
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
