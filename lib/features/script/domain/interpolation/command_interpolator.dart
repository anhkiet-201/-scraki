import 'script_variable.dart';

class CommandInterpolator {
  final List<ScriptVariable> _variables;

  // Sử dụng ký tự Unicode Private Use Area (PUA) để đánh dấu an toàn
  // Các ký tự này sẽ không bao giờ xung đột với lệnh Bash hoặc nội dung text thông thường
  static const String wrapStart = '\uE000';
  static const String wrapEnd = '\uE001';

  CommandInterpolator(this._variables);

  /// Bọc giá trị an toàn
  static String wrap(String value) {
    return '$wrapStart$value$wrapEnd';
  }

  String interpolate(String command, [Map<String, String>? args]) {
    String result = command;

    for (final variable in _variables) {
      if (variable.regex.hasMatch(result)) {
        result = variable.resolve(result, args);
      }
    }

    return _unwrapVariables(result);
  }

  String _unwrapVariables(String input) {
    if (input.isEmpty) {
      return input;
    }
    // Dọn dẹp tất cả các ký tự đánh dấu còn sót lại
    return input.replaceAll(wrapStart, '').replaceAll(wrapEnd, '');
  }
}
