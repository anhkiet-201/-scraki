import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../utils/logger.dart';

/// Service quản lý ADB binary và cung cấp các ADB commands dùng chung.
///
/// Ưu tiên bundled ADB theo thứ tự:
///   1. macOS: Contents/Resources/adb
///   2. Windows: <exe_dir>/adb.exe
///   3. Fallback: 'adb' từ system PATH (phù hợp khi debug với flutter run)
@lazySingleton
class AdbBinaryService {
  // Cache path sau lần resolve đầu tiên để tránh I/O mỗi lần gọi
  String? _cachedPath;

  // ─── Path resolution ──────────────────────────────────────────────────────

  /// Trả về path đến ADB binary (bundled hoặc system).
  Future<String> get adbPath async {
    _cachedPath ??= await _resolvePath();
    return _cachedPath!;
  }

  static Future<String> _resolvePath() async {
    // 1. macOS: binary nằm trong Contents/Resources/
    if (Platform.isMacOS) {
      final exePath = Platform.resolvedExecutable;
      final contentsDir = File(exePath).parent.parent.path;
      final bundled = p.join(contentsDir, 'Resources', 'adb');
      if (File(bundled).existsSync()) {
        logger.i('[AdbBinaryService] Using bundled ADB: $bundled');
        return bundled;
      }
    }

    // 2. Windows: binary nằm cùng thư mục với .exe
    if (Platform.isWindows) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final bundled = p.join(exeDir, 'adb.exe');
      if (File(bundled).existsSync()) {
        logger.i('[AdbBinaryService] Using bundled ADB: $bundled');
        return bundled;
      }
    }

