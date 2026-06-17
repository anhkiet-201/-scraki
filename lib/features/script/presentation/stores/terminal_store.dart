import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/mixins/session_manager_store_mixin.dart';
import 'package:scraki/core/stores/device_manager_store.dart';
import 'package:scraki/core/stores/session_manager_store.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/script/presentation/stores/script_management_store.dart';
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import 'package:scraki/features/device/domain/services/device_shell.dart';
import 'package:scraki/features/script/domain/entities/log_entry.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import 'package:scraki/features/script/presentation/stores/terminal_log_worker.dart';
import 'package:scraki/features/script/presentation/stores/terminal_process_worker.dart';
import 'package:scraki/core/auth/presentation/stores/app_auth_store.dart';
import 'package:scraki/core/di/injection.dart';
import '../utils/script_execution_parser.dart';

part 'terminal_store.g.dart';

@singleton
class TerminalStore = _TerminalStore with _$TerminalStore;

abstract class _TerminalStore with Store, SessionManagerStoreMixin {
  final DeviceManagerStore _deviceManagerStore;
  final DeviceGroupStore _deviceGroupStore;
  final ScriptManagementStore _scriptManagementStore;
  final CommandInterpolator _interpolator;

  final TerminalLogWorker _logWorker;
  final TerminalProcessWorker _processWorker;

  StreamSubscription<LogEntry>? _scriptLogSubscription;

  _TerminalStore(
    this._deviceManagerStore,
    this._deviceGroupStore,
    this._scriptManagementStore,
    this._interpolator,
    this._logWorker,
    this._processWorker,
  ) {
    initialized();
    _listenToScriptLogs();
  }

  void _listenToScriptLogs() {
    _scriptLogSubscription = _scriptManagementStore.logStream.listen((log) {
      final entry = _logWorker.parseSingleLog(
        message: log.message,
        type: log.type,
        serial: log.serial,
        model: log.deviceModel,
        deviceCount: log.deviceCount,
      );
      _appendLog(entry, log.serial);
    });
  }

  @computed
  Set<String> get selectedSerials => _deviceManagerStore.selectedSerials;

  @computed
  ObservableList<DeviceEntity> get devices => _deviceManagerStore.devices;

  @readonly
  ObservableMap<String, bool> _shellStates = ObservableMap<String, bool>();

  @observable
  ObservableList<LogEntry> terminalOutput = ObservableList<LogEntry>();

  @observable
  ObservableMap<String, ObservableList<LogEntry>> deviceLogs =
      ObservableMap<String, ObservableList<LogEntry>>();

  @observable
  bool isExecuting = false;

  @observable
  String commandInput = '';

  static const int _maxConcurrentDevices = 100;

  @observable
  ObservableList<String> commandHistory = ObservableList<String>();

  @observable
  int historyIndex = -1;

  @observable
  bool isTiledView = false;

  @observable
  ObservableMap<String, LastExecution> lastExecutions =
      ObservableMap<String, LastExecution>();

  void initialized() {
    _processWorker.init().then((_) {
      _processWorker.onRawLogsReceived = (globalRaw, deviceRaw) {
        runInAction(() {
          _logWorker.processGlobalLogs(
            globalRaw: globalRaw,
            currentGlobalLogs: terminalOutput,
            onLogProcessed: (entry, indexToReplace) {
              if (indexToReplace != null) {
                terminalOutput[indexToReplace] = entry;
              } else {
                terminalOutput.add(entry);
              }
            },
          );

          if (terminalOutput.length > 5000) {
            terminalOutput.removeRange(0, terminalOutput.length - 5000);
          }

          _logWorker.processDeviceLogs(
            deviceRaw: deviceRaw,
            currentDeviceLogs: deviceLogs,
            onLogProcessed: (serial, entry, indexToReplace) {
              if (!deviceLogs.containsKey(serial)) {
                deviceLogs[serial] = ObservableList<LogEntry>();
              }
              final list = deviceLogs[serial]!;
              if (indexToReplace != null) {
                list[indexToReplace] = entry;
              } else {
                list.add(entry);
              }
              if (list.length > 500) {
                list.removeRange(0, list.length - 500);
              }
              _updateTaskStatusFromLog(serial, entry);
            },
          );
        });
      };

      _processWorker.onShellStateChanged = (serial, isRunning) {
        runInAction(() {
          _shellStates[serial] = isRunning;
          _handleShellStateChanged(serial, isRunning);
        });
      };
    });
  }

