import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import 'package:scraki/features/script/domain/interpolation/script_variable.dart';

class IndexVariable implements ScriptVariable {
  @override
  RegExp get regex => RegExp(r'\{index\}');

  @override
  String resolve(String cmd, [Map<String, String>? args]) {
    return cmd.replaceAllMapped(regex, (match) {
      final content = args?['index'];
      if (content == null || content.isEmpty) {
        throw ScriptInterpolationException('Thiếu thông tin Index thiết bị');
      }
      return CommandInterpolator.wrap(content);
    });
  }
}
