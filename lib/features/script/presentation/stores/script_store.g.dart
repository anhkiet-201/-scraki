// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ScriptStore on _ScriptStore, Store {
  Computed<Set<String>>? _$selectedSerialsComputed;

  @override
  Set<String> get selectedSerials =>
      (_$selectedSerialsComputed ??= Computed<Set<String>>(
        () => super.selectedSerials,
        name: '_ScriptStore.selectedSerials',
      )).value;
  Computed<ObservableList<DeviceEntity>>? _$devicesComputed;

  @override
  ObservableList<DeviceEntity> get devices =>
      (_$devicesComputed ??= Computed<ObservableList<DeviceEntity>>(
        () => super.devices,
        name: '_ScriptStore.devices',
      )).value;
  Computed<bool>? _$hasActiveExecutionComputed;

  @override
  bool get hasActiveExecution =>
      (_$hasActiveExecutionComputed ??= Computed<bool>(
        () => super.hasActiveExecution,
        name: '_ScriptStore.hasActiveExecution',
      )).value;

  late final _$scriptsAtom = Atom(
    name: '_ScriptStore.scripts',
    context: context,
  );

  @override
  ObservableList<ScriptEntity> get scripts {
    _$scriptsAtom.reportRead();
    return super.scripts;
  }

  @override
  set scripts(ObservableList<ScriptEntity> value) {
    _$scriptsAtom.reportWrite(value, super.scripts, () {
      super.scripts = value;
    });
  }

  late final _$terminalOutputAtom = Atom(
    name: '_ScriptStore.terminalOutput',
    context: context,
  );

  @override
  ObservableList<LogEntry> get terminalOutput {
    _$terminalOutputAtom.reportRead();
    return super.terminalOutput;
  }

  @override
  set terminalOutput(ObservableList<LogEntry> value) {
    _$terminalOutputAtom.reportWrite(value, super.terminalOutput, () {
      super.terminalOutput = value;
    });
  }

  late final _$isExecutingAtom = Atom(
    name: '_ScriptStore.isExecuting',
    context: context,
  );

  @override
  bool get isExecuting {
    _$isExecutingAtom.reportRead();
    return super.isExecuting;
  }

  @override
  set isExecuting(bool value) {
    _$isExecutingAtom.reportWrite(value, super.isExecuting, () {
      super.isExecuting = value;
    });
  }

  late final _$commandInputAtom = Atom(
    name: '_ScriptStore.commandInput',
    context: context,
  );

  @override
  String get commandInput {
    _$commandInputAtom.reportRead();
    return super.commandInput;
  }

  @override
  set commandInput(String value) {
    _$commandInputAtom.reportWrite(value, super.commandInput, () {
      super.commandInput = value;
    });
  }

  late final _$commandHistoryAtom = Atom(
    name: '_ScriptStore.commandHistory',
    context: context,
  );

  @override
  ObservableList<String> get commandHistory {
    _$commandHistoryAtom.reportRead();
    return super.commandHistory;
  }

  @override
  set commandHistory(ObservableList<String> value) {
    _$commandHistoryAtom.reportWrite(value, super.commandHistory, () {
      super.commandHistory = value;
    });
  }

  late final _$historyIndexAtom = Atom(
    name: '_ScriptStore.historyIndex',
    context: context,
  );

  @override
  int get historyIndex {
    _$historyIndexAtom.reportRead();
    return super.historyIndex;
  }

  @override
  set historyIndex(int value) {
    _$historyIndexAtom.reportWrite(value, super.historyIndex, () {
      super.historyIndex = value;
    });
  }

  late final _$editingScriptAtom = Atom(
    name: '_ScriptStore.editingScript',
    context: context,
  );

  @override
  ScriptEntity? get editingScript {
    _$editingScriptAtom.reportRead();
    return super.editingScript;
  }

  @override
  set editingScript(ScriptEntity? value) {
    _$editingScriptAtom.reportWrite(value, super.editingScript, () {
      super.editingScript = value;
    });
  }

  late final _$isTiledViewAtom = Atom(
    name: '_ScriptStore.isTiledView',
    context: context,
  );

  @override
  bool get isTiledView {
    _$isTiledViewAtom.reportRead();
    return super.isTiledView;
  }

  @override
  set isTiledView(bool value) {
    _$isTiledViewAtom.reportWrite(value, super.isTiledView, () {
      super.isTiledView = value;
    });
  }

  late final _$saveCurrentScriptAsyncAction = AsyncAction(
    '_ScriptStore.saveCurrentScript',
    context: context,
  );

  @override
  Future<void> saveCurrentScript() {
    return _$saveCurrentScriptAsyncAction.run(() => super.saveCurrentScript());
  }

  late final _$deleteScriptAsyncAction = AsyncAction(
    '_ScriptStore.deleteScript',
    context: context,
  );

  @override
  Future<void> deleteScript(String id) {
    return _$deleteScriptAsyncAction.run(() => super.deleteScript(id));
  }

  late final _$loadScriptsAsyncAction = AsyncAction(
    '_ScriptStore.loadScripts',
    context: context,
  );

  @override
  Future<void> loadScripts() {
    return _$loadScriptsAsyncAction.run(() => super.loadScripts());
  }

  late final _$executeCurrentCommandAsyncAction = AsyncAction(
    '_ScriptStore.executeCurrentCommand',
    context: context,
  );

  @override
  Future<void> executeCurrentCommand() {
    return _$executeCurrentCommandAsyncAction.run(
      () => super.executeCurrentCommand(),
    );
  }

  late final _$executeCommandOnDeviceAsyncAction = AsyncAction(
    '_ScriptStore.executeCommandOnDevice',
    context: context,
  );

  @override
  Future<void> executeCommandOnDevice(
    String serial,
    String command, {
    bool logCommand = true,
  }) {
    return _$executeCommandOnDeviceAsyncAction.run(
      () =>
          super.executeCommandOnDevice(serial, command, logCommand: logCommand),
    );
  }

  late final _$runScriptAsyncAction = AsyncAction(
    '_ScriptStore.runScript',
    context: context,
  );

  @override
  Future<void> runScript(ScriptEntity script) {
    return _$runScriptAsyncAction.run(() => super.runScript(script));
  }

  late final _$_ScriptStoreActionController = ActionController(
    name: '_ScriptStore',
    context: context,
  );

  @override
  void toggleDeviceSelection(String serial) {
    final _$actionInfo = _$_ScriptStoreActionController.startAction(
      name: '_ScriptStore.toggleDeviceSelection',
    );
    try {
      return super.toggleDeviceSelection(serial);
    } finally {
      _$_ScriptStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectAllDevices(bool select) {
    final _$actionInfo = _$_ScriptStoreActionController.startAction(
      name: '_ScriptStore.selectAllDevices',
    );
    try {
      return super.selectAllDevices(select);
    } finally {
      _$_ScriptStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectDevicesByRange(int start, int end) {
    final _$actionInfo = _$_ScriptStoreActionController.startAction(
      name: '_ScriptStore.selectDevicesByRange',
    );
    try {
      return super.selectDevicesByRange(start, end);
    } finally {
      _$_ScriptStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearSelection() {
    final _$actionInfo = _$_ScriptStoreActionController.startAction(
      name: '_ScriptStore.clearSelection',
    );
    try {
      return super.clearSelection();
    } finally {
      _$_ScriptStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCommandInput(String value) {
    final _$actionInfo = _$_ScriptStoreActionController.startAction(
      name: '_ScriptStore.setCommandInput',
    );
    try {
      return super.setCommandInput(value);
    } finally {
      _$_ScriptStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleTiledView() {
    final _$actionInfo = _$_ScriptStoreActionController.startAction(
      name: '_ScriptStore.toggleTiledView',
    );
    try {
      return super.toggleTiledView();
    } finally {
      _$_ScriptStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setEditingScript(ScriptEntity? script) {
    final _$actionInfo = _$_ScriptStoreActionController.startAction(
      name: '_ScriptStore.setEditingScript',
    );
    try {
      return super.setEditingScript(script);
    } finally {
      _$_ScriptStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateEditingScript({
    String? name,
    String? description,
    List<String>? commands,
  }) {
    final _$actionInfo = _$_ScriptStoreActionController.startAction(
      name: '_ScriptStore.updateEditingScript',
    );
    try {
      return super.updateEditingScript(
        name: name,
        description: description,
        commands: commands,
      );
    } finally {
      _$_ScriptStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void stopCommand(String serial) {
    final _$actionInfo = _$_ScriptStoreActionController.startAction(
      name: '_ScriptStore.stopCommand',
    );
    try {
      return super.stopCommand(serial);
    } finally {
      _$_ScriptStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void stopAll() {
    final _$actionInfo = _$_ScriptStoreActionController.startAction(
      name: '_ScriptStore.stopAll',
    );
    try {
      return super.stopAll();
    } finally {
      _$_ScriptStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void navigateHistory(bool up) {
    final _$actionInfo = _$_ScriptStoreActionController.startAction(
      name: '_ScriptStore.navigateHistory',
    );
    try {
      return super.navigateHistory(up);
    } finally {
      _$_ScriptStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearTerminal() {
    final _$actionInfo = _$_ScriptStoreActionController.startAction(
      name: '_ScriptStore.clearTerminal',
    );
    try {
      return super.clearTerminal();
    } finally {
      _$_ScriptStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
scripts: ${scripts},
terminalOutput: ${terminalOutput},
isExecuting: ${isExecuting},
commandInput: ${commandInput},
commandHistory: ${commandHistory},
historyIndex: ${historyIndex},
editingScript: ${editingScript},
isTiledView: ${isTiledView},
selectedSerials: ${selectedSerials},
devices: ${devices},
hasActiveExecution: ${hasActiveExecution}
    ''';
  }
}
