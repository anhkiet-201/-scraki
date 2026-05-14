
abstract interface class ScriptVariable {
  RegExp get regex;
  String resolve(String cmd, [Map<String, String>? args]);
}
