import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/mixins/session_manager_store_mixin.dart';
import 'package:scraki/core/stores/device_manager_store.dart';
import 'package:scraki/features/script/presentation/stores/script_management_store.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import 'package:scraki/features/device/domain/services/device_shell.dart';
import 'package:scraki/features/script/domain/entities/log_entry.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import 'package:scraki/features/script/domain/usecases/run_script_use_case.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';

part 'terminal_store.g.dart';

@singleton
class TerminalStore = _TerminalStore with _$TerminalStore;

abstract class _TerminalStore with Store, SessionManagerStoreMixin {
  final RunScriptUseCase _runScriptUseCase;
  final DeviceManagerStore _deviceManagerStore;
  final DeviceGroupStore _deviceGroupStore;
  final ScriptManagementStore _scriptManagementStore;

  StreamSubscription<LogEntry>? _scriptLogSubscription;

  _TerminalStore(
    this._runScriptUseCase,
    this._deviceManagerStore,
    this._deviceGroupStore,
    this._scriptManagementStore,
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
  ObservableMap<String, ShellState> _shellStates = ObservableMap<String, ShellState>();

  @observable
  ObservableList<LogEntry> terminalOutput = ObservableList<LogEntry>();

  @observable
  ObservableMap<String, ObservableList<LogEntry>> deviceLogs = ObservableMap<String, ObservableList<LogEntry>>();

  @observable
  bool isExecuting = false;

  @observable
  String commandInput = '';

  static const int _maxConcurrentDevices = 10;

  @observable
  ObservableList<String> commandHistory = ObservableList<String>();

  @observable
  int historyIndex = -1;

  @observable
  bool isTiledView = false;

  final Map<String, StreamSubscription<DeviceShellResult>> _shellLogSubscriptions = {};

  void initialized() {
    reaction(
      (_) => sessionManagerStore.activeSessions.keys.toSet(),
      (Set<String> newKeys) {
        // 1. Subscribe các session mới
        for (final key in newKeys) {
          final serial = _normalizeSerial(key);
          if (!_shellLogSubscriptions.containsKey(serial)) {
            final shell = sessionManagerStore.activeSessions[key]?.deviceShell;
            if (shell == null) continue;
            _shellLogSubscriptions[serial] = shell.results.listen((result) {
              final device = getDeviceBySerial(serial);
              final deviceName = device?.modelName;
              _shellStates[serial] = result.state == ShellState.error && result.exitCode == null ? ShellState.running : result.state;
              switch (result.state) {
                case ShellState.error:
                  _log(result.logs, serial: serial, model: deviceName, type: LogType.error);
                  break;
                case ShellState.success:
                case ShellState.canceled:
                  _log(result.logs, serial: serial, model: deviceName, type: LogType.info);
                  break;
                case ShellState.running:
                  _log(result.logs, serial: serial, model: deviceName, type: LogType.output);
                  break;
              }
            });
          }
        }

        // 2. Cancel các subscription của session đã đóng
        final normalizedNew = newKeys.map(_normalizeSerial).toSet();
        final removed = _shellLogSubscriptions.keys
            .where((s) => !normalizedNew.contains(s))
            .toList();
        for (final serial in removed) {
          _shellLogSubscriptions[serial]?.cancel();
          _shellLogSubscriptions.remove(serial);
        }
      },
    );
  }

  String _normalizeSerial(String key) =>
      key.replaceAll('_grid', '').replaceAll('_floating', '');

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
      final processedCmd = _replacePlaceholders(cmd, serial);
      if (serial == selectedSerialsList.first) {
        _log('Chạy lệnh trên $deviceCount thiết bị: $cmd', type: LogType.command, deviceCount: deviceCount, serial: serial, model: selectedSerialsList.length == 1 ? getDeviceBySerial(serial)?.modelName : null);
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
    try {
      for (var i = 0; i < serialList.length; i += _maxConcurrentDevices) {
        final end = (i + _maxConcurrentDevices < serialList.length) ? i + _maxConcurrentDevices : serialList.length;
        final chunk = serialList.sublist(i, end);

        await Future.wait(chunk.asMap().entries.map((entry) async {
          return task(entry.value);
        }));
      }
    } finally {
      isExecuting = false;
    }
  }

  @action
  Future<void> executeCommandOnDevice(String serial, String command, {bool logCommand = true}) async {
    if (command.trim().isEmpty) return;

    final device = getDeviceBySerial(serial);

    if (device == null) {
      _log('Lỗi: Không tìm thấy thiết bị với serial $serial', type: LogType.error);
      return;
    }

    final deviceName = device.modelName;
    if (logCommand) {
      _log(command, serial: serial, model: deviceName, type: LogType.command, deviceCount: 1);
    }

    final shell = sessionManagerStore.activeDeviceShells[serial];
    if (shell == null) {
      _log('Lỗi: Không tìm thấy shell cho thiết bị với serial $serial', type: LogType.error);
      return;
    }

    final completer = Completer<void>();

    shell.start("adb", arguments: ["-s", serial, "shell", command]).then((_) {
      completer.complete();
    });

    return completer.future;
  }

  @action
  Future<void> runScript(ScriptEntity script) async {
    _log('Running script: ${script.name} on ${selectedSerials.length} devices', type: LogType.command);

    await _executeBatch((serial) async {
      final device = getDeviceBySerial(serial);
      if (device == null) return;
      final deviceName = device.modelName;

      final processedCommands = script.commands.map((cmd) => _replacePlaceholders(cmd, serial)).toList();
      final processedScript = script.copyWith(commands: processedCommands);

      await _runScriptUseCase(serial, processedScript).forEach((result) {
        result.fold(
          (Failure failure) => _log(failure.message, serial: serial, model: deviceName, type: LogType.error),
          (String line) => _log(line, serial: serial, model: deviceName, type: LogType.output),
        );
      });
    });
  }

  String _replacePlaceholders(String command, String serial) {
    String processed = command;
    processed = processed.replaceAll('{SERIAL}', serial);
    final ipOnly = serial.split(':').first;
    final segments = ipOnly.split('.');
    String octet3 = '0';
    if (segments.length == 4) {
      octet3 = segments[2];
    } else {
      final match = RegExp(r'(\d+)[^\d]*$').firstMatch(serial);
      octet3 = match?.group(1) ?? '0';
    }
    processed = processed.replaceAll('{I}', octet3);
    return processed;
  }

  @action
  void clearTerminal() {
    terminalOutput.clear();
    deviceLogs.clear();
  }

  void _log(String message, {String? serial, String? model, required LogType type, int? deviceCount}) {
    final displaySerial = serial ?? (deviceCount != null && deviceCount > 1 ? 'ALL' : null);
    
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
      return devices.firstWhere(
        (d) => d.serial == serial
      );
    } catch (_) {
      return null;
    }
  }

  @action
  void stopCommand(String serial) {
    final shell = sessionManagerStore.activeDeviceShells[serial];
    if (shell != null) {
      shell.stop();
    }
  }

  @action
  void stopAll() {
    for (final shell in sessionManagerStore.activeDeviceShells.values) {
      shell.stop();
    }
    isExecuting = false;
  }

  void dispose() {
    stopAll();
    _scriptLogSubscription?.cancel();
    for (final sub in _shellLogSubscriptions.values) {
      sub.cancel();
    }
    _shellLogSubscriptions.clear();
    for (var shell in sessionManagerStore.activeDeviceShells.values) {
      shell.dispose();
    }
  }

  @computed
  bool get hasActiveExecution => isExecuting;

  @action
  void selectDevicesByRange(int start, int end) {
    _log('Chọn thiết bị theo dải Octet thứ 3: $start -> $end', type: LogType.info);
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

      if (targetNumber != null && targetNumber >= start && targetNumber <= end) {
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
      
      if (groupIps.contains(deviceIp) || group.deviceSerials.contains(device.serial)) {
        if (!selectedSerials.contains(device.serial)) {
          _deviceManagerStore.toggleDeviceSelection(device.serial);
        }
      }
    }
  }
}
