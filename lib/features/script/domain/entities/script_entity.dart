class ScriptEntity {
  final String id;
  final String name;
  final String description;
  final List<String> commands;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;

  ScriptEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.commands,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.tags = const [],
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
  }) {
    return ScriptEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      commands: commands ?? this.commands,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }
}
