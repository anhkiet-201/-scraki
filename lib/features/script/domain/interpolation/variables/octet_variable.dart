import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import '../script_variable.dart';

class OctetVariable implements ScriptVariable {
  @override
  RegExp get regex => RegExp(r'\{I\}');

  @override
  String resolve(String cmd, [Map<String, String>? args]) {
    final serial = args?['serial'];
    if (serial == null || serial.isEmpty) {
      throw ScriptInterpolationException('Thiếu thông tin Serial để lấy Octet');
    }

    final ipOnly = serial.split(':').first;
    final segments = ipOnly.split('.');

    String? octet;
    if (segments.length == 4) {
      octet = segments[2];
    } else {
      final match = RegExp(r'(\d+)[^\d]*$').firstMatch(serial);
      octet = match?.group(1);
    }

    if (octet == null) {
      throw ScriptInterpolationException(
          'Không thể xác định octet từ serial: $serial');
    }

    return cmd.replaceAll(regex, CommandInterpolator.wrap(octet));
  }
}
