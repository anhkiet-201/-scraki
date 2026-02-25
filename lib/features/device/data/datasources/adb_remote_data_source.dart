import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/adb_binary_service.dart';

abstract class IAdbRemoteDataSource {
  Future<String> getConnectedDevicesOutput();
  Future<void> connectTcp(String ip, int port);
  Future<void> disconnect(String serial);
  Future<void> restartServer();

  /// Lấy danh sách packages đã cài đặt trên device.
  /// [includeSystemApps] = false → chỉ lấy user apps.
  Future<List<String>> getInstalledPackages(
    String serial, {
    bool includeSystemApps = false,
  });

  /// Lấy label hiển thị của một package.
  Future<String> getPackageLabel(String serial, String packageName);

  /// Launch app bằng package name.
  Future<void> launchApp(String serial, String packageName);

  /// Gửi keycode POWER (26) để bật/tắt màn hình.
  Future<void> sendPowerKey(String serial);
}

@LazySingleton(as: IAdbRemoteDataSource)
class AdbRemoteDataSourceImpl implements IAdbRemoteDataSource {
  final AdbBinaryService _adb;

  AdbRemoteDataSourceImpl(this._adb);

  @override
  Future<String> getConnectedDevicesOutput() async {
    try {
      return await _adb.devicesOutput();
    } catch (e) {
      throw ServerException('Failed to list ADB devices: $e');
    }
  }

  @override
  Future<void> connectTcp(String ip, int port) async {
    try {
      await _adb.connectTcp(ip, port);
    } on AdbException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to connect $ip:$port: $e');
    }
  }

  @override
  Future<void> disconnect(String serial) async {
    try {
      await _adb.disconnect(serial);
    } catch (e) {
      throw ServerException('Failed to disconnect $serial: $e');
    }
  }

  @override
  Future<void> restartServer() async {
    try {
      await _adb.restartServer();
    } catch (e) {
      throw ServerException('Failed to restart ADB server: $e');
    }
  }

  @override
  Future<List<String>> getInstalledPackages(
    String serial, {
    bool includeSystemApps = false,
  }) async {
    try {
      return await _adb.getInstalledPackages(
        serial,
        includeSystemApps: includeSystemApps,
      );
    } catch (e) {
      throw ServerException('Failed to get installed packages: $e');
    }
  }

  @override
  Future<String> getPackageLabel(String serial, String packageName) async {
    // Không ném exception — trả về packageName làm fallback
    return _adb.getPackageLabel(serial, packageName);
  }

  @override
  Future<void> launchApp(String serial, String packageName) async {
    try {
      await _adb.launchApp(serial, packageName);
    } on AdbException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to launch app $packageName: $e');
    }
  }

  @override
  Future<void> sendPowerKey(String serial) async {
    try {
      await _adb.sendPowerKey(serial);
    } catch (e) {
      throw ServerException('Failed to send power key to $serial: $e');
    }
  }
}
