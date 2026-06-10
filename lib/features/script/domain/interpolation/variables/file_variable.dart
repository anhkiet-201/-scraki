import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import '../script_variable.dart';

class FileVariable implements ScriptVariable {
  @override
  RegExp get regex => RegExp(r'\{file\}');

  @override
  String resolve(String cmd, [Map<String, String>? args]) {
    return cmd.replaceAllMapped(regex, (match) {
      final content = args?['file'];
      if (content == null || content.isEmpty) {
        throw ScriptInterpolationException('Đường dẫn file {file} chưa được cung cấp');
      }
      return CommandInterpolator.wrap(content);
    });
  }
}
