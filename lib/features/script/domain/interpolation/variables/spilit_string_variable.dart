import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import 'package:scraki/features/script/domain/interpolation/script_variable.dart';

class SplitStringVariable implements ScriptVariable {
  @override
  final RegExp regex = RegExp(
    '${CommandInterpolator.wrapStart}([^${CommandInterpolator.wrapEnd}]*)${CommandInterpolator.wrapEnd}\\[(?:${CommandInterpolator.wrapStart})?(\\d+)(?:${CommandInterpolator.wrapEnd})?\\]',
  );

  @override
  String resolve(String cmd, [Map<String, String>? args]) {
    return cmd.replaceAllMapped(regex, (match) {
      final content = match.group(1) ?? '';
      final indexStr = match.group(2);

      if (indexStr != null) {
        try {
          final index = int.parse(indexStr);
          final lines = content.split(RegExp(r'\r?\n'));
          if (index >= 0 && index < lines.length) {
            return CommandInterpolator.wrap(lines[index]);
          }
        } catch (_) {}
      }
      return CommandInterpolator.wrap('');
    });
  }
}