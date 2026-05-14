import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import '../script_variable.dart';

class OctetVariable implements ScriptVariable {
  @override
  RegExp get regex => RegExp(r'\{I\}');

  @override
  String resolve(String cmd, [Map<String, String>? args]) {
    final serial = args?['serial'];
    if (serial == null || serial.isEmpty) {
      return cmd.replaceAll(regex, CommandInterpolator.wrap('0'));
    }

    final ipOnly = serial.split(':').first;
    final segments = ipOnly.split('.');
    
    String octet = '0';
    if (segments.length == 4) {
      octet = segments[2];
    } else {
      final match = RegExp(r'(\d+)[^\d]*$').firstMatch(serial);
      octet = match?.group(1) ?? '0';
    }

    return cmd.replaceAll(regex, CommandInterpolator.wrap(octet));
  }
}
