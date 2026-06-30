class SettingsEntity {
  final String aiApiKey;
  final String posterPhoneNumber;
  final String deviceGroupCollection;
  final String ipRange;
  final int maxDevices;

  const SettingsEntity({
    required this.aiApiKey,
    required this.posterPhoneNumber,
    this.deviceGroupCollection = 'device_groups',
    this.ipRange = '10.10.0.0',
    this.maxDevices = 100,
  });

  /// Copy with method cho immutability
  SettingsEntity copyWith({
    String? aiApiKey,
    String? posterPhoneNumber,
    String? deviceGroupCollection,
    String? ipRange,
    int? maxDevices,
  }) {
    return SettingsEntity(
      aiApiKey: aiApiKey ?? this.aiApiKey,
      posterPhoneNumber: posterPhoneNumber ?? this.posterPhoneNumber,
      deviceGroupCollection:
          deviceGroupCollection ?? this.deviceGroupCollection,
      ipRange: ipRange ?? this.ipRange,
      maxDevices: maxDevices ?? this.maxDevices,
    );
  }

  /// Empty factory cho default values
  factory SettingsEntity.empty() {
    return const SettingsEntity(
      aiApiKey: '',
      posterPhoneNumber: '',
      deviceGroupCollection: 'device_groups',
      ipRange: '10.10.0.0',
      maxDevices: 100,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SettingsEntity &&
        other.aiApiKey == aiApiKey &&
        other.posterPhoneNumber == posterPhoneNumber &&
        other.deviceGroupCollection == deviceGroupCollection &&
        other.ipRange == ipRange &&
        other.maxDevices == maxDevices;
  }

  @override
  int get hashCode =>
      aiApiKey.hashCode ^
      posterPhoneNumber.hashCode ^
      deviceGroupCollection.hashCode ^
      ipRange.hashCode ^
      maxDevices.hashCode;
}
