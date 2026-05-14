import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import '../script_variable.dart';

class InputVariable implements ScriptVariable {
  @override
  RegExp get regex => RegExp(r'\{input\}');

  @override
  String resolve(String cmd, [Map<String, String>? args]) {
    return cmd.replaceAllMapped(regex, (match) {
      final content = args?['input'];
      if (content == null || content.isEmpty) {
        throw ScriptInterpolationException(
            'Dữ liệu đầu vào {input} không được để trống');
      }
      return CommandInterpolator.wrap(content);
    });
  }
}
