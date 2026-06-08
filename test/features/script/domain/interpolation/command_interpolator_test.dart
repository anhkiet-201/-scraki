import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import 'package:scraki/features/script/domain/interpolation/variables/random_variable.dart';

class FakeRandom implements Random {
  final List<int> values;
  int _index = 0;

  FakeRandom(this.values);

  @override
  int nextInt(int max) {
    final value = values[_index];
    _index = (_index + 1) % values.length;
    return value;
  }

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}

void main() {
  group('RandomVariable Tests', () {
    test('nên nội suy {random(max)} thành số ngẫu nhiên chính xác', () {
      final fakeRandom = FakeRandom([5]);
      final interpolator = CommandInterpolator([
        RandomVariable(random: fakeRandom),
      ]);

      final result = interpolator.interpolate('echo {random(10)}');
      expect(result, 'echo 5');
    });

    test('nên nội suy nhiều biến {random(max)} trong cùng câu lệnh', () {
      final fakeRandom = FakeRandom([3, 75]);
      final interpolator = CommandInterpolator([
        RandomVariable(random: fakeRandom),
      ]);

      final result = interpolator.interpolate('echo {random(5)} {random(100)}');
      expect(result, 'echo 3 75');
    });

    test('không nên thay đổi các chuỗi không khớp định dạng', () {
      final interpolator = CommandInterpolator([
        RandomVariable(),
      ]);

      final result1 = interpolator.interpolate('echo {random(abc)}');
      expect(result1, 'echo {random(abc)}');

      final result2 = interpolator.interpolate('echo {random()}');
      expect(result2, 'echo {random()}');
    });
  });
}
