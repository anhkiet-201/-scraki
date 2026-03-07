import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:process_run/shell.dart';
import '../../../../core/error/exceptions.dart';

abstract class IAdbRemoteDataSource {
  Future<String> getConnectedDevicesOutput();
  Future<void> connectTcp(String ip, int port);
  Future<void> disconnect(String serial);
  Future<void> restartServer();

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

  /// Gửi keycode bất kỳ qua ADB (dùng giả lập Navigation Buttons khi control disabled)
  /// [serial] - Device serial number
  /// [keyCode] - Mã phím Android KeyEvent
  Future<void> sendKeyEvent(String serial, int keyCode);

  /// Dump ui and extract email
  /// [serial] - Device serial number
  Future<String?> dumpUiAndExtractEmail(String serial);

  /// Nhập văn bản vào thiết bị qua ADB
  /// [serial] - Device serial number
  /// [text] - Nội dung văn bản
  Future<void> inputText(String serial, String text);

  /// Lấy tên thiết bị do người dùng đặt qua Android settings
  /// [serial] - Device serial number
  /// Returns: Tên thiết bị (e.g. "Pixel 6 của Kiệt"), hoặc null nếu không lấy được
  Future<String?> getDeviceName(String serial);

  /// Mở trang Inbox (hộp thư đến) trong TikTok
  /// Thử lần lượt: Global → Asia → Lite
  /// [serial] - Device serial number
  Future<void> openTikTokInbox(String serial);

