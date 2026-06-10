import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/mixins/session_manager_store_mixin.dart';
import 'package:scraki/core/stores/device_manager_store.dart';
import 'package:scraki/core/stores/session_manager_store.dart';
import 'package:scraki/features/script/presentation/stores/script_management_store.dart';
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import 'package:scraki/features/script/domain/entities/log_entry.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import 'package:scraki/features/script/presentation/stores/terminal_log_worker.dart';
import 'package:scraki/core/auth/presentation/stores/app_auth_store.dart';
import 'package:scraki/core/di/injection.dart';

part 'terminal_store.g.dart';

@singleton
class TerminalStore = _TerminalStore with _$TerminalStore;

abstract class _TerminalStore with Store, SessionManagerStoreMixin {
  final DeviceManagerStore _deviceManagerStore;
  final DeviceGroupStore _deviceGroupStore;
  final ScriptManagementStore _scriptManagementStore;
  final CommandInterpolator _interpolator;

  final TerminalLogWorker _logWorker = TerminalLogWorker();

  StreamSubscription<LogEntry>? _scriptLogSubscription;

  _TerminalStore(
    this._deviceManagerStore,
    this._deviceGroupStore,
    this._scriptManagementStore,
    this._interpolator,
  ) {
    initialized();
    _listenToScriptLogs();
  }

  void _listenToScriptLogs() {
    _scriptLogSubscription = _scriptManagementStore.logStream.listen((log) {
      terminalOutput.add(log);
      if (terminalOutput.length > 5000) {
        terminalOutput.removeAt(0);
      }
    });
  }

  @computed
  Set<String> get selectedSerials => _deviceManagerStore.selectedSerials;

  @computed
  ObservableList<DeviceEntity> get devices => _deviceManagerStore.devices;

  @readonly
  ObservableMap<String, bool> _shellStates =
      ObservableMap<String, bool>();

  @observable
  ObservableList<LogEntry> terminalOutput = ObservableList<LogEntry>();

  @observable
  ObservableMap<String, ObservableList<LogEntry>> deviceLogs =
      ObservableMap<String, ObservableList<LogEntry>>();

  @observable
  bool isExecuting = false;

  @observable
  String commandInput = '';

  static const int _maxConcurrentDevices = 50;

  @observable
  ObservableList<String> commandHistory = ObservableList<String>();

  @observable
  int historyIndex = -1;

  @observable
  bool isTiledView = false;

  @observable
  ObservableMap<String, LastExecution> lastExecutions = ObservableMap<String, LastExecution>();