  @action
  void setCommandInput(String value) {
    commandInput = value;
    if (value.isEmpty) {
      historyIndex = -1;
    }
  }

  @action
  void toggleTiledView() => isTiledView = !isTiledView;

  @action
  void navigateHistory(bool up) {
    if (commandHistory.isEmpty) return;

    if (up) {
      if (historyIndex < commandHistory.length - 1) {
        historyIndex++;
        commandInput = commandHistory[commandHistory.length - 1 - historyIndex];
      }
    } else {
      if (historyIndex > 0) {
        historyIndex--;
        commandInput = commandHistory[commandHistory.length - 1 - historyIndex];
      } else if (historyIndex == 0) {
        historyIndex = -1;
        commandInput = '';
      }
    }
  }

  @action
  Future<void> executeCurrentCommand() async {
    if (!getIt<AppAuthStore>().isAuthenticated) {
      _log(
        'Lỗi: Cần xác thực (Anonymous Auth) để chạy lệnh!',
        type: LogType.error,
      );
      return;
    }
    if (commandInput.trim().isEmpty) return;
    final cmd = commandInput;
    if (cmd.trim().isNotEmpty) {
      commandHistory.add(cmd);
      if (commandHistory.length > 50) {
        commandHistory.removeAt(0);
      }
    }
    commandInput = '';
    historyIndex = -1;

    final selectedSerialsList = selectedSerials.toList();
    final deviceCount = selectedSerialsList.length;

    await _executeBatch((serial) async {
      final processedCmd = _interpolator.interpolate(cmd, {'serial': serial});
      if (serial == selectedSerialsList.first) {
        _log(
          'Chạy lệnh trên $deviceCount thiết bị: $cmd',
          type: LogType.command,
          deviceCount: deviceCount,
          serial: serial,
          model: selectedSerialsList.length == 1
              ? getDeviceBySerial(serial)?.modelName
              : null,
        );
      }
      await executeCommandOnDevice(serial, processedCmd, logCommand: false);
    });
  }

  Future<void> _executeBatch(Future<void> Function(String serial) task) async {
    final serialList = selectedSerials.toList();
    if (serialList.isEmpty) {
      _log('Chưa chọn thiết bị nào!', type: LogType.info);
      return;
    }

    runInAction(() {
      isExecuting = true;
    });
    final queue = Queue<String>.from(serialList);

    try {
      final workers = <Future<void>>[];
      final numWorkers = serialList.length < _maxConcurrentDevices
          ? serialList.length
          : _maxConcurrentDevices;

      for (int i = 0; i < numWorkers; i++) {
        final workerIndex = i;
        workers.add(() async {
          if (workerIndex > 0) {
            final delayMs = Random().nextInt(500) + 50;
            const stepMs = 50;
            int remaining = delayMs;
            while (remaining > 0) {
              if (queue.isEmpty || !isExecuting) return;
              final sleepTime = remaining > stepMs ? stepMs : remaining;
              await Future<void>.delayed(Duration(milliseconds: sleepTime));
              remaining -= stepMs;
            }
          }

          while (queue.isNotEmpty && isExecuting) {
            final serial = queue.removeFirst();
            try {
              await task(serial);
            } catch (e) {
              logger.i('Lỗi thực thi trên $serial: $e');
            }
          }
        }());
      }

      await Future.wait(workers);
    } finally {
      runInAction(() {
        isExecuting = false;
      });
    }
  }

