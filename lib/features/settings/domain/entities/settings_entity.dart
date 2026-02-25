class SettingsEntity {
  final String aiApiKey;
  final String posterPhoneNumber;
  final String deviceGroupCollection;

  const SettingsEntity({
    required this.aiApiKey,
    required this.posterPhoneNumber,
    this.deviceGroupCollection = 'device_groups',
  });

  /// Copy with method cho immutability
  SettingsEntity copyWith({
    String? aiApiKey,
    String? posterPhoneNumber,
    String? deviceGroupCollection,
  }) {
    return SettingsEntity(
      aiApiKey: aiApiKey ?? this.aiApiKey,
      posterPhoneNumber: posterPhoneNumber ?? this.posterPhoneNumber,
      deviceGroupCollection:
          deviceGroupCollection ?? this.deviceGroupCollection,
    );
  }

  /// Empty factory cho default values
  factory SettingsEntity.empty() {
    return const SettingsEntity(
      aiApiKey: '',
      posterPhoneNumber: '',
      deviceGroupCollection: 'device_groups',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SettingsEntity &&
        other.aiApiKey == aiApiKey &&
        other.posterPhoneNumber == posterPhoneNumber &&
        other.deviceGroupCollection == deviceGroupCollection;
  }

  @override
  int get hashCode =>
      aiApiKey.hashCode ^
      posterPhoneNumber.hashCode ^
      deviceGroupCollection.hashCode;
}
