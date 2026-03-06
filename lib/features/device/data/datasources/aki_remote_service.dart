import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/services/i_aki_remote_service.dart';

@LazySingleton(as: IAkiRemoteService)
class AkiRemoteService implements IAkiRemoteService {
  static const _jarAssetPath = 'assets/server/aki_remote.jar';
  static const _wrapperAssetPath = 'assets/server/aki_remote';
  static const _remoteJarPath = '/data/local/tmp/aki_remote.jar';
  static const _remoteWrapperPath = '/data/local/tmp/aki_remote';

  /// Cache các serial đã được push thành công trong session hiện tại.
  final Set<String> _pushedSerials = {};

  // ---------------------------------------------------------------------------
  // Setup
  // ---------------------------------------------------------------------------

  @override
  Future<void> ensureServerPushed(String serial) async {
    // Kiểm tra in-memory cache — nhưng vẫn cần verify file còn tồn tại trên
    // device vì /data/local/tmp/ bị xóa khi device reboot.
    if (_pushedSerials.contains(serial)) {
      final stillExists = await _remoteFileExists(serial, _remoteWrapperPath);
      if (stillExists) return;

      // File bị xóa (do reboot hoặc lý do khác) — invalidate cache và push lại.
      logger.w(
        '[AkiRemoteService] Cache hit but binary missing on $serial, re-pushing...',
      );
      _pushedSerials.remove(serial);
    }

    logger.i('[AkiRemoteService] Pushing binaries to $serial...');
    try {
      final docsDir = await getApplicationDocumentsDirectory();

      // 1. Copy JAR từ assets ra local temp nếu chưa có.
      final localJar = File(p.join(docsDir.path, 'aki_remote.jar'));
      if (!await localJar.exists()) {
        final bytes = await rootBundle.load(_jarAssetPath);
        await localJar.writeAsBytes(bytes.buffer.asUint8List());
      }

      // 2. Push JAR lên device.
      await _runAdb(serial, [
        'push',
        localJar.path,
        _remoteJarPath,
      ], label: 'push jar');

      // 3. Copy shell wrapper từ assets ra local temp.
      // Luôn overwrite để đảm bảo file local đúng version.
      // Strip CRLF → LF: trên Windows, Git có thể bundle file với \r\n
      // khiến Android shell không parse được shebang #!/system/bin/sh\r
      final localWrapper = File(p.join(docsDir.path, 'aki_remote'));
      final wrapperBytes = await rootBundle.load(_wrapperAssetPath);
      final wrapperLf = _stripCrlf(wrapperBytes.buffer.asUint8List());
      await localWrapper.writeAsBytes(wrapperLf);

      // 4. Push shell wrapper lên device.
      await _runAdb(serial, [
        'push',
        localWrapper.path,
        _remoteWrapperPath,
      ], label: 'push wrapper');

      // 5. chmod +x để có thể execute.
      await _runAdbShell(
        serial,
        'chmod +x $_remoteWrapperPath',
        label: 'chmod',
      );

      _pushedSerials.add(serial);
      logger.i('[AkiRemoteService] Binaries ready on $serial');
    } catch (e) {
      throw AkiRemoteException('Failed to push aki_remote to $serial: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // UI Interaction
  // ---------------------------------------------------------------------------

  @override
  Future<void> click(String serial, AkiSelector selector) async {
    await _runRemote(serial, [
      'click',
      selector.toSelectorString(),
    ], label: 'click');
  }

  @override
  Future<void> type(String serial, String text, {AkiSelector? selector}) async {
    final escapedText = text.replaceAll('"', '\\"');
    if (selector != null) {
      // Format: type "<selector> || <text>"
      // Dùng nháy kép bao toàn bộ để tránh '||' bị shell hiểu nhầm là toán tử OR
      await _runRemote(serial, [
        'type',
        '"${selector.toSelectorString()} || $escapedText"',
      ], label: 'type');
    } else {
      await _runRemote(serial, ['type', '"$escapedText"'], label: 'type');
    }
  }

  @override
  Future<String?> get(String serial, AkiSelector selector) async {
    final output = await _runRemote(serial, [
      'get',
      selector.toSelectorString(),
    ], label: 'get');
    final trimmed = output.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Future<String> find(String serial, AkiSelector selector) async {
    return _runRemote(serial, [
      'find',
      selector.toSelectorString(),
    ], label: 'find');
  }

  @override
  Future<String> dump(String serial) async {
    return _runRemote(serial, ['dump'], label: 'dump');
  }

  // ---------------------------------------------------------------------------
  // Swipe
  // ---------------------------------------------------------------------------

  @override
  Future<void> swipe(
    String serial,
    SwipeDirection direction,
    double ratio, {
    int? durationMs,
  }) async {
    final dirStr = direction.name; // 'up' | 'down' | 'left' | 'right'
    final args = ['swipe', dirStr, ratio.toString()];
    if (durationMs != null) args.add(durationMs.toString());
    await _runRemote(serial, args, label: 'swipe');
  }

  @override
  Future<void> swipeByCoords(
    String serial,
    int x1,
    int y1,
    int x2,
    int y2, {
    int? durationMs,
  }) async {
    final args = [
      'swipe',
      x1.toString(),
      y1.toString(),
      x2.toString(),
      y2.toString(),
    ];
    if (durationMs != null) args.add(durationMs.toString());
    await _runRemote(serial, args, label: 'swipe-coords');
  }

  // ---------------------------------------------------------------------------
  // Screen info
  // ---------------------------------------------------------------------------

  @override
  Future<({int width, int height})> getScreenSize(String serial) async {
    final output = await _runRemote(serial, ['size'], label: 'size');
    // Output format: "1080x2220"
    final parts = output.trim().split('x');
    if (parts.length != 2) {
      throw AkiRemoteException(
        'Unexpected size output format from $serial: "$output"',
      );
    }
    final width = int.tryParse(parts[0]);
    final height = int.tryParse(parts[1]);
    if (width == null || height == null) {
      throw AkiRemoteException(
        'Cannot parse screen size from "$output" for $serial',
      );
    }
    return (width: width, height: height);
  }

  // ---------------------------------------------------------------------------
  // System navigation
  // ---------------------------------------------------------------------------

  @override
  Future<void> home(String serial) async {
    await _runRemote(serial, ['home'], label: 'home');
  }

  @override
  Future<void> back(String serial) async {
    await _runRemote(serial, ['back'], label: 'back');
  }

  @override
  Future<void> recents(String serial) async {
    await _runRemote(serial, ['recents'], label: 'recents');
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Chạy lệnh `aki_remote` trên device qua ADB shell.
  ///
  /// [commandArgs] — command + arguments, VD: `['click', 'text:OK']`
  ///
  /// Throws [AkiRemoteException] nếu exitCode != 0.
  Future<String> _runRemote(
    String serial,
    List<String> commandArgs, {
    required String label,
  }) async {
    // Build argument list cho ADB:
    // adb -s <serial> shell /data/local/tmp/aki_remote <cmd> [args...]
    final adbArgs = ['-s', serial, 'shell', _remoteWrapperPath, ...commandArgs];

    logger.d('[AkiRemoteService] [$label] adb ${adbArgs.join(' ')}');

    final result = await Process.run('adb', adbArgs);
    final stdout = (result.stdout as String).trim();
    final stderr = (result.stderr as String).trim();

    final isSuccessOutput =
        stdout.trim() == 'OK' || stdout.trim().startsWith('OK');

    final isFailure =
        (!isSuccessOutput && result.exitCode != 0) ||
        stdout.contains('Failure:') ||
        stdout.contains('No matches found') ||
        stderr.contains('Exception') ||
        stderr.contains('Error');

    if (isFailure) {
      final errorMsg = [
        if (stderr.isNotEmpty) 'STDERR: $stderr',
        if (stdout.isNotEmpty) 'STDOUT: $stdout',
      ].join(' | ');

      logger.e(
        '[AkiRemoteService] [$label] failed on $serial: exit=${result.exitCode}, err=$errorMsg',
      );
      throw AkiRemoteException('[$label] failed on $serial: $errorMsg');
    }

    logger.d('[AkiRemoteService] [$label] output: $stdout');
    return stdout;
  }

  /// Chạy lệnh ADB thuần (không qua aki_remote).
  Future<void> _runAdb(
    String serial,
    List<String> args, {
    required String label,
  }) async {
    final result = await Process.run('adb', ['-s', serial, ...args]);
    if (result.exitCode != 0) {
      throw AkiRemoteException(
        'adb $label failed for $serial: ${result.stderr}',
      );
    }
  }

  /// Chạy lệnh ADB shell thuần.
  Future<void> _runAdbShell(
    String serial,
    String shellCmd, {
    required String label,
  }) async {
    final result = await Process.run('adb', ['-s', serial, 'shell', shellCmd]);
    if (result.exitCode != 0) {
      throw AkiRemoteException(
        'adb shell $label failed for $serial: ${result.stderr}',
      );
    }
  }

  /// Kiểm tra file có tồn tại trên device không (dùng `adb shell ls`).
  Future<bool> _remoteFileExists(String serial, String remotePath) async {
    final result = await Process.run('adb', [
      '-s',
      serial,
      'shell',
      'ls',
      remotePath,
    ]);
    return result.exitCode == 0;
  }

  /// Xóa ký tự \r (CR) khỏi byte array để đảm bảo LF-only line endings.
  ///
  /// Cần thiết trên Windows vì Git core.autocrlf=true có thể bundle
  /// shell script với CRLF, khiến Android /system/bin/sh không parse
  /// được shebang #!/system/bin/sh\r.
  List<int> _stripCrlf(List<int> bytes) {
    return bytes.where((b) => b != 0x0D).toList(); // 0x0D = \r
  }
}