  @action
  Future<int> executeCommandOnDevice(
    String serial,
    String command, {
    bool logCommand = true,
    bool updateTaskOverlay = true,
  }) async {
    if (command.trim().isEmpty) return 0;

    final device = getDeviceBySerial(serial);

    if (device == null) {
      _log(
        'Lỗi: Không tìm thấy thiết bị với serial $serial',
        type: LogType.error,
      );
      return -1;
    }

    final deviceName = device.modelName;
    lastExecutions[serial] = CommandExecution(command);
    if (logCommand) {
      _log(
        command,
        serial: serial,
        model: deviceName,
        type: LogType.command,
        deviceCount: 1,
      );
    }

    final shell = sessionManagerStore.activeDeviceShells[serial];
    if (shell == null) {
      _log(
        'Lỗi: Không tìm thấy shell cho thiết bị với serial $serial',
        type: LogType.error,
      );
      return -1;
    }

    final parsed = _parseCommand(command, serial);
    final commandId = '${serial}_${DateTime.now().microsecondsSinceEpoch}';

    // Intercept adb push to show progress
    final isAdbPush =
        parsed.executable == 'adb' &&
        parsed.arguments.isNotEmpty &&
        parsed.arguments.contains('push');

    if (isAdbPush) {
      return await _executeAdbPushWithProgress(
        commandId,
        serial,
        parsed.executable,
        parsed.arguments,
        deviceName,
      );
    }

    return await _processWorker.executeCommand(
      commandId: commandId,
      serial: serial,
      executable: parsed.executable,
      arguments: parsed.arguments,
      modelName: deviceName,
    );
  }

  @action
  Future<void> runScript(
    ScriptEntity script, {
    Map<String, String>? args,
  }) async {
    if (!getIt<AppAuthStore>().isAuthenticated) {
      _log(
        'Lỗi: Cần xác thực (Anonymous Auth) để chạy script!',
        type: LogType.error,
      );
      return;
    }
    _log(
      'Running script: ${script.name} on ${selectedSerials.length} devices',
      type: LogType.command,
    );

    await _executeBatch((serial) async {
      final device = getDeviceBySerial(serial);
      if (device == null) return;
      await _executeScriptOnDevice(serial, script, args, device.modelName);
    });
  }

  @action
  void writeLog(
    String message, {
    String? serial,
    LogType type = LogType.error,
  }) {
    final device = serial != null ? getDeviceBySerial(serial) : null;
    _log(message, serial: serial, model: device?.modelName, type: type);
  }

  @action
  void clearTerminal() {
    terminalOutput.clear();
    deviceLogs.clear();
    _shellStates.clear();
  }

  void _log(
    String message, {
    String? serial,
    String? model,
    required LogType type,
    int? deviceCount,
    bool overwriteLast = false,
    String? executionId,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      message: message,
      type: type,
      serial: serial,
      deviceModel: model,
      deviceCount: deviceCount,
      overwriteLast: overwriteLast,
      executionId: executionId,
    );
    _appendLog(entry, serial);
  }

  DeviceEntity? getDeviceBySerial(String serial) {
    try {
      return devices.firstWhere((d) => d.serial == serial);
    } catch (_) {
      return null;
    }
  }

  @action
  void stopCommand(String serial) {
    _processWorker.stopCommand(serial);
  }

  @action
  void stopAll() {
    _processWorker.stopAll();
    isExecuting = false;
  }

  void dispose() {
    _processWorker.dispose();
    _scriptLogSubscription?.cancel();
  }

  @computed
  bool get hasActiveExecution => isExecuting;

  @action
  void selectDevicesByRange(int start, int end) {
    _log(
      'Chọn thiết bị theo dải Octet thứ 3: $start -> $end',
      type: LogType.info,
    );
    for (final device in devices) {
      final serial = device.serial.split(':').first;
      final ipSegments = serial.split('.');

      int? targetNumber;
      if (ipSegments.length == 4) {
        targetNumber = int.tryParse(ipSegments[2]);
      } else {
        final match = RegExp(r'(\d+)[^\d]*$').firstMatch(serial);
        targetNumber = int.tryParse(match?.group(1) ?? '');
      }

      if (targetNumber != null &&
          targetNumber >= start &&
          targetNumber <= end) {
        if (!selectedSerials.contains(device.serial)) {
          _deviceManagerStore.toggleDeviceSelection(device.serial);
        }
      }
    }
  }

