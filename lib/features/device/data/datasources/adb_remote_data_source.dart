import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import 'package:injectable/injectable.dart';
import 'package:process_run/shell.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/logger.dart';

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

  /// Mở trình cài đặt gói (Package Installer) cho một file APK đã được push lên thiết bị
  Future<void> openPackageInstaller(String serial, String remotePath);

  /// Cài đặt trực tiếp file APK từ máy tính lên thiết bị và theo dõi tiến trình
  /// [serial] - Device serial number
  /// [localPath] - Đường dẫn file APK trên máy tính
  /// [onProgress] - Callback khi % thay đổi (0.0 đến 1.0)
  /// [onStatus] - Callback khi trạng thái thay đổi (vd: "Streaming...", "Installing...")
  Future<void> installPackage(
    String serial,
    String localPath, {
    void Function(double progress)? onProgress,
    void Function(String status)? onStatus,
  });
  
  /// Cài đặt file XAPK (bao gồm Split APKs và OBB)
  Future<void> installXapk(
    String serial,
    String localPath, {
    void Function(double progress)? onProgress,
    void Function(String status)? onStatus,
  });

  /// Chạy một lệnh shell tùy ý trên thiết bị
  /// [serial] - Serial number của thiết bị
  /// [command] - Lệnh shell (ví dụ: "ls /sdcard")
  /// Returns: stdout của lệnh
  Future<String> runShellCommand(String serial, String command);

  /// Chạy một lệnh shell và trả về luồng dữ liệu realtime
  Stream<String> runShellCommandStream(String serial, String command);

  /// Chạy một lệnh ADB nguyên bản (không bọc trong shell) và trả về luồng dữ liệu realtime
  /// [adbCommand] - Phần lệnh sau 'adb' (ví dụ: "install -r app.apk")
  Stream<String> runRawAdbCommandStream(String serial, String adbCommand);
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

  @override
  Future<void> openPackageInstaller(String serial, String remotePath) async {
    try {
      logger.i('[ADB] Attempting to open package installer for: $remotePath on $serial');
      
      // 1. Kiểm tra file có tồn tại không
      final lsResult = await Process.run('adb', ['-s', serial, 'shell', 'ls', "'$remotePath'"]);
      if (lsResult.exitCode != 0) {
        logger.e('[ADB] File not found on device: $remotePath');
        throw ServerException('File APK không tồn tại trên thiết bị tại đường dẫn: $remotePath');
      }

      // Đợi một chút để OS ổn định
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // 2. Danh sách các Intent/Activity có thể mở trình cài đặt
      final commands = [
        // Cách 1: Intent chuẩn + NEW_TASK flag (0x10000000 = 268435456) + --user 0
        ['-a', 'android.intent.action.VIEW', '-d', 'file://$remotePath', '-t', 'application/vnd.android.package-archive', '-f', '268435456', '--user', '0'],
        
        // Cách 2: Thử với đường dẫn /data/local/tmp/ nếu push vào đó (thường có quyền truy cập tốt hơn)
        if (remotePath.startsWith('/data/local/tmp/'))
          ['-a', 'android.intent.action.VIEW', '-d', 'file://$remotePath', '-t', 'application/vnd.android.package-archive', '-f', '268435456', '--user', '0'],

        // Cách 3: Google Package Installer
        ['-n', 'com.google.android.packageinstaller/com.android.packageinstaller.PackageInstallerActivity', '-a', 'android.intent.action.VIEW', '-d', 'file://$remotePath', '-t', 'application/vnd.android.package-archive', '-f', '268435456', '--user', '0'],
        
        // Cách 4: Samsung/AOSP Package Installer
        ['-n', 'com.android.packageinstaller/.PackageInstallerActivity', '-a', 'android.intent.action.VIEW', '-d', 'file://$remotePath', '-t', 'application/vnd.android.package-archive', '-f', '268435456', '--user', '0'],
        
        // Cách 5: Intent ACTION_INSTALL_PACKAGE
        ['-a', 'android.intent.action.INSTALL_PACKAGE', '-d', 'file://$remotePath', '-f', '268435456', '--user', '0'],
      ];

      bool success = false;
      for (final args in commands) {
        logger.i('[ADB] Trying command: am start ${args.join(' ')}');
        final result = await Process.run('adb', [
          '-s',
          serial,
          'shell',
          'am',
          'start',
          ...args,
        ]);

        final out = (result.stdout as String).trim();
        final err = (result.stderr as String).trim();
        
        if (out.contains('Starting: Intent') && !out.contains('Error') && !out.contains('unable to resolve')) {
          logger.i('[ADB] Command successful: $out');
          success = true;
          break;
        } else {
          logger.w('[ADB] Command failed: $out $err');
        }
      }

      if (!success) {
        throw ServerException('Không thể mở trình cài đặt gói trên thiết bị này. Hãy thử cài đặt thủ công trong thư mục Download.');
      }
    } catch (e) {
      logger.e('[ADB] Error opening package installer', error: e);
      if (e is ServerException) rethrow;
      throw ServerException('Lỗi khi mở trình cài đặt APK: $e');
    }
  }

  @override
  Future<void> installPackage(
    String serial,
    String localPath, {
    void Function(double progress)? onProgress,
    void Function(String status)? onStatus,
  }) async {
    try {
      logger.i('[ADB] Simple install: $localPath on $serial');
      final result = await Process.run('adb', ['-s', serial, 'install', '-r', localPath]);
      
      final out = (result.stdout as String).trim();
      if (!out.contains('Success') && result.exitCode != 0) {
        throw ServerException('Cài đặt thất bại: $out ${result.stderr}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Lỗi cài đặt: $e');
    }
  }

  @override
  Future<void> installXapk(
    String serial,
    String localPath, {
    void Function(double progress)? onProgress,
    void Function(String status)? onStatus,
  }) async {
    Directory? tempDir;
    try {
      onStatus?.call('Đang giải nén XAPK...');
      final file = File(localPath);
      if (!await file.exists()) throw ServerException('File XAPK không tồn tại');

      // 1. Tạo thư mục tạm và giải nén
      tempDir = await Directory.systemTemp.createTemp('xapk_install_');
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File(p.join(tempDir.path, filename))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
      }

      // 2. Tìm danh sách APK và OBB
      final apkFiles = <String>[];
      final obbFiles = <String>[];
      String? packageName;

      // Quét thư mục tạm
      await for (final entity in tempDir.list(recursive: true)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (ext == '.apk') {
            apkFiles.add(entity.path);
          } else if (ext == '.obb') {
            obbFiles.add(entity.path);
          } else if (p.basename(entity.path) == 'manifest.json') {
            // Đọc package name từ manifest nếu cần cho OBB
            try {
              final content = await entity.readAsString();
              final json = jsonDecode(content);
              packageName = json['package_name'] as String?;
            } catch (_) {}
          }
        }
      }

      if (apkFiles.isEmpty) throw ServerException('Không tìm thấy file APK trong gói XAPK');

      // 3. Cài đặt APK
      onStatus?.call('Đang cài đặt APK (${apkFiles.length} files)...');
      if (apkFiles.length == 1) {
        await installPackage(serial, apkFiles.first);
      } else {
        // adb install-multiple -r -d base.apk split1.apk ...
        final result = await Process.run('adb', [
          '-s',
          serial,
          'install-multiple',
          '-r',
          ...apkFiles,
        ]);
        final out = (result.stdout as String).trim();
        if (!out.contains('Success') && result.exitCode != 0) {
          throw ServerException('Cài đặt Split APKs thất bại: $out');
        }
      }

      // 4. Xử lý OBB (nếu có)
      if (obbFiles.isNotEmpty) {
        onStatus?.call('Đang đẩy dữ liệu OBB...');
        // Nếu không lấy được từ manifest, cố gắng lấy từ tên file OBB (thường là main.123.com.pkg.name.obb)
        if (packageName == null) {
          for (final obbPath in obbFiles) {
             final filename = p.basename(obbPath);
             final parts = filename.split('.');
             if (parts.length >= 3) {
                // Thường format là: main.version.packageName.obb
                // Hoặc patch.version.packageName.obb
                packageName = parts.sublist(2, parts.length - 1).join('.');
                break;
             }
          }
        }

        if (packageName != null) {
          final remoteObbDir = '/sdcard/Android/obb/$packageName';
          await runShellCommand(serial, 'mkdir -p $remoteObbDir');
          
          for (final obbPath in obbFiles) {
            final fileName = p.basename(obbPath);
            final result = await Process.run('adb', [
              '-s',
              serial,
              'push',
              obbPath,
              '$remoteObbDir/$fileName',
            ]);
            if (result.exitCode != 0) {
              throw ServerException('Lỗi khi đẩy OBB: ${result.stderr}');
            }
          }
        } else {
          logger.w('[ADB] Có OBB nhưng không xác định được package name để đẩy.');
          // Thất bại 1 phần (OBB) theo yêu cầu User là thất bại toàn bộ
          throw ServerException('Không xác định được Package Name để cài đặt OBB.');
        }
      }

      onStatus?.call('Cài đặt hoàn tất!');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Lỗi cài đặt XAPK: $e');
    } finally {
      // Dọn dẹp temp
      try {
        if (tempDir != null && await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  @override
  Future<String> runShellCommand(String serial, String command) async {
    try {
      final result = await Process.run('adb', ['-s', serial, 'shell', command]);
      final out = (result.stdout as String).trim();
      final err = (result.stderr as String).trim();

      if (result.exitCode != 0 || out.trim().toLowerCase() == 'failed' || out.trim().toLowerCase().startsWith('error:')) {
        final fullError = [
          if (out.isNotEmpty) out,
          if (err.isNotEmpty) err,
        ].join('\n').trim();
        
        throw ServerException('Lệnh thất bại ($command): ${fullError.isEmpty ? "Unknown Error" : fullError}');
      }
      return out;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Lỗi thực thi lệnh ($command): $e');
    }
  }

  @override
  Stream<String> runShellCommandStream(String serial, String command) {
    return _runProcessStream('adb', ['-s', serial, 'shell', command], serial, 'shell $command');
  }

  @override
  Stream<String> runRawAdbCommandStream(String serial, String adbCommand) {
    final args = _splitArguments(adbCommand);
    return _runProcessStream('adb', ['-s', serial, ...args], serial, adbCommand);
  }

  Stream<String> _runProcessStream(String executable, List<String> args, String serial, String displayCmd) {
    final controller = StreamController<String>();
    Process? process;
    Timer? timeoutTimer;
    bool stdoutDone = false;
    bool stderrDone = false;
    int? exitCode;

    void tryClose() {
      if (stdoutDone && stderrDone && exitCode != null) {
        timeoutTimer?.cancel();
        _closeController(controller);
        process = null;
      }
    }

    // Timeout sau 15 giây nếu không có phản hồi hoặc không kết thúc
    void startTimeout() {
      timeoutTimer?.cancel();
      timeoutTimer = Timer(const Duration(seconds: 15), () {
        if (process != null && !controller.isClosed) {
          logger.w('[ADB] Timeout ($serial): $displayCmd. Killing process...');
          controller.addError('Lỗi: Thiết bị không phản hồi (Timeout 15s) [$displayCmd]');
          process?.kill();
          process = null;
          _closeController(controller);
        }
      });
    }

    // Khi người dùng ngừng lắng nghe stream (subscription.cancel()), kill tiến trình
    controller.onCancel = () {
      timeoutTimer?.cancel();
      if (process != null) {
        logger.i('[ADB] Cancelled ($serial): $displayCmd. Killing process...');
        process?.kill();
        process = null;
      }
    };

    startTimeout();

    Process.start(executable, args).then((p) {
      process = p;

      p.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
        (line) {
          if (!controller.isClosed) controller.add(line);
        },
        onDone: () {
          stdoutDone = true;
          tryClose();
        },
        onError: (Object e) {
          _addError(controller, 'Lỗi stdout ($serial)', e);
          stdoutDone = true;
          tryClose();
        },
      );

      p.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(
        (line) {
          // stderr thường chứa thông tin lỗi quan trọng, đẩy qua addError để UI báo đỏ
          if (!controller.isClosed) {
            controller.addError(line);
          }
        },
        onDone: () {
          stderrDone = true;
          tryClose();
        },
        onError: (Object e) {
          _addError(controller, 'Lỗi stderr ($serial)', e);
          stderrDone = true;
          tryClose();
        },
      );

      p.exitCode.then((code) {
        exitCode = code;
        if (code != 0 && code != 1) {
          logger.w('[ADB] Process $displayCmd ($serial) exited with code $code');
        }
        tryClose();
      });
    }).catchError((Object e) {
      timeoutTimer?.cancel();
      _addErrorAndClose(controller, 'Lỗi khởi động process ($serial)', e);
    });

    return controller.stream;
  }

  /// Tách chuỗi lệnh thành danh sách các tham số, hỗ trợ dấu ngoặc kép
  List<String> _splitArguments(String command) {
    final List<String> result = [];
    final RegExp regex = RegExp(r'("[^"]*"|\S+)');
    final matches = regex.allMatches(command);
    
    for (final match in matches) {
      String arg = match.group(0)!;
      if (arg.startsWith('"') && arg.endsWith('"')) {
        arg = arg.substring(1, arg.length - 1);
      }
      result.add(arg);
    }
    // Lọc bỏ các tham số rỗng để tránh gửi các tham số rác vào Process.start
    return result.where((arg) => arg.isNotEmpty).toList();
  }

  void _closeController(StreamController<String> controller) {
    if (!controller.isClosed) {
      controller.close();
    }
  }

  void _addError(StreamController<String> controller, String context, dynamic error) {
    if (!controller.isClosed) {
      controller.add('$context: $error');
    }
  }

  void _addErrorAndClose(StreamController<String> controller, String context, dynamic error) {
    _addError(controller, context, error);
    _closeController(controller);
  }
}
