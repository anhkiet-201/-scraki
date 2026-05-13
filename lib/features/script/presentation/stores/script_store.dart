import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scraki/core/mixins/session_manager_store_mixin.dart';
import 'package:scraki/core/stores/device_manager_store.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import 'package:scraki/features/device/domain/services/device_shell.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import 'package:scraki/features/script/domain/entities/log_entry.dart';
import 'package:scraki/features/script/domain/repositories/script_repository.dart';
import 'package:scraki/features/script/domain/usecases/run_script_use_case.dart';
import 'package:scraki/features/script/domain/usecases/save_script_use_case.dart';
import 'package:scraki/features/script/domain/usecases/delete_script_use_case.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';

part 'script_store.g.dart';

@singleton
// ignore: library_private_types_in_public_api
class ScriptStore = _ScriptStore with _$ScriptStore;

abstract class _ScriptStore with Store, SessionManagerStoreMixin {
  final ScriptRepository _repository;
  final RunScriptUseCase _runScriptUseCase;
  final SaveScriptUseCase _saveScriptUseCase;
  final DeleteScriptUseCase _deleteScriptUseCase;
  final DeviceManagerStore _deviceManagerStore;
  final DeviceGroupStore _deviceGroupStore;
  MergeStream<DeviceShellResult>? logs;

  _ScriptStore(
    this._repository,
    this._runScriptUseCase,
    this._saveScriptUseCase,
    this._deleteScriptUseCase,
    this._deviceManagerStore,
    this._deviceGroupStore,
  ) {
    initialized();
  }

  @computed
  Set<String> get selectedSerials => _deviceManagerStore.selectedSerials;

  @computed
  ObservableList<DeviceEntity> get devices => _deviceManagerStore.devices;

  @readonly
  ObservableMap<String, ShellState> _shellStates = ObservableMap<String, ShellState>();

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
              _shellStates[serial] = result.state;
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
  void toggleDeviceSelection(String serial) => _deviceManagerStore.toggleDeviceSelection(serial);

  @action
  void selectAllDevices(bool select) {
    if (select) {
      for (final device in devices) {
        if (!selectedSerials.contains(device.serial)) {
          toggleDeviceSelection(device.serial);
        }
      }
    } else {
      _deviceManagerStore.clearSelection();
    }
  }

  @action
  void selectDevicesByRange(int start, int end) {
    _log('Chọn thiết bị theo dải Octet thứ 3: $start -> $end', type: LogType.info);
    for (final device in devices) {
      final serial = device.serial.split(':').first;
      final ipSegments = serial.split('.');
      
      int? targetNumber;
      if (ipSegments.length == 4) {
        // Chỉ xét duy nhất octet thứ 3 (x trong 192.168.x.20) theo yêu cầu người dùng
        targetNumber = int.tryParse(ipSegments[2]);
      } else {
        final match = RegExp(r'(\d+)[^\d]*$').firstMatch(serial);
        targetNumber = int.tryParse(match?.group(1) ?? '');
      }

      if (targetNumber != null && targetNumber >= start && targetNumber <= end) {
        if (!selectedSerials.contains(device.serial)) {
          toggleDeviceSelection(device.serial);
        }
      }
    }
  }

  @action
  void selectDevicesByGroup(String groupId) {
    final group = _deviceGroupStore.groups.firstWhere((g) => g.id == groupId);
    _log('Chọn thiết bị theo nhóm: ${group.name}', type: LogType.info);
    
    // Lấy danh sách IP sạch từ nhóm (bỏ port nếu có)
    final groupIps = group.deviceSerials.map((s) => s.split(':').first).toSet();
    
    // Duyệt qua danh sách thiết bị đang online để tìm các máy khớp IP
    for (final device in devices) {
      final deviceIp = device.serial.split(':').first;
      
      if (groupIps.contains(deviceIp) || group.deviceSerials.contains(device.serial)) {
        if (!selectedSerials.contains(device.serial)) {
          toggleDeviceSelection(device.serial);
        }
      }
    }
  }

  @action
  void clearSelection() => _deviceManagerStore.clearSelection();

  @observable
  ObservableList<ScriptEntity> scripts = ObservableList<ScriptEntity>();

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
  ScriptEntity? editingScript;

  @observable
  bool isTiledView = false;

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
  void setEditingScript(ScriptEntity? script) {
    editingScript = script;
  }