  @action
  void selectDevicesByGroup(String groupId) {
    final group = _deviceGroupStore.groups.firstWhere((g) => g.id == groupId);
    _log('Chọn thiết bị theo nhóm: ${group.name}', type: LogType.info);

    final groupIps = group.deviceSerials.map((s) => s.split(':').first).toSet();

    for (final device in devices) {
      final deviceIp = device.serial.split(':').first;

      if (groupIps.contains(deviceIp) ||
          group.deviceSerials.contains(device.serial)) {
        if (!selectedSerials.contains(device.serial)) {
          _deviceManagerStore.toggleDeviceSelection(device.serial);
        }
      }
    }
  }

  @action
  Future<void> rerunLastExecution(String serial) async {
    final exec = lastExecutions[serial];
    if (exec == null) return;
    if (exec is CommandExecution) {
      await executeCommandOnDevice(serial, exec.command);
    } else if (exec is ScriptExecution) {
      final script = exec.script;
      final args = exec.args;
      final device = getDeviceBySerial(serial);
      if (device == null) return;

      _log(
        'Rerunning script: ${script.name}',
        serial: serial,
        model: device.modelName,
        type: LogType.command,
      );

      try {
        await _executeScriptOnDevice(serial, script, args, device.modelName);
      } catch (e) {
        final errorMsg = e.toString();
        // Lỗi từ tiến trình đã được Isolate log qua addLog(), không log lại để tránh trùng lặp.
        if (!errorMsg.contains('Process exited with code')) {
          _log(
            e.toString(),
            type: LogType.error,
            serial: serial,
            model: device.modelName,
          );
        }
      }
    }
  }

  Future<int> _executeBashBlockOnDevice(
    String serial,
    List<String> bashCommands, {
    required String deviceModel,
  }) async {
    final cleanCommands = bashCommands
        .skipWhile((s) => s.trim().isEmpty)
        .toList();
    if (cleanCommands.isEmpty) return 0;

    // Nối thêm lệnh exit và đảm bảo kết thúc bằng newline để tránh treo EOF
    final scriptText =
        '${['#!/system/bin/sh', ...cleanCommands, 'exit'].join('\n')}\n';
    final arguments = ['-s', serial, 'shell', 'sh'];
    final executable = 'adb';
    final commandId = '${serial}_${DateTime.now().microsecondsSinceEpoch}';

    return await _processWorker.executeCommand(
      commandId: commandId,
      serial: serial,
      executable: executable,
      arguments: arguments,
      modelName: deviceModel,
      stdin: scriptText,
    );
  }

