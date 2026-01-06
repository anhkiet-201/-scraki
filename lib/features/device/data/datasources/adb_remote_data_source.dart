import 'package:injectable/injectable.dart';
import 'package:process_run/shell.dart';
import '../../../../core/error/exceptions.dart';

abstract class IAdbRemoteDataSource {
  Future<String> getConnectedDevicesOutput();
  Future<void> connectTcp(String ip, int port);
  Future<void> disconnect(String serial);

  /// Lấy danh sách packages đã cài đặt trên device
  /// [serial] - Device serial number
  /// [includeSystemApps] - Nếu true, bao gồm cả system apps. Mặc định false (chỉ user apps)
  /// Returns: List of package names (e.g., ["com.android.chrome", "com.example.app"])
  Future<List<String>> getInstalledPackages(
    String serial, {
    bool includeSystemApps = false,
  });

  /// Lấy thông tin chi tiết của một package
  /// [serial] - Device serial number
  /// [packageName] - Package name của app
  /// Returns: AppInfo object với label và launch activity
  /// Throws: ServerException nếu package không tồn tại hoặc lỗi ADB
  Future<String> getPackageLabel(String serial, String packageName);

  /// Launch app bằng package name
  /// [serial] - Device serial number
  /// [packageName] - Package name của app cần mở
  /// Throws: ServerException nếu không launch được app
  Future<void> launchApp(String serial, String packageName);

  /// Gửi keycode POWER (26) để bật/tắt màn hình
  /// [serial] - Device serial number
  Future<void> sendPowerKey(String serial);
}

@LazySingleton(as: IAdbRemoteDataSource)
class AdbRemoteDataSourceImpl implements IAdbRemoteDataSource {
  final Shell _shell;
  static const _cmdListDevices = 'adb devices -l';

  AdbRemoteDataSourceImpl() : _shell = Shell();

  @override
  Future<String> getConnectedDevicesOutput() async {
    try {
      final result = await _shell.run(_cmdListDevices);
      return result.outText;
    } catch (e) {
      throw ServerException('Failed to execute $_cmdListDevices: $e');
    }
  }

  @override
  Future<void> connectTcp(String ip, int port) async {
    final cmd = 'adb connect $ip:$port';
    try {
      final result = await _shell.run(cmd);
      final output = result.outText;
      if (output.runes.contains("unable") || output.contains("failed")) {
        throw ServerException(output);
      }
    } catch (e) {
      if (e is ServerException) rethrow; // rethrow formatted exception
      throw ServerException('Failed to execute $cmd: $e');
    }
  }

  @override
  Future<void> disconnect(String serial) async {
    final cmd = 'adb disconnect $serial';
    try {
      await _shell.run(cmd);
    } catch (e) {
      throw ServerException('Failed to execute $cmd: $e');
    }
  }

  @override
  Future<List<String>> getInstalledPackages(
    String serial, {
    bool includeSystemApps = false,
  }) async {
    // -3 flag để chỉ lấy user-installed apps (third-party)
    // Không dùng -3 để lấy tất cả packages (bao gồm system)
    final flag = includeSystemApps ? '' : '-3';
    final cmd = 'adb -s $serial shell pm list packages $flag';

    try {
      final result = await _shell.run(cmd);
      final output = result.outText.trim();

      if (output.isEmpty) {
        return [];
      }

      // Output format: "package:com.example.app\npackage:com.another.app"
      // Parse và remove prefix "package:"
      return output
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.trim().replaceFirst('package:', ''))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get installed packages: $e');
    }
  }

  @override
  Future<String> getPackageLabel(String serial, String packageName) async {
    // Sử dụng dumpsys để lấy applicationLabel
    final cmd =
        'adb -s $serial shell dumpsys package $packageName | grep -i "applicationLabel"';

    try {
      final result = await _shell.run(cmd);
      final output = result.outText.trim();

      if (output.isEmpty) {
        // Fallback: return package name nếu không tìm được label
        return packageName;
      }

      // Output format: "applicationLabel=App Name" hoặc "applicationLabel-en=App Name"
      // Parse label từ output
      final match = RegExp(r'applicationLabel[^=]*=(.+)').firstMatch(output);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }

      // Fallback
      return packageName;
    } catch (e) {
      // Nếu lỗi, return package name làm label
      return packageName;
    }
  }

  @override
  Future<void> launchApp(String serial, String packageName) async {
    // Sử dụng monkey command để launch app
    // monkey -p <package> 1 sẽ mở main activity của app
    final cmd = 'adb -s $serial shell monkey -p $packageName 1';

    try {
      final result = await _shell.run(cmd);
      final output = result.outText;

      // Kiểm tra lỗi thường gặp
      if (output.contains('monkey: not found') ||
          output.contains('does not exist') ||
          output.contains('No activities found')) {
        throw ServerException('Failed to launch app $packageName: $output');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to launch app $packageName: $e');
    }
  }

  @override
  Future<void> sendPowerKey(String serial) async {
    // KEYCODE_POWER = 26
    final cmd = 'adb -s $serial shell input keyevent 26';

    try {
      await _shell.run(cmd);
    } catch (e) {
      throw ServerException('Failed to send power key: $e');
    }
  }
}
