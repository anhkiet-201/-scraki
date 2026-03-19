import 'package:scraki/features/device/domain/entities/device_nickname_entity.dart';

class DeviceNicknameModel {
  final Map<String, String> nicknames;

  DeviceNicknameModel({
    required this.nicknames,
  });

  factory DeviceNicknameModel.fromEntity(DeviceNicknameEntity entity) {
    return DeviceNicknameModel(
      nicknames: entity.nicknames,
    );
  }

  factory DeviceNicknameModel.fromJson(Map<String, dynamic> json) {
    return DeviceNicknameModel(
      nicknames: (json['nicknames'] as Map<String, dynamic>?)?.map((key, value) {
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
      'nicknames': nicknames.map((key, value) {
        final safeKey = key.replaceAll('.', '_dot_').replaceAll(':', '_colon_');
        return MapEntry(safeKey, value);
      }),
    };
  }

  DeviceNicknameEntity toEntity() {
    return DeviceNicknameEntity(
      nicknames: nicknames,
    );
  }
}