  Future<int> _executeServerBashBlockOnDevice(
    String serial,
    List<String> bashCommands, {
    required String deviceModel,
  }) async {
    final cleanCommands = bashCommands
        .skipWhile((s) => s.trim().isEmpty)
        .toList();
    if (cleanCommands.isEmpty) return 0;

    final isWindows = Platform.isWindows;
    final executable = isWindows ? 'powershell.exe' : 'sh';
    final scriptText = cleanCommands.join('\n');

    final List<String> arguments;
    File? tempFile;
    if (isWindows) {
      // --- Script Setup ---
      // PowerShell khi stdout bị pipe (không phải console) tự động bật CLIXML format,
      // serialize mọi output (Write-Host, progress...) thành XML <Objs>.
      // Fix 3 lớp:
      //   1. [Console]::OutputEncoding = UTF8: Dart decode stdout bằng utf8.decoder.
      //   2. $ProgressPreference = 'SilentlyContinue': Tắt progress bar XML.
      //   3. Override Write-Host → Write-Output: Chuyển output của Write-Host
      //      từ Information stream (stream 6, bị serialize thành CLIXML)
      //      về stdout stream (stream 1, plain text).
      const scriptSetup = r'''
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
function Write-Host {
    param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
        $Object,
        [switch]$NoNewLine,
        $ForegroundColor,
        $BackgroundColor,
        $Separator
    )
    process {
        if ($null -ne $Object) {
            if ($NoNewLine) {
                [System.Console]::Write([string]$Object)
            } else {
                [System.Console]::WriteLine([string]$Object)
            }
        } else {
            if (-not $NoNewLine) {
                [System.Console]::WriteLine()
            }
        }
    }
}
function echo {
    param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
        $Object
    )
    process {
        if ($null -ne $Object) {
            [System.Console]::WriteLine([string]$Object)
        } else {
            [System.Console]::WriteLine()
        }
    }
}
''';
      final fullScript = '$scriptSetup$scriptText';
      final tempDir = Directory.systemTemp;
      final sanitizedSerial = serial.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final f = File('${tempDir.path}\\scraki_script_${sanitizedSerial}_${DateTime.now().microsecondsSinceEpoch}.ps1');
      tempFile = f;
      
      final bom = [0xEF, 0xBB, 0xBF];
      final scriptBytes = utf8.encode(fullScript);
      final fileBytes = Uint8List(bom.length + scriptBytes.length);
      fileBytes.setRange(0, bom.length, bom);
      fileBytes.setRange(bom.length, fileBytes.length, scriptBytes);
      f.writeAsBytesSync(fileBytes);

      arguments = [
        '-NoLogo',
        '-NonInteractive',
        '-NoProfile',
        '-File',
        f.path,
      ];
    } else {
      tempFile = null;
      arguments = ['-c', scriptText];
    }

    final commandId = '${serial}_${DateTime.now().microsecondsSinceEpoch}';

    int exitCode = -1;
    try {
      exitCode = await _processWorker.executeCommand(
        commandId: commandId,
        serial: serial,
        executable: executable,
        arguments: arguments,
        modelName: deviceModel,
        processKey: '__server__$serial',
      );
    } finally {
      if (tempFile != null) {
        try {
          if (tempFile.existsSync()) {
            tempFile.deleteSync();
          }
        } catch (_) {}
      }
    }

    return exitCode;
  }

  void _appendLog(LogEntry entry, String? serial) {
    runInAction(() {
      final indexGlobal = terminalOutput.lastIndexWhere((e) {
        if (e.type != LogType.output && e.type != LogType.error) return false;
        if (entry.executionId != null)
          return e.executionId == entry.executionId;
        return e.serial == entry.serial;
      });

      if (indexGlobal != -1 && terminalOutput[indexGlobal].overwriteLast) {
        terminalOutput[indexGlobal] = entry;
      } else {
        terminalOutput.add(entry);
      }
      if (terminalOutput.length > 5000) {
        terminalOutput.removeRange(0, terminalOutput.length - 5000);
      }

      if (serial != null) {
        if (!deviceLogs.containsKey(serial)) {
          deviceLogs[serial] = ObservableList<LogEntry>();
        }
        final list = deviceLogs[serial]!;
        final indexDevice = list.lastIndexWhere((e) {
          if (e.type != LogType.output && e.type != LogType.error) return false;
          if (entry.executionId != null)
            return e.executionId == entry.executionId;
          return e.serial == entry.serial;
        });

        if (indexDevice != -1 && list[indexDevice].overwriteLast) {
          list[indexDevice] = entry;
        } else {
          list.add(entry);
        }
        if (list.length > 500) {
          list.removeRange(0, list.length - 500);
        }
      }
    });
  }

