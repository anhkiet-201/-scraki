import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/stores/device_manager_store.dart';
import '../../../../core/error/failures.dart';
import '../../../device/domain/entities/device_entity.dart';
import '../../domain/entities/script_entity.dart';
import '../../domain/entities/log_entry.dart';
import '../../domain/repositories/script_repository.dart';
import '../../domain/usecases/run_script_use_case.dart';
import '../../domain/usecases/execute_command_use_case.dart';
import '../../domain/usecases/save_script_use_case.dart';
import '../../domain/usecases/delete_script_use_case.dart';

part 'script_store.g.dart';

@lazySingleton
// ignore: library_private_types_in_public_api
class ScriptStore = _ScriptStore with _$ScriptStore;

abstract class _ScriptStore with Store {
  final ScriptRepository _repository;
  final RunScriptUseCase _runScriptUseCase;
  final ExecuteCommandUseCase _executeCommandUseCase;
  final SaveScriptUseCase _saveScriptUseCase;
  final DeleteScriptUseCase _deleteScriptUseCase;
  final DeviceManagerStore _deviceManagerStore;

  _ScriptStore(
    this._repository,
    this._runScriptUseCase,
    this._executeCommandUseCase,
    this._saveScriptUseCase,
    this._deleteScriptUseCase,
    this._deviceManagerStore,
  );

  @computed
  Set<String> get selectedSerials => _deviceManagerStore.selectedSerials;

  @computed
  ObservableList<DeviceEntity> get devices => _deviceManagerStore.devices;

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
  void clearSelection() => _deviceManagerStore.clearSelection();

  @observable
  ObservableList<ScriptEntity> scripts = ObservableList<ScriptEntity>();

  @observable
  ObservableList<LogEntry> terminalOutput = ObservableList<LogEntry>();

  @observable
  bool isExecuting = false;

  @observable
  String commandInput = '';

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

  // Quản lý các subscription đang chạy để có thể dừng lệnh
  final Map<String, StreamSubscription<dynamic>> _activeSubscriptions = {};
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
  }

  bool hasActiveSubscription(String serial) => _activeSubscriptions.containsKey(serial);

  @computed
  bool get hasActiveExecution => _activeSubscriptions.isNotEmpty || isExecuting;

  @action
  void stopCommand(String serial) {
    if (_activeSubscriptions.containsKey(serial)) {
      _activeSubscriptions[serial]?.cancel();
      _activeSubscriptions.remove(serial);
      _log('Đã dừng lệnh trên thiết bị', serial: serial, type: LogType.error);
      
      if (_activeSubscriptions.isEmpty) {
        isExecuting = false;
      }
    }
  }

  @action
  void stopAll() {
    for (final sub in _activeSubscriptions.values) {
      sub.cancel();
    }
    _activeSubscriptions.clear();
    isExecuting = false;
    _log('Đã dừng tất cả các lệnh đang thực thi', type: LogType.error);
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
    
    final selectedSerials = _deviceManagerStore.selectedSerials.toList();
    if (selectedSerials.isEmpty) {
      _log('Chưa chọn thiết bị nào!', type: LogType.info);
      return;
    }

    isExecuting = true;
    final deviceCount = selectedSerials.length;
    // Nếu chạy trên nhiều thiết bị, log một dòng thông báo chung trước
    _log('Chạy lệnh trên $deviceCount thiết bị: $cmd', type: LogType.command, deviceCount: deviceCount);

    await Future.wait(selectedSerials.map((serial) => executeCommandOnDevice(serial, cmd, logCommand: false)));
  }

  @action
  Future<void> executeCommandOnDevice(String serial, String command, {bool logCommand = true}) async {
    if (command.trim().isEmpty) return;
    
    final device = _deviceManagerStore.devices.firstWhere((d) => d.serial == serial);
    final deviceName = device.modelName;
    
    if (logCommand) {
      _log(command, serial: serial, model: deviceName, type: LogType.command, deviceCount: 1);
    }
    
    // Hủy subscription cũ nếu có
    await _activeSubscriptions[serial]?.cancel();

    final subscription = _executeCommandUseCase.executeStream(serial, command).listen(
      (result) {
        result.fold(
          (f) => _log('Lỗi: ${f.message}', serial: serial, model: deviceName, type: LogType.error),
          (msg) => _log(msg, serial: serial, model: deviceName, type: LogType.output),
        );
      },
      onDone: () {
        _activeSubscriptions.remove(serial);
        if (_activeSubscriptions.isEmpty) isExecuting = false;
      },
      onError: (Object e) {
        _log('Lỗi hệ thống: $e', serial: serial, model: deviceName, type: LogType.error);
        _activeSubscriptions.remove(serial);
        if (_activeSubscriptions.isEmpty) isExecuting = false;
      },
    );

    _activeSubscriptions[serial] = subscription;
  }

  @action
  Future<void> runScript(ScriptEntity script) async {
    final selectedSerials = _deviceManagerStore.selectedSerials.toList();
    if (selectedSerials.isEmpty) {
      _log('Chưa chọn thiết bị nào!', type: LogType.info);
      return;
    }

    isExecuting = true;
    _log('Running script: ${script.name} on ${selectedSerials.length} devices', type: LogType.command);

    await Future.wait(selectedSerials.map((serial) async {
      final device = _deviceManagerStore.devices.firstWhere((d) => d.serial == serial);
      final deviceName = device.modelName;

      await _runScriptUseCase(serial, script).forEach((result) {
        result.fold(
          (Failure failure) => _log(failure.message, serial: serial, model: deviceName, type: LogType.error),
          (String line) => _log(line, serial: serial, model: deviceName, type: LogType.output),
        );
      });
    }));

    isExecuting = false;
  }

  @action
  void clearTerminal() {
    terminalOutput.clear();
  }

  void _log(String message, {String? serial, String? model, required LogType type, int? deviceCount}) {
    // Nếu là lệnh global (không có serial), hiển thị là [ALL] thay vì [???]
    final displaySerial = serial ?? (deviceCount != null && deviceCount > 1 ? 'ALL' : null);
    
    terminalOutput.add(LogEntry(
      message: message,
      serial: displaySerial,
      deviceModel: model,
      type: type,
      deviceCount: deviceCount,
    ));
    
    // Limit to 1000 lines
    if (terminalOutput.length > 1000) {
      terminalOutput.removeAt(0);
    }
  }
}
