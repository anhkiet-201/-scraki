import 'package:flutter_test/flutter_test.dart';
import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import 'package:scraki/features/script/domain/interpolation/variables/file_variable.dart';
import 'package:scraki/features/script/domain/interpolation/script_variable.dart';

void main() {
  group('FileVariable Tests', () {
    test('nên nội suy thành công biến {file}', () {
      final interpolator = CommandInterpolator([
        FileVariable(),
      ]);

      final result = interpolator.interpolate(
        'cat {file}',
        {
          'file': 'C:\\path\\to\\my_file.txt',
        },
      );

      // Vì đường dẫn chứa khoảng trắng hoặc ký tự đặc biệt, nó sẽ được bọc nếu CommandInterpolator.wrap thấy cần.
      // C:\path\to\my_file.txt không có khoảng trắng nên wrap sẽ trả về nguyên bản
      expect(result, 'cat C:\\path\\to\\my_file.txt');
    });

    test('nên giữ nguyên đường dẫn chứa khoảng trắng không tự bọc nháy kép', () {
      final interpolator = CommandInterpolator([
        FileVariable(),
      ]);

      final result = interpolator.interpolate(
        'cat {file}',
        {
          'file': 'C:\\My Documents\\file name.txt',
        },
      );

      expect(result, 'cat C:\\My Documents\\file name.txt');
    });

    test('nên ném lỗi nếu thiếu giá trị cho biến {file}', () {
      final interpolator = CommandInterpolator([
        FileVariable(),
      ]);

      expect(
        () => interpolator.interpolate(
          'cat {file}',
          {},
        ),
        throwsA(isA<ScriptInterpolationException>()),
      );
    });

    test('nên ném lỗi nếu giá trị biến {file} bị rỗng', () {
      final interpolator = CommandInterpolator([
        FileVariable(),
      ]);

      expect(
        () => interpolator.interpolate(
          'cat {file}',
          {'file': ''},
        ),
        throwsA(isA<ScriptInterpolationException>()),
      );
    });
  });
}
