class ScriptEntity {
  final String id;
  final String name;
  final String description;
  final List<String> commands;

  ScriptEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.commands,
  });

  ScriptEntity copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? commands,
  }) {
    return ScriptEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      commands: commands ?? this.commands,
    );
  }
}