  @action
  void updateEditingScript({String? name, String? description, List<String>? commands}) {
    if (editingScript == null) {
      editingScript = ScriptEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name ?? 'New Script',
        description: description ?? '',
        commands: commands ?? [],
      );
    } else {
      editingScript = editingScript!.copyWith(
        name: name,
        description: description,
        commands: commands,
        updatedAt: DateTime.now(),
      );
    }
  }

  @action
  Future<void> saveCurrentScript() async {
    if (editingScript == null) return;
    final result = await _saveScriptUseCase(editingScript!);
    result.fold(
      (failure) => _log('Lỗi lưu script: ${failure.message}', type: LogType.error),
      (_) {
        _log('Đã lưu script: ${editingScript!.name}', type: LogType.info);
        loadScripts();
      },
    );
  }


  // Quản lý subscription log của từng thiết bị
  final Map<String, StreamSubscription<DeviceShellResult>> _shellLogSubscriptions = {};
  StreamSubscription<Either<Failure, List<ScriptEntity>>>? _scriptsSubscription;

  @action
  void init() {
    watchScripts();
  }

  @action
  void watchScripts() {
    _scriptsSubscription?.cancel();
    _scriptsSubscription = _repository.watchAllScripts().listen((result) {
      result.fold(
        (failure) => _log('Lỗi tải script realtime: ${failure.message}', type: LogType.error),
        (loadedScripts) {
          scripts.clear();
          scripts.addAll(loadedScripts);
        },
      );
    });
  }

  void dispose() {
    _scriptsSubscription?.cancel();
    stopAll();
    // Hủy các subscription log
    for (final sub in _shellLogSubscriptions.values) {
      sub.cancel();
    }
    _shellLogSubscriptions.clear();
  }

  @computed
  bool get hasActiveExecution => isExecuting;

  @action
  void stopCommand(String serial) {
    final shell = sessionManagerStore.activeDeviceShells[serial];
    if (shell != null) {
      shell.stop();
    }
  }

  @action
  void stopAll() {
    // Dừng tất cả các shell
    for (final shell in sessionManagerStore.activeDeviceShells.values) {
      shell.stop();
    }

    isExecuting = false;
  }

  @action
  Future<void> deleteScript(String id) async {
    final result = await _deleteScriptUseCase(id);
    result.fold(
      (failure) => _log('Lỗi xóa script: ${failure.message}', type: LogType.error),
      (_) {
        _log('Đã xóa script', type: LogType.info);
        if (editingScript?.id == id) editingScript = null;
        loadScripts();
      },
    );
  }

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
  Future<void> loadScripts() async {
    final result = await _repository.getAllScripts();
    result.fold(
      (Failure failure) => _log('Lỗi tải script: ${failure.message}', type: LogType.error),
      (List<ScriptEntity> loadedScripts) {
        scripts.clear();
        scripts.addAll(loadedScripts);
      },
    );
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
      // Trước khi chạy batch, log một dòng thông báo chung
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

        // Chạy song song trong phạm vi một đợt và ĐỢI đợt này xong hoàn toàn
        // Thêm khoảng nghỉ 50ms giữa các thiết bị để tránh gây sốc cho ADB Server
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

      // Tạo bản sao script với các lệnh đã được replace placeholders
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

    // 1. Thay thế {SERIAL} - Toàn bộ serial gốc (có thể kèm port)
    processed = processed.replaceAll('{SERIAL}', serial);

    // 2. Thay thế {I} - Mặc định là Octet thứ 3 của IP
    final ipOnly = serial.split(':').first;
    final segments = ipOnly.split('.');
    String octet3 = '0';
    if (segments.length == 4) {
      octet3 = segments[2];
    } else {
      // Fallback: Lấy số cuối cùng trong chuỗi serial nếu không phải format IP
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
    // Nếu là lệnh global (không có serial), hiển thị là [ALL] thay vì [???]
    final displaySerial = serial ?? (deviceCount != null && deviceCount > 1 ? 'ALL' : null);
    
    final entry = LogEntry(
      message: message,
      serial: displaySerial,
      deviceModel: model,
      type: type,
      deviceCount: deviceCount,
    );

    // 1. Thêm vào danh sách tổng (cho Console chính)
    terminalOutput.add(entry);
    if (terminalOutput.length > 5000) { // Tăng lên 5000 dòng cho console tổng
      terminalOutput.removeAt(0);
    }

    // 2. Thêm vào danh sách riêng của thiết bị (cho Tiled View)
    if (serial != null) {
      if (!deviceLogs.containsKey(serial)) {
        deviceLogs[serial] = ObservableList<LogEntry>();
      }
      final logs = deviceLogs[serial]!;
      logs.add(entry);
      if (logs.length > 500) { // Giới hạn 500 dòng/máy để tiết kiệm RAM
        logs.removeAt(0);
      }
    }
  }

  /// Lấy thông tin thiết bị theo Serial một cách an toàn
  DeviceEntity? getDeviceBySerial(String serial) {
    try {
      return devices.firstWhere(
        (d) => d.serial == serial
      );
    } catch (_) {
      return null;
    }
  }
}
