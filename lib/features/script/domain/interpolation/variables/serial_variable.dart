import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import '../script_variable.dart';

class SerialVariable implements ScriptVariable {
  @override
  RegExp get regex => RegExp(r'\{SERIAL\}');

  @override
  String resolve(String cmd, [Map<String, String>? args]) {
    final value = args?['serial'] ?? '';
    return cmd.replaceAll(regex, CommandInterpolator.wrap(value));
  }
}
