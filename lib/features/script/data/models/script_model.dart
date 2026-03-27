import 'package:hive/hive.dart';
import '../../domain/entities/script_entity.dart';

class ScriptModel extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String description;
  
  @HiveField(3)
  List<String> commands;
  
  @HiveField(4)
  DateTime createdAt;
  
  @HiveField(5)
  DateTime updatedAt;
  
  @HiveField(6)
  List<String> tags;

  ScriptModel({
    required this.id,
    required this.name,
    required this.description,
    required this.commands,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  factory ScriptModel.fromEntity(ScriptEntity entity) {
    return ScriptModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      commands: entity.commands,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      tags: entity.tags,
    );
  }

  ScriptEntity toEntity() {
    return ScriptEntity(
      id: id,
      name: name,
      description: description,
      commands: commands,
      createdAt: createdAt,
      updatedAt: updatedAt,
      tags: tags,
    );
  }
}

class ScriptModelAdapter extends TypeAdapter<ScriptModel> {
  @override
  final int typeId = 2;

  @override
  ScriptModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScriptModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      commands: (fields[3] as List).cast<String>(),
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      tags: (fields[6] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ScriptModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.commands)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScriptModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
