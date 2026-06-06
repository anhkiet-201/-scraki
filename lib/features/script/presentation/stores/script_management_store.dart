// ignore_for_file: avoid_print
import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:fpdart/fpdart.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import 'package:scraki/features/script/domain/entities/log_entry.dart'; // Thêm import này
import 'package:scraki/features/script/domain/repositories/script_repository.dart';
import 'package:scraki/features/script/domain/usecases/save_script_use_case.dart';
import 'package:scraki/features/script/domain/usecases/delete_script_use_case.dart';
import 'package:scraki/core/auth/presentation/stores/app_auth_store.dart';
import 'package:scraki/core/di/injection.dart';

part 'script_management_store.g.dart';

@singleton
class ScriptManagementStore = _ScriptManagementStore with _$ScriptManagementStore;

abstract class _ScriptManagementStore with Store {
  final ScriptRepository _repository;
  final SaveScriptUseCase _saveScriptUseCase;
  final DeleteScriptUseCase _deleteScriptUseCase;
  
  final _logController = StreamController<LogEntry>.broadcast();
  Stream<LogEntry> get logStream => _logController.stream;

  _ScriptManagementStore(
    this._repository,
    this._saveScriptUseCase,
    this._deleteScriptUseCase,
  ) {
    init();
  }

  @observable
  ObservableList<ScriptEntity> scripts = ObservableList<ScriptEntity>();

  @observable
  ScriptEntity? editingScript;

  @observable
  String searchQuery = '';

  @action
  void setSearchQuery(String query) {
    searchQuery = query;
  }

  @computed
  List<ScriptEntity> get filteredScripts {
    if (searchQuery.trim().isEmpty) {
      return scripts;
    }
    final query = searchQuery.trim().toLowerCase();
    return scripts.where((script) {
      final nameMatch = script.name.toLowerCase().contains(query);
      final descMatch = script.description.toLowerCase().contains(query);
      return nameMatch || descMatch;
    }).toList();
  }

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
        (failure) {
          _log('Lỗi tải script realtime: ${failure.message}', type: LogType.error);
        },
        (loadedScripts) {
          scripts.clear();
          scripts.addAll(loadedScripts);
        },
      );
    });
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
  void setEditingScript(ScriptEntity? script) {
    editingScript = script;
  }

  @action
  void updateEditingScript({
    String? name,
    String? description,
    List<String>? commands,
    ScriptTileType? tileType,
    bool? enableFileDrop,
  }) {
    if (editingScript == null) {
      editingScript = ScriptEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name ?? 'New Script',
        description: description ?? '',
        commands: commands ?? [],
        tileType: tileType ?? ScriptTileType.normal,
        enableFileDrop: enableFileDrop ?? false,
      );
    } else {
      editingScript = editingScript!.copyWith(
        name: name,
        description: description,
        commands: commands,
        tileType: tileType,
        enableFileDrop: enableFileDrop,
        updatedAt: DateTime.now(),
      );
    }
  }

  @action
  Future<void> saveCurrentScript() async {
    if (!getIt<AppAuthStore>().isAuthenticated) {
      _log('Lỗi: Cần xác thực (Anonymous Auth) để lưu script!', type: LogType.error);
      return;
    }
    if (editingScript == null) return;
    final result = await _saveScriptUseCase(editingScript!);
    result.fold(
      (failure) => _log('Lỗi lưu script: ${failure.message}', type: LogType.error),
      (_) {
        _log('Đã lưu script: ${editingScript?.name ?? ''}', type: LogType.info);
        loadScripts();
      },
    );
  }

  @action
  Future<void> deleteScript(String id) async {
    if (!getIt<AppAuthStore>().isAuthenticated) {
      _log('Lỗi: Cần xác thực (Anonymous Auth) để xóa script!', type: LogType.error);
      return;
    }
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

  void _log(String message, {required LogType type}) {
    _logController.add(LogEntry(
      message: message,
      type: type,
    ));
  }

  void dispose() {
    _scriptsSubscription?.cancel();
    _logController.close();
  }
}