  _CommandArgs _parseCommand(String command, String serial) {
    final trimmed = command.trim();

    // Tách các đối số bằng khoảng trắng nhưng giữ nguyên nội dung trong dấu nháy
    final regExp = RegExp(r"""[^\s"']*(?:"[^"]*"|'[^']*')[^\s"']*|[^\s]+""");
    final cmd = regExp.allMatches(trimmed).map((m) => m.group(0)!).toList();

    if (cmd.isEmpty) {
      return _CommandArgs('', []);
    }

    if (cmd[0] == ">") {
      cmd.removeAt(0);
      cmd.insertAll(0, ["adb", "-s", serial]);
    } else if (cmd[0] == "\$") {
      cmd.removeAt(0);
    } else {
      cmd.insertAll(0, ["adb", "-s", serial, "shell"]);
    }
    final executable = cmd.removeAt(0);

    // Làm sạch dấu nháy kép/nháy đơn cho các đối số sau khi parse
    final cleanedArgs = cmd.map((arg) {
      var t = arg.trim();
      if (t.length >= 2) {
        if ((t.startsWith('"') && t.endsWith('"')) ||
            (t.startsWith("'") && t.endsWith("'"))) {
          return t.substring(1, t.length - 1).trim();
        }
      }
      return t;
    }).toList();

    return _CommandArgs(executable, cleanedArgs);
  }

