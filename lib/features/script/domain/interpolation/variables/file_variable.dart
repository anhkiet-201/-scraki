import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import '../script_variable.dart';

class FileVariable implements ScriptVariable {
  @override
  RegExp get regex => RegExp(r'\{file\}(?:\[(\d+)\])?');

  @override
  String resolve(String cmd, [Map<String, String>? args]) {
    return cmd.replaceAllMapped(regex, (match) {
      final content = args?['file'];
      if (content == null || content.isEmpty) {
        throw ScriptInterpolationException('Đường dẫn file {file} chưa được cung cấp');
      }

      final indexStr = match.group(1);
      if (indexStr != null) {
        final index = int.tryParse(indexStr);
        if (index == null) {
          throw ScriptInterpolationException('Chỉ mục file không hợp lệ: $indexStr');
        }
        final lines = content.split(RegExp(r'\r?\n'));
        if (index < 0 || index >= lines.length) {
          throw ScriptInterpolationException(
              'Chỉ mục file [$index] vượt quá số lượng dòng có sẵn (${lines.length})');
        }
        final normalized = lines[index].replaceAll('\\', '/');
        return CommandInterpolator.wrap(normalized);
      } else {
        final normalized = content.replaceAll('\\', '/');
        return CommandInterpolator.wrap(normalized);
      }
    });
  }
}
