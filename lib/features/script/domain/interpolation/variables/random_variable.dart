import 'dart:math';
import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import 'package:scraki/features/script/domain/interpolation/script_variable.dart';

class RandomVariable implements ScriptVariable {
  final Random _random;

  RandomVariable({Random? random}) : _random = random ?? Random();

  @override
  RegExp get regex => RegExp(r'\{random\((\d+)\)\}');

  @override
  String resolve(String cmd, [Map<String, String>? args]) {
    return cmd.replaceAllMapped(regex, (match) {
      final maxStr = match.group(1);
      if (maxStr == null) {
        throw ScriptInterpolationException('Thiếu giá trị số ngẫu nhiên tối đa');
      }

      final maxVal = int.tryParse(maxStr);
      if (maxVal == null) {
        throw ScriptInterpolationException('Giá trị tối đa không hợp lệ: $maxStr');
      }

      // Sinh số ngẫu nhiên từ 0 đến maxVal (bao gồm cả maxVal)
      final randomVal = _random.nextInt(maxVal + 1);
      return CommandInterpolator.wrap(randomVal.toString());
    });
  }
}
