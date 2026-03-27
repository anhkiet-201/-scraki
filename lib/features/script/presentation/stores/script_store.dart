import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import '../../../../core/stores/device_manager_store.dart';
import '../../../../core/error/failures.dart';
import '../../../device/domain/entities/device_entity.dart';
import '../../domain/entities/script_entity.dart';
import '../../domain/repositories/script_repository.dart';
import '../../domain/usecases/run_script_use_case.dart';
import '../../domain/usecases/execute_command_use_case.dart';

part 'script_store.g.dart';

@lazySingleton
// ignore: library_private_types_in_public_api
class ScriptStore = _ScriptStore with _$ScriptStore;

abstract class _ScriptStore with Store {
  final ScriptRepository _repository;
  final RunScriptUseCase _runScriptUseCase;
  final ExecuteCommandUseCase _executeCommandUseCase;
  final DeviceManagerStore _deviceManagerStore;

  _ScriptStore(
    this._repository,
    this._runScriptUseCase,
    this._executeCommandUseCase,
    this._deviceManagerStore,
  );

  @computed
  Set<String> get selectedSerials => _deviceManagerStore.selectedSerials;

  @computed
  ObservableList<DeviceEntity> get devices => _deviceManagerStore.devices;

  @action
  void toggleDeviceSelection(String serial) => _deviceManagerStore.toggleDeviceSelection(serial);

  @action
  void clearSelection() => _deviceManagerStore.clearSelection();

  @observable
  ObservableList<ScriptEntity> predefinedScripts = ObservableList<ScriptEntity>();

  @observable
  ObservableList<String> terminalOutput = ObservableList<String>();

  @observable
  bool isExecuting = false;

  @observable
  String commandInput = '';

  @action
  void setCommandInput(String value) => commandInput = value;

  @action
  Future<void> loadScripts() async {
    final result = await _repository.getPredefinedScripts();
    result.fold(
      (failure) => _log('Lỗi tải script: ${failure.message}'),
      (scripts) => predefinedScripts.replaceRange(0, predefinedScripts.length, scripts),
    );
  }

  @action
  Future<void> executeCurrentCommand() async {
    if (commandInput.trim().isEmpty) return;
    final cmd = commandInput;
    commandInput = '';
    
    final selectedSerials = _deviceManagerStore.selectedSerials.toList();
    if (selectedSerials.isEmpty) {
      _log('Chưa chọn thiết bị nào!');
      return;
    }

    isExecuting = true;
    _log('>>> Thực thi: $cmd trên ${selectedSerials.length} thiết bị');

    await Future.wait(selectedSerials.map((serial) async {
      final device = _deviceManagerStore.devices.firstWhere((d) => d.serial == serial);
      final deviceName = device.modelName;
      
      final result = await _executeCommandUseCase(serial, cmd);
      result.fold(
        (Failure failure) => _log('[$deviceName] Lỗi: ${failure.message}'),
        (String output) => _log('[$deviceName]\n$output'),
      );
    }));

    isExecuting = false;
  }

  @action
  Future<void> runScript(ScriptEntity script) async {
    final selectedSerials = _deviceManagerStore.selectedSerials.toList();
    if (selectedSerials.isEmpty) {
      _log('Chưa chọn thiết bị nào!');
      return;
    }

    isExecuting = true;
    _log('>>> Chạy script: ${script.name} trên ${selectedSerials.length} thiết bị');

    await Future.wait(selectedSerials.map((serial) async {
      final device = _deviceManagerStore.devices.firstWhere((d) => d.serial == serial);
      final deviceName = device.modelName;

      final result = await _runScriptUseCase(serial, script);
      result.fold(
        (Failure failure) => _log('[$deviceName] Lỗi: ${failure.message}'),
        (String output) => _log('[$deviceName]\n$output'),
      );
    }));

    isExecuting = false;
  }

  @action
  void clearTerminal() {
    terminalOutput.clear();
  }

  void _log(String message) {
    terminalOutput.add(message);
    // Giới hạn log tối đa 1000 dòng
    if (terminalOutput.length > 1000) {
      terminalOutput.removeAt(0);
    }
  }
}
