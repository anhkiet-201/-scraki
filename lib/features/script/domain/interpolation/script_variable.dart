
abstract interface class ScriptVariable {
  RegExp get regex;
  String resolve(String cmd, [Map<String, String>? args]);
}

class ScriptInterpolationException implements Exception {
  final String message;
  ScriptInterpolationException(this.message);

  @override
  String toString() => 'ScriptInterpolationException: $message';
}
