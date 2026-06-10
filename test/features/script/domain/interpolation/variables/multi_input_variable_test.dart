import 'package:flutter_test/flutter_test.dart';
import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import 'package:scraki/features/script/domain/interpolation/variables/input_variable.dart';
import 'package:scraki/features/script/domain/interpolation/variables/multi_input_variable.dart';
import 'package:scraki/features/script/domain/interpolation/script_variable.dart';

void main() {
  group('MultiInputVariable Tests', () {
    test('nên nội suy thành công nhiều biến {input:tên_biến}', () {
      final interpolator = CommandInterpolator([
        MultiInputVariable(),
      ]);

      final result = interpolator.interpolate(
        'echo "User: {input:username}" -p "{input:password}"',
        {
          'username': 'admin',
          'password': '123',
        },
      );

      expect(result, 'echo "User: admin" -p "123"');
    });

    test('nên ném lỗi nếu thiếu giá trị cho biến {input:tên_biến}', () {
      final interpolator = CommandInterpolator([
        MultiInputVariable(),
      ]);

      expect(
        () => interpolator.interpolate(
          'echo "User: {input:username}"',
          {'password': '123'},
        ),
        throwsA(isA<ScriptInterpolationException>()),
      );
    });

    test('nên ném lỗi nếu giá trị biến bị rỗng', () {
      final interpolator = CommandInterpolator([
        MultiInputVariable(),
      ]);

      expect(
        () => interpolator.interpolate(
          'echo "User: {input:username}"',
          {'username': ''},
        ),
        throwsA(isA<ScriptInterpolationException>()),
      );
    });

    test('tránh xung đột: {input} và {input:username} nên hoạt động độc lập và song song', () {
      final interpolator = CommandInterpolator([
        InputVariable(),
        MultiInputVariable(),
      ]);

      // Trường hợp có cả hai biến
      final result = interpolator.interpolate(
        'echo {input} user={input:username} pass={input:password}',
        {
          'input': 'global_data',
          'username': 'alice',
          'password': 'secret_password',
        },
      );

      expect(result, 'echo global_data user=alice pass=secret_password');
    });
    test('nên nội suy thành công kể cả khi biến có chứa khoảng trắng xung quanh tên', () {
      final interpolator = CommandInterpolator([
        MultiInputVariable(),
      ]);

      final result = interpolator.interpolate(
        'echo "User: {input: username }"',
        {
          'username': 'admin',
        },
      );

      expect(result, 'echo "User: admin"');
    });
  });
}
