import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import '../script_variable.dart';

class MultiInputVariable implements ScriptVariable {
  @override
  RegExp get regex => RegExp(r'\{input:([^}]+)\}(?:\[(\d+)\])?');

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

      final indexStr = match.group(2);
      if (indexStr != null) {
        final index = int.tryParse(indexStr);
        if (index == null) {
          throw ScriptInterpolationException('Chỉ mục input không hợp lệ: $indexStr');
        }
        final lines = content.split(RegExp(r'\r?\n'));
        if (index < 0 || index >= lines.length) {
          throw ScriptInterpolationException(
              'Chỉ mục input [$index] vượt quá số lượng dòng có sẵn (${lines.length})');
        }
        return CommandInterpolator.wrap(lines[index]);
      } else {
        return CommandInterpolator.wrap(content);
      }
    });
  }
}