  /// Mở trang Profile (Hồ sơ) trong TikTok
  /// Sử dụng Deep Link vào thẳng tab Hồ Sơ (Mine)
  /// [serial] - Device serial number
  Future<void> openTikTokProfile(String serial);
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
    // Dùng Process.run thay vì _shell.run vì Shell có internal queue
    // serialize các lệnh tuần tự — khiến Future.wait không thực sự parallel.
    // Process.run tạo process độc lập, cho phép nhiều kết nối chạy đồng thời.
    try {
      final result = await Process.run('adb', ['connect', '$ip:$port']);
      final output = (result.stdout as String).trim();
      if (output.contains('unable') || output.contains('failed')) {
        throw ServerException(output);
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to connect $ip:$port: $e');
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
  Future<void> restartServer() async {
    try {
      await _shell.run('adb kill-server');
      await _shell.run('adb start-server');
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
      final result = await Process.run('adb', [
        '-s',
        serial,
        'shell',
        'pm',
        'list',
        'packages',
        if (!includeSystemApps) '-3',
      ]);
      final output = (result.stdout as String?)?.trim() ?? '';

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
    try {
      final result = await Process.run('adb', [
        '-s',
        serial,
        'shell',
        'dumpsys',
        'package',
        packageName,
      ]);
      final output = (result.stdout as String?) ?? '';

      if (output.isEmpty) return packageName;

      for (final line in output.split('\n')) {
        if (line.toLowerCase().contains('applicationlabel')) {
          final match = RegExp(r'applicationLabel[^=]*=(.+)').firstMatch(line);
          if (match != null && match.group(1) != null) {
            return match.group(1)!.trim();
          }
        }
      }

      return packageName;
    } catch (_) {
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

  @override
  Future<void> sendKeyEvent(String serial, int keyCode) async {
    final cmd = 'adb -s $serial shell input keyevent $keyCode';
    try {
      await _shell.run(cmd);
    } catch (e) {
      // Ignored for non-critical navigation keys
    }
  }

  @override
  Future<String?> dumpUiAndExtractEmail(String serial) async {
    const remotePath = '/sdcard/window_dump.xml';

    try {
      // 1. Dump UI on device
      final dumpResult = await _shell.run(
        'adb -s $serial shell uiautomator dump $remotePath',
      );
      if (dumpResult.outText.contains('ERROR')) {
        throw ServerException('Failed to dump UI: ${dumpResult.outText}');
      }

      // 2. Pull the file to a safe system temp directory
      final localPath = '${Directory.systemTemp.path}/window_dump_$serial.xml';

      await _shell.run('adb -s $serial pull $remotePath $localPath');

      final file = File(localPath);
      if (!await file.exists()) {
        throw ServerException(
          'Dump XML file not found after pull for device $serial',
        );
      }

      final content = await file.readAsString();

      final regex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
      final match = regex.firstMatch(content);

      return match?.group(0);
    } catch (e) {
      throw ServerException('Failed to dump UI and extract email: $e');
    } finally {
      // 3. Clean up remote and local file safely
      final localPath = '${Directory.systemTemp.path}/window_dump_$serial.xml';
      try {
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      try {
        await _shell.run('adb -s $serial shell rm $remotePath');
      } catch (_) {}
    }
  }

  @override
  Future<void> inputText(String serial, String text) async {
    final cmd = 'adb -s $serial shell input text "$text"';
    try {
      await _shell.run(cmd);
    } catch (e) {
      throw ServerException('Failed to input text: $e');
    }
  }

  @override
  Future<String?> getDeviceName(String serial) async {
    try {
      final result = await Process.run('adb', [
        '-s',
        serial,
        'shell',
        'settings',
        'get',
        'global',
        'device_name',
      ]);
      final name = (result.stdout as String).trim();
      // Nếu chưa set, Android trả về 'null' (string)
      if (name.isEmpty || name == 'null') return null;
      return name;
    } catch (_) {
      return null;
    }
  }

  /// Cấu hình chính xác Scheme mở Inbox (Notification) cho từng phiên bản TikTok
  /// Gán tĩnh theo từng package để tránh lỗi app nhận bừa Scheme nhưng không chuyển tab.
  static const _tikTokVariants = [
    (
      pkg: 'com.zhiliaoapp.musically', // Global
      scheme: 'snssdk1233://notification',
    ),
    (
      pkg: 'com.ss.android.ugc.trill', // Asia
      scheme: 'snssdk1180://notification',
    ),
    (
      pkg: 'com.zhiliaoapp.musically.go', // Global Lite
      scheme: 'snssdk1180://notification', // User confirmed
    ),
    (
      pkg: 'com.ss.android.ugc.trillgo', // Asia Lite
      scheme: 'snssdk1180://notification',
    ),
  ];

  @override
  Future<void> openTikTokInbox(String serial) async {
    // Lấy trước danh sách package chính xác đã cài để check Exact Match
    // Tránh lỗi pm list search theo Substring (vd: tìm musically ra luôn musically.go)
    final installedPkgs = await getInstalledPackages(serial);

    for (final variant in _tikTokVariants) {
      if (!installedPkgs.contains(variant.pkg)) continue;

      try {
        await Process.run('adb', [
          '-s',
          serial,
          'shell',
          'am',
          'start',
          '-W',
          '-a',
          'android.intent.action.VIEW',
          '-d',
          variant.scheme,
          '-p',
          variant.pkg,
        ]);
      } catch (_) {
        // Bỏ qua lỗi thực thi ADB
      }
      return;
    }

    throw ServerException('TikTok is not installed on device $serial');
  }

  /// Cấu hình chính xác Scheme mở Profile (Hồ sơ) cho từng phiên bản TikTok
  static const _profileVariants = [
    (
      pkg: 'com.zhiliaoapp.musically', // Global
      scheme: 'snssdk1233://profile',
    ),
    (
      pkg: 'com.ss.android.ugc.trill', // Asia
      scheme: 'snssdk1180://profile',
    ),
    (
      pkg: 'com.zhiliaoapp.musically.go', // Global Lite
      scheme: 'snssdk1180://profile',
    ),
    (
      pkg: 'com.ss.android.ugc.trillgo', // Asia Lite
      scheme: 'snssdk1180://profile',
    ),
  ];

  @override
  Future<void> openTikTokProfile(String serial) async {
    final installedPkgs = await getInstalledPackages(serial);

    for (final variant in _profileVariants) {
      if (!installedPkgs.contains(variant.pkg)) continue;

      try {
        await Process.run('adb', [
          '-s',
          serial,
          'shell',
          'am',
          'start',
          '-W',
          '-a',
          'android.intent.action.VIEW',
          '-d',
          variant.scheme,
          '-p',
          variant.pkg,
        ]);
      } catch (_) {
        // Bỏ qua lỗi thực thi ADB
      }
      return;
    }

    throw ServerException('TikTok is not installed on device $serial');
  }
}
