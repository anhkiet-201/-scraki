import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/script_entity.dart';

abstract class ScriptRepository {
  /// Lắng nghe realtime danh sách script (Cloud Firestore)
  Stream<Either<Failure, List<ScriptEntity>>> watchAllScripts();

  /// Lấy toàn bộ danh sách script (Một lần)
  Future<Either<Failure, List<ScriptEntity>>> getAllScripts();

  /// Lưu hoặc cập nhật một script
  Future<Either<Failure, void>> saveScript(ScriptEntity script);

  /// Xóa một script theo ID
  Future<Either<Failure, void>> deleteScript(String id);

  /// Thực thi một lệnh ADB shell trên thiết bị
  /// [serial] - Serial number của thiết bị
  /// [command] - Lệnh adb shell cần chạy (ví dụ: "ls /sdcard")
  /// Returns: Output của lệnh
  Future<Either<Failure, String>> executeSingleCommand(String serial, String command);

  /// Thực thi một lệnh ADB shell và trả về luồng dữ liệu realtime
  Stream<Either<Failure, String>> executeSingleCommandStream(String serial, String command);

  /// Thực thi một script (danh sách lệnh) trên thiết bị
  Stream<Either<Failure, String>> executeScriptStream(String serial, ScriptEntity script);
}
