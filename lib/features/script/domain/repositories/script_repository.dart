import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/script_entity.dart';

abstract class ScriptRepository {
  /// Lấy danh sách script mẫu có sẵn
  Future<Either<Failure, List<ScriptEntity>>> getPredefinedScripts();

  /// Thực thi một lệnh ADB shell trên thiết bị
  /// [serial] - Serial number của thiết bị
  /// [command] - Lệnh adb shell cần chạy (ví dụ: "ls /sdcard")
  /// Returns: Output của lệnh
  Future<Either<Failure, String>> executeSingleCommand(String serial, String command);

  /// Thực thi một script (danh sách lệnh) trên thiết bị
  Future<Either<Failure, String>> executeScript(String serial, ScriptEntity script);
}
