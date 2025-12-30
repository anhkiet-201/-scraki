import '../../domain/entities/device_entity.dart';

class AdbOutputParser {
  static List<DeviceEntity> parseDevices(String output) {
    final devices = <DeviceEntity>[];
    final lines = output.split('\n');

    // Regex matches: "SERIAL  status  details..."
    // Group 1: Serial
    // Group 2: Status (device|offline|unauthorized)
    // Group 3: Details (product:x model:y ...)
    final deviceRegex = RegExp(r'^(\S+)\s+(device|offline|unauthorized)(.*)$');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('List of devices attached')) continue;

      final match = deviceRegex.firstMatch(line);
      if (match != null) {
        final serial = match.group(1)!;
        final statusStr = match.group(2)!;
        final details = match.group(3) ?? '';

        final status = _parseStatus(statusStr);

        String modelName = 'Unknown';
        final modelMatch = RegExp(r'model:(\S+)').firstMatch(details);
        if (modelMatch != null) {
          modelName = modelMatch.group(1)!;
        }

        final connectionType = serial.contains(':')
            ? ConnectionType.tcp
            : ConnectionType.usb;

        devices.add(
          DeviceEntity(
            id: serial,
            serial: serial,
            modelName: modelName,
            status: status,
            connectionType: connectionType,
          ),
        );
      }
    }
    return devices;
  }

  static DeviceStatus _parseStatus(String status) {
    switch (status) {
      case 'device':
        return DeviceStatus.connected;
      case 'offline':
        return DeviceStatus.offline;
      case 'unauthorized':
        return DeviceStatus.unauthorized;
      default:
        return DeviceStatus.offline;
    }
  }
}