  void initialized() {
    _logWorker.init().then((_) {
      _logWorker.onLogsReceived = (globalLogs, deviceLogsBatch) {
        runInAction(() {
          terminalOutput.addAll(globalLogs);
          if (terminalOutput.length > 5000) {
            terminalOutput.removeRange(0, terminalOutput.length - 5000);
          }

          deviceLogsBatch.forEach((serial, logs) {
            if (!deviceLogs.containsKey(serial)) {
              deviceLogs[serial] = ObservableList<LogEntry>();
            }
            final list = deviceLogs[serial]!;
            list.addAll(logs);
            if (list.length > 500) {
              list.removeRange(0, list.length - 500);
            }
          });
        });
      };

      _logWorker.onShellStateChanged = (serial, isRunning) {
        runInAction(() {
          _shellStates[serial] = isRunning;
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
      _log('Lỗi: Cần xác thực (Anonymous Auth) để chạy lệnh!', type: LogType.error);
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
      return executeCommandOnDevice(serial, processedCmd, logCommand: false);
    });
  }

  Future<void> _executeBatch(Future<void> Function(String serial) task) async {
    final serialList = selectedSerials.toList();
    if (serialList.isEmpty) {
      _log('Chưa chọn thiết bị nào!', type: LogType.info);
      return;
    }

    isExecuting = true;
    final queue = Queue<String>.from(serialList);

    try {
      final workers = <Future<void>>[];
      final numWorkers = serialList.length < _maxConcurrentDevices
          ? serialList.length
          : _maxConcurrentDevices;

      for (int i = 0; i < numWorkers; i++) {
        // Staggered start: Khởi chạy các worker cách nhau một khoảng nhỏ
        // giúp dàn trải tải trọng CPU/IO khi bắt đầu process adb
        if (i > 0) await Future<void>.delayed(Duration(milliseconds: Random().nextInt(500) + 50));

        // Kiểm tra nếu đã bị dừng trong lúc chờ delay
        if (!isExecuting) break;

        workers.add(() async {
          while (queue.isNotEmpty && isExecuting) {
            final serial = queue.removeFirst();
            try {
              await task(serial);
            } catch (e) {
              _log('Lỗi thực thi trên $serial: $e', type: LogType.error);
            }
          }
        }());
      }

      await Future.wait(workers);
    } finally {
      isExecuting = false;
    }
  }

  @action
  Future<void> executeCommandOnDevice(
    String serial,
    String command, {
    bool logCommand = true,
    bool updateTaskOverlay = true,
  }) async {
    if (command.trim().isEmpty) return;

    final device = getDeviceBySerial(serial);

    if (device == null) {
      _log(
        'Lỗi: Không tìm thấy thiết bị với serial $serial',
        type: LogType.error,
      );
      return;
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
      return;
    }

    final cmd = command.split(" ");

    if (cmd[0] == ">") {
      cmd.removeAt(0);
      cmd.insertAll(0, ["adb", "-s", serial]);
    } else if (cmd[0] == "\$") {
      cmd.removeAt(0);
    } else {
      cmd.insertAll(0, ["adb", "-s", serial, "shell"]);
    }

    final commandId = '${serial}_${DateTime.now().microsecondsSinceEpoch}';
    final executable = cmd.removeAt(0);

    if (updateTaskOverlay) {
      sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.command, status: command);
    }

    try {
      await _logWorker.executeCommand(
        commandId: commandId,
        serial: serial,
        executable: executable,
        arguments: cmd,
        modelName: deviceName,
      );

      if (updateTaskOverlay) {
        sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.command, status: 'Hoàn thành!', phase: DeviceTaskPhase.success);
        Future.delayed(const Duration(seconds: 2), () {
          final currentTask = sessionManagerStore.activeTasks[serial];
          if (currentTask != null && currentTask.phase == DeviceTaskPhase.success) {
            sessionManagerStore.clearDeviceTask(serial);
          }
        });
      }
    } catch (e) {
      if (updateTaskOverlay) {
        final errorMsg = e.toString();
        final isCanceled = errorMsg.contains('Canceled') || errorMsg.contains('code: -1');
        sessionManagerStore.updateDeviceTask(
          serial,
          type: DeviceTaskType.command,
          status: isCanceled ? 'Đã dừng!' : 'Lỗi',
          phase: DeviceTaskPhase.failed,
        );
        Future.delayed(Duration(seconds: isCanceled ? 2 : 3), () {
          final currentTask = sessionManagerStore.activeTasks[serial];
          if (currentTask != null && currentTask.phase == DeviceTaskPhase.failed) {
            sessionManagerStore.clearDeviceTask(serial);
          }
        });
      }
      rethrow;
    }
  }

  @action
  Future<void> runScript(
    ScriptEntity script, {
    Map<String, String>? args,
  }) async {
    if (!getIt<AppAuthStore>().isAuthenticated) {
      _log('Lỗi: Cần xác thực (Anonymous Auth) để chạy script!', type: LogType.error);
      return;
    }
    _log(
      'Running script: ${script.name} on ${selectedSerials.length} devices',
      type: LogType.command,
    );

    await _executeBatch((serial) async {
      final device = getDeviceBySerial(serial);
      try {
        if (device == null) return;
        lastExecutions[serial] = ScriptExecution(script, args);
        
        sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.script, status: 'Đang chạy: ${script.name}');

        final processedCommands = script.commands
            .map((cmd) => _interpolator.interpolate(cmd, {
                  'serial': serial,
                  'index': selectedSerials.toList().indexOf(serial).toString(),
                  ...?args,
                }))
            .toList();
            
        for (final command in processedCommands) {
          await executeCommandOnDevice(serial, command, logCommand: false, updateTaskOverlay: false);
        }
        
        sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.script, status: 'Hoàn thành!', phase: DeviceTaskPhase.success);
        Future.delayed(const Duration(seconds: 2), () {
          final currentTask = sessionManagerStore.activeTasks[serial];
          if (currentTask != null && currentTask.phase == DeviceTaskPhase.success) {
            sessionManagerStore.clearDeviceTask(serial);
          }
        });
      } catch (e) {
        final errorMsg = e.toString();
        final isCanceled = errorMsg.contains('Canceled') || errorMsg.contains('code: -1');
        sessionManagerStore.updateDeviceTask(
          serial,
          type: DeviceTaskType.script,
          status: isCanceled ? 'Đã dừng!' : 'Lỗi',
          phase: DeviceTaskPhase.failed,
        );
        Future.delayed(Duration(seconds: isCanceled ? 2 : 3), () {
          final currentTask = sessionManagerStore.activeTasks[serial];
          if (currentTask != null && currentTask.phase == DeviceTaskPhase.failed) {
            sessionManagerStore.clearDeviceTask(serial);
          }
        });
        _log(
          e.toString(),
          type: LogType.error,
          serial: serial,
          model: device?.modelName,
        );
      }
    });
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
  }) {
    final displaySerial =
        serial ?? (deviceCount != null && deviceCount > 1 ? 'ALL' : null);

    final entry = LogEntry(
      message: message,
      serial: displaySerial,
      deviceModel: model,
      type: type,
      deviceCount: deviceCount,
    );

    terminalOutput.add(entry);
    if (terminalOutput.length > 5000) {
      terminalOutput.removeAt(0);
    }

    if (serial != null) {
      if (!deviceLogs.containsKey(serial)) {
        deviceLogs[serial] = ObservableList<LogEntry>();
      }
      final logs = deviceLogs[serial]!;
      logs.add(entry);
      if (logs.length > 500) {
        logs.removeAt(0);
      }
    }
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
    _logWorker.stopCommand(serial);
  }

  @action
  void stopAll() {
    _logWorker.stopAll();
    isExecuting = false;
  }

  void dispose() {
    _logWorker.dispose();
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
        sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.script, status: 'Đang chạy: ${script.name}');

        final processedCommands = script.commands
            .map((cmd) => _interpolator.interpolate(cmd, {
                  'serial': serial,
                  'index': selectedSerials.toList().indexOf(serial).toString(),
                  ...?args,
                }))
            .toList();
        for (final command in processedCommands) {
          await executeCommandOnDevice(serial, command, logCommand: true, updateTaskOverlay: false);
        }

        sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.script, status: 'Hoàn thành!', phase: DeviceTaskPhase.success);
        Future.delayed(const Duration(seconds: 2), () {
          final currentTask = sessionManagerStore.activeTasks[serial];
          if (currentTask != null && currentTask.phase == DeviceTaskPhase.success) {
            sessionManagerStore.clearDeviceTask(serial);
          }
        });
      } catch (e) {
        final errorMsg = e.toString();
        final isCanceled = errorMsg.contains('Canceled') || errorMsg.contains('code: -1');
        sessionManagerStore.updateDeviceTask(
          serial,
          type: DeviceTaskType.script,
          status: isCanceled ? 'Đã dừng!' : 'Lỗi',
          phase: DeviceTaskPhase.failed,
        );
        Future.delayed(Duration(seconds: isCanceled ? 2 : 3), () {
          final currentTask = sessionManagerStore.activeTasks[serial];
          if (currentTask != null && currentTask.phase == DeviceTaskPhase.failed) {
            sessionManagerStore.clearDeviceTask(serial);
          }
        });
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