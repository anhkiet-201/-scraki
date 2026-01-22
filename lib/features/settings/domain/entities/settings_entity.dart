class SettingsEntity {
  final String aiApiKey;
  final String posterPhoneNumber;

  const SettingsEntity({
    required this.aiApiKey,
    required this.posterPhoneNumber,
  });

  /// Copy with method cho immutability
  SettingsEntity copyWith({String? aiApiKey, String? posterPhoneNumber}) {
    return SettingsEntity(
      aiApiKey: aiApiKey ?? this.aiApiKey,
      posterPhoneNumber: posterPhoneNumber ?? this.posterPhoneNumber,
    );
  }

  /// Empty factory cho default values
  factory SettingsEntity.empty() {
    return const SettingsEntity(aiApiKey: '', posterPhoneNumber: '');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SettingsEntity &&
        other.aiApiKey == aiApiKey &&
        other.posterPhoneNumber == posterPhoneNumber;
  }

  @override
  int get hashCode => aiApiKey.hashCode ^ posterPhoneNumber.hashCode;
}
