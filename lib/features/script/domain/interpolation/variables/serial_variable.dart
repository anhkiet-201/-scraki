import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import '../script_variable.dart';

class SerialVariable implements ScriptVariable {
  @override
  RegExp get regex => RegExp(r'\{SERIAL\}');

  @override
  String resolve(String cmd, [Map<String, String>? args]) {
    final value = args?['serial'];
    if (value == null || value.isEmpty) {
      throw ScriptInterpolationException('Thiếu thông tin Serial thiết bị');
    }
    return cmd.replaceAll(regex, CommandInterpolator.wrap(value));
  }
}
