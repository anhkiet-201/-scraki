import 'package:cloud_firestore/cloud_firestore.dart';
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

  @HiveField(7)
  String tileType;

  @HiveField(8)
  bool enableFileDrop;

  ScriptModel({
    required this.id,
    required this.name,
    required this.description,
    required this.commands,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.tileType = 'normal',
    this.enableFileDrop = false,
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
      tileType: entity.tileType.name,
      enableFileDrop: entity.enableFileDrop,
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
      tileType: ScriptTileType.values.firstWhere(
        (e) => e.name == tileType,
        orElse: () => tileType == 'multiInput' ? ScriptTileType.input : ScriptTileType.normal,
      ),
      enableFileDrop: enableFileDrop,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'commands': commands,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'tileType': tileType,
      'enableFileDrop': enableFileDrop,
    };
  }

  factory ScriptModel.fromJson(Map<String, dynamic> json) {
    return ScriptModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      commands: (json['commands'] as List).cast<String>(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      tileType: json['tileType'] as String? ?? 'normal',
      enableFileDrop: json['enableFileDrop'] as bool? ?? false,
    );
  }

  factory ScriptModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScriptModel.fromJson({'id': doc.id, ...data});
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
      tileType: fields[7] as String? ?? 'normal',
      enableFileDrop: fields[8] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, ScriptModel obj) {
    writer
      ..writeByte(9)
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
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.tileType)
      ..writeByte(8)
      ..write(obj.enableFileDrop);
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