  Future<int> _executeAdbPushWithProgress(
    String commandId,
    String serial,
    String executable,
    List<String> arguments,
    String deviceName,
  ) async {
    final pushIdx = arguments.indexOf('push');
    if (pushIdx == -1 || pushIdx + 2 >= arguments.length) {
      return await _processWorker.executeCommand(
        commandId: commandId,
        serial: serial,
        executable: executable,
        arguments: arguments,
        modelName: deviceName,
      );
    }

    final localPath = arguments[pushIdx + 1];
    final remotePath = arguments[pushIdx + 2];

    final localFile = File(localPath);
    if (!localFile.existsSync()) {
      _log(
        'Lỗi: File nguồn không tồn tại: $localPath',
        serial: serial,
        model: deviceName,
        type: LogType.error,
      );
      return 1;
    }

    final totalBytes = localFile.lengthSync();
    final fileName = localPath.split(RegExp(r'[/\\]')).last;
    final String remoteFilePath;
    if (remotePath.endsWith('/') || remotePath.endsWith('\\')) {
      remoteFilePath = '$remotePath$fileName';
    } else {
      final lastPart = remotePath.split('/').last;
      if (!lastPart.contains('.')) {
        remoteFilePath = '$remotePath/$fileName';
      } else {
        remoteFilePath = remotePath;
      }
    }

    final completer = Completer<int>();
    final pushFuture = _processWorker.executeCommand(
      commandId: commandId,
      serial: serial,
      executable: executable,
      arguments: arguments,
      modelName: deviceName,
    );

    bool isDone = false;
    final timer = Timer.periodic(const Duration(milliseconds: 500), (t) async {
      if (isDone) {
        t.cancel();
        return;
      }

      try {
        final result = await Process.run('adb', [
          '-s',
          serial,
          'shell',
          'ls',
          '-l',
          remoteFilePath,
        ]);
        if (isDone) return;

        final output = result.stdout.toString().trim();
        if (output.isNotEmpty && !output.contains('No such file')) {
          final parts = output.split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            int? currentBytes;
            for (final part in parts) {
              final val = int.tryParse(part);
              if (val != null &&
                  val > 0 &&
                  val != totalBytes &&
                  parts.indexOf(part) > 2) {
                currentBytes = val;
                break;
              }
            }
            currentBytes ??= int.tryParse(parts[4]);
            currentBytes ??= int.tryParse(parts[3]);

            if (currentBytes != null && totalBytes > 0) {
              final pct = (currentBytes * 100 / totalBytes).toStringAsFixed(1);
              final currentMB = (currentBytes / (1024 * 1024)).toStringAsFixed(
                1,
              );
              final totalMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);

              _log(
                '[Tiến trình] $pct% ($currentMB MB / $totalMB MB) đã truyền tải...',
                serial: serial,
                model: deviceName,
                type: LogType.output,
                overwriteLast: true,
                executionId: commandId,
              );
            }
          }
        }
      } catch (_) {}
    });

    final exitCode = await pushFuture;
    isDone = true;
    timer.cancel();

    if (exitCode == 0) {
      final totalMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
      _log(
        'Đẩy file thành công! Tổng dung lượng: $totalMB MB',
        serial: serial,
        model: deviceName,
        type: LogType.info,
        overwriteLast: true,
        executionId: commandId,
      );
    }

    return exitCode;
  }

  Future<void> _executeScriptOnDevice(
    String serial,
    ScriptEntity script,
    Map<String, String>? args,
    String deviceModel,
  ) async {
    lastExecutions[serial] = ScriptExecution(script, args);

    final processedCommands = script.commands
        .map(
          (cmd) => _interpolator.interpolate(cmd, {
            'serial': serial,
            'index': selectedSerials.toList().indexOf(serial).toString(),
            ...?args,
          }),
        )
        .toList();

    final blocks = ScriptExecutionParser.parse(processedCommands);

    for (final block in blocks) {
      int exitCode = 0;
      if (block is SingleCommandBlock) {
        exitCode = await executeCommandOnDevice(
          serial,
          block.command,
          logCommand: false,
          updateTaskOverlay: false,
        );
      } else if (block is BashScriptBlock) {
        exitCode = await _executeBashBlockOnDevice(
          serial,
          block.commands,
          deviceModel: deviceModel,
        );
      } else if (block is ServerBashScriptBlock) {
        exitCode = await _executeServerBashBlockOnDevice(
          serial,
          block.commands,
          deviceModel: deviceModel,
        );
      }
      final state = ShellState.fromCode(exitCode);
      if (state == ShellState.stopped || state == ShellState.canceled) {
        break;
      }
    }
  }

  void _handleShellStateChanged(String serial, bool isRunning) {
    if (isRunning) {
      final exec = lastExecutions[serial];
      if (exec == null) return;

      DeviceTaskType type;
      String label;
      if (exec is ScriptExecution) {
        type = DeviceTaskType.script;
        label = exec.script.name;
      } else {
        type = DeviceTaskType.command;
        label = (exec as CommandExecution).command;
      }

      sessionManagerStore.updateDeviceTask(
        serial,
        type: type,
        label: label,
        status: 'Khởi chạy...',
        phase: DeviceTaskPhase.running,
      );
    } else {
      final currentTask = sessionManagerStore.activeTasks[serial];
      if (currentTask == null) return;

      final logs = deviceLogs[serial];
      bool isFailed = false;
      String statusMsg = 'Hoàn thành!';

      if (logs != null && logs.isNotEmpty) {
        final lastLog = logs.last;
        final lowerMsg = lastLog.message.toLowerCase();
        if (lastLog.type == LogType.error ||
            lowerMsg.contains('failed') ||
            lowerMsg.contains('error') ||
            lowerMsg.contains('timeout') ||
            lowerMsg.contains('canceled')) {
          isFailed = true;
          statusMsg = lastLog.message;
        }
      }

      sessionManagerStore.updateDeviceTask(
        serial,
        type: currentTask.type,
        label: currentTask.taskLabel,
        status: statusMsg,
        phase: isFailed ? DeviceTaskPhase.failed : DeviceTaskPhase.success,
      );

      Future.delayed(const Duration(seconds: 2), () {
        final taskNow = sessionManagerStore.activeTasks[serial];
        if (taskNow != null && taskNow.phase != DeviceTaskPhase.running) {
          sessionManagerStore.clearDeviceTask(serial);
        }
      });
    }
  }

  void _updateTaskStatusFromLog(String serial, LogEntry entry) {
    final currentTask = sessionManagerStore.activeTasks[serial];
    if (currentTask == null || currentTask.phase != DeviceTaskPhase.running)
      return;
    if (entry.message.trim().isEmpty) return;

    sessionManagerStore.updateDeviceTask(
      serial,
      type: currentTask.type,
      label: currentTask.taskLabel,
      status: entry.message,
      phase: DeviceTaskPhase.running,
    );
  }
}

abstract class LastExecution {
  const LastExecution();
}

class CommandExecution extends LastExecution {
  final String command;
  const CommandExecution(this.command);
}

class ScriptExecution extends LastExecution {
  final ScriptEntity script;
  final Map<String, String>? args;
  const ScriptExecution(this.script, this.args);
}

class _CommandArgs {
  final String executable;
  final List<String> arguments;
  _CommandArgs(this.executable, this.arguments);
}
