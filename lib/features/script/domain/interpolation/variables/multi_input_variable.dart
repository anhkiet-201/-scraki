import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import '../script_variable.dart';

class MultiInputVariable implements ScriptVariable {
  @override
  RegExp get regex => RegExp(r'\{input:([^}]+)\}');

  @override
  String resolve(String cmd, [Map<String, String>? args]) {
    return cmd.replaceAllMapped(regex, (match) {
      final rawKey = match.group(1);
      if (rawKey == null || rawKey.trim().isEmpty) {
        throw ScriptInterpolationException('Tên biến multi input không được để trống');
      }
      final key = rawKey.trim();
      final content = args?[key];
      if (content == null || content.isEmpty) {
        throw ScriptInterpolationException(
            'Dữ liệu đầu vào {input:$key} không được để trống');
      }
      return CommandInterpolator.wrap(content);
    });
  }
}