    // 3. Fallback: dùng system PATH (hữu ích khi flutter run debug)
    final systemBin = Platform.isWindows ? 'adb.exe' : 'adb';
    logger.w(
      '[AdbBinaryService] Bundled ADB not found, falling back to system: $systemBin',
    );
    return systemBin;
  }

  // ─── Core process wrappers ────────────────────────────────────────────────

  /// Chạy lệnh ADB và trả về [ProcessResult]. Dành cho lệnh ngắn, cần output.
  Future<ProcessResult> run(
    List<String> args, {
    String? workingDirectory,
  }) async {
    final bin = await adbPath;
    logger.d('[ADB] run: $bin ${args.join(' ')}');
    return Process.run(bin, args, workingDirectory: workingDirectory);
  }

  /// Khởi động process ADB dạng streaming (long-running). Trả về [Process].
  Future<Process> start(List<String> args) async {
    final bin = await adbPath;
    logger.d('[ADB] start: $bin ${args.join(' ')}');
    return Process.start(bin, args);
  }

  // ─── Device management ────────────────────────────────────────────────────

  /// Liệt kê các device đang kết nối. Trả về raw output của `adb devices -l`.
  Future<String> devicesOutput() async {
    final result = await run(['devices', '-l']);
    return result.stdout as String;
  }

  /// Kết nối đến device qua TCP/IP.
  /// Ném [AdbException] nếu kết nối thất bại.
  Future<void> connectTcp(String ip, int port) async {
    final result = await run(['connect', '$ip:$port']);
    final output = (result.stdout as String).trim();
    if (output.contains('unable') ||
        output.contains('failed') ||
        output.contains('error')) {
      throw AdbException('Connect $ip:$port failed: $output');
    }
    logger.i('[ADB] Connected to $ip:$port — $output');
  }

  /// Ngắt kết nối một device.
  Future<void> disconnect(String serial) async {
    final result = await run(['disconnect', serial]);
    logger.i('[ADB] Disconnected $serial: ${result.stdout}');
  }

  /// Khởi động lại ADB server (kill + start).
  Future<void> restartServer() async {
    await run(['kill-server']);
    await run(['start-server']);
    logger.i('[ADB] Server restarted');
  }

  // ─── Shell commands ───────────────────────────────────────────────────────

  /// Chạy lệnh shell trên device. Tương đương `adb -s <serial> shell <cmd...>`.
  Future<ProcessResult> shell(String serial, List<String> shellArgs) async {
    return run(['-s', serial, 'shell', ...shellArgs]);
  }

  /// Kiểm tra device có đang connected không.
  Future<bool> isDeviceConnected(String serial) async {
    try {
      final result = await run(['-s', serial, 'get-state']);
      return (result.stdout as String).trim() == 'device';
    } catch (_) {
      return false;
    }
  }

  // ─── File transfer ────────────────────────────────────────────────────────

  /// Push file từ host lên device đường dẫn [remotePath].
  /// Ném [AdbException] nếu push thất bại.
  Future<void> push(String serial, String localPath, String remotePath) async {
    final result = await run(['-s', serial, 'push', localPath, remotePath]);
    if (result.exitCode != 0) {
      throw AdbException(
        'adb push failed (exit ${result.exitCode}): ${result.stderr}',
      );
    }
    logger.i('[ADB] Pushed $localPath → $serial:$remotePath');
  }

  // ─── Package management ───────────────────────────────────────────────────

  /// Lấy danh sách package đã cài trên device.
  /// [includeSystemApps] = false → chỉ lấy user apps.
  Future<List<String>> getInstalledPackages(
    String serial, {
    bool includeSystemApps = false,
  }) async {
    final args = [
      '-s',
      serial,
      'shell',
      'pm',
      'list',
      'packages',
      if (!includeSystemApps) '-3',
    ];
    final result = await run(args);
    final output = (result.stdout as String).trim();
    if (output.isEmpty) return [];

    // Output: "package:com.example.app\npackage:..."
    return output
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.trim().replaceFirst('package:', ''))
        .toList();
  }

  /// Lấy label hiển thị của một package.
  /// Trả về [packageName] nếu không tìm được.
  Future<String> getPackageLabel(String serial, String packageName) async {
    try {
      final result = await run([
        '-s',
        serial,
        'shell',
        'dumpsys',
        'package',
        packageName,
      ]);
      final output = (result.stdout as String);
      final match = RegExp(r'applicationLabel[^=]*=(.+)').firstMatch(output);
      if (match?.group(1) != null) {
        return match!.group(1)!.trim();
      }
    } catch (e) {
      logger.w('[ADB] getPackageLabel fallback for $packageName: $e');
    }
    return packageName;
  }

  /// Mở app qua package name bằng `monkey`.
  Future<void> launchApp(String serial, String packageName) async {
    final result = await run([
      '-s',
      serial,
      'shell',
      'monkey',
      '-p',
      packageName,
      '1',
    ]);
    final output = result.stdout as String;
    if (output.contains('monkey: not found') ||
        output.contains('does not exist') ||
        output.contains('No activities found')) {
      throw AdbException('Failed to launch $packageName: $output');
    }
  }

  // ─── Input ────────────────────────────────────────────────────────────────

  /// Gửi keycode đến device. [keycode] là số nguyên (vd: 26 = POWER).
  Future<void> sendKeyEvent(String serial, int keycode) async {
    await run(['-s', serial, 'shell', 'input', 'keyevent', '$keycode']);
  }

  /// Bật/tắt màn hình (KEYCODE_POWER = 26).
  Future<void> sendPowerKey(String serial) => sendKeyEvent(serial, 26);

  // ─── Forward / Reverse ───────────────────────────────────────────────────

  /// `adb -s <serial> forward tcp:<local> tcp:<remote>`
  Future<void> forward(String serial, int localPort, int remotePort) async {
    final result = await run([
      '-s',
      serial,
      'forward',
      'tcp:$localPort',
      'tcp:$remotePort',
    ]);
    if (result.exitCode != 0) {
      throw AdbException('adb forward failed: ${result.stderr}');
    }
  }

  /// Xóa một forward rule.
  Future<void> removeForward(String serial, int localPort) async {
    await run(['-s', serial, 'forward', '--remove', 'tcp:$localPort']);
  }
}

// ─── Exception ────────────────────────────────────────────────────────────────

/// Exception riêng cho các lỗi ADB để tách biệt với [ServerException].
class AdbException implements Exception {
  final String message;

  const AdbException(this.message);

  @override
  String toString() => 'AdbException: $message';
}
