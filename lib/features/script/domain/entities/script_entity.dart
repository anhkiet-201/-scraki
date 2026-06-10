enum ScriptTileType { normal, confirm, dialog, input, multiInput }

class ScriptEntity {
  final String id;
  final String name;
  final String description;
  final List<String> commands;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final ScriptTileType tileType;
  final bool enableFileDrop;

  ScriptEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.commands,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.tags = const [],
    this.tileType = ScriptTileType.normal,
    this.enableFileDrop = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ScriptEntity copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? commands,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    ScriptTileType? tileType,
    bool? enableFileDrop,
  }) {
    return ScriptEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      commands: commands ?? this.commands,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      tileType: tileType ?? this.tileType,
      enableFileDrop: enableFileDrop ?? this.enableFileDrop,
    );
  }
}
