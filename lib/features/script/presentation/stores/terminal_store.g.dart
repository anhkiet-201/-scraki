// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terminal_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$TerminalStore on _TerminalStore, Store {
  Computed<Set<String>>? _$selectedSerialsComputed;

  @override
  Set<String> get selectedSerials =>
      (_$selectedSerialsComputed ??= Computed<Set<String>>(
        () => super.selectedSerials,
        name: '_TerminalStore.selectedSerials',
      )).value;
  Computed<ObservableList<DeviceEntity>>? _$devicesComputed;

  @override
  ObservableList<DeviceEntity> get devices =>
      (_$devicesComputed ??= Computed<ObservableList<DeviceEntity>>(
        () => super.devices,
        name: '_TerminalStore.devices',
      )).value;
  Computed<bool>? _$hasActiveExecutionComputed;

  @override
  bool get hasActiveExecution =>
      (_$hasActiveExecutionComputed ??= Computed<bool>(
        () => super.hasActiveExecution,
        name: '_TerminalStore.hasActiveExecution',
      )).value;

  late final _$_shellStatesAtom = Atom(
    name: '_TerminalStore._shellStates',
    context: context,
  );

  ObservableMap<String, ShellState> get shellStates {
    _$_shellStatesAtom.reportRead();
    return super._shellStates;
  }

  @override
  ObservableMap<String, ShellState> get _shellStates => shellStates;

  @override
  set _shellStates(ObservableMap<String, ShellState> value) {
    _$_shellStatesAtom.reportWrite(value, super._shellStates, () {
      super._shellStates = value;
    });
  }

  late final _$terminalOutputAtom = Atom(
    name: '_TerminalStore.terminalOutput',
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

  late final _$deviceLogsAtom = Atom(
    name: '_TerminalStore.deviceLogs',
    context: context,
  );

  @override
  ObservableMap<String, ObservableList<LogEntry>> get deviceLogs {
    _$deviceLogsAtom.reportRead();
    return super.deviceLogs;
  }

  @override
  set deviceLogs(ObservableMap<String, ObservableList<LogEntry>> value) {
    _$deviceLogsAtom.reportWrite(value, super.deviceLogs, () {
      super.deviceLogs = value;
    });
  }

  late final _$isExecutingAtom = Atom(
    name: '_TerminalStore.isExecuting',
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
    name: '_TerminalStore.commandInput',
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
    name: '_TerminalStore.commandHistory',
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
    name: '_TerminalStore.historyIndex',
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

  late final _$isTiledViewAtom = Atom(
    name: '_TerminalStore.isTiledView',
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

  late final _$executeCurrentCommandAsyncAction = AsyncAction(
    '_TerminalStore.executeCurrentCommand',
    context: context,
  );

  @override
  Future<void> executeCurrentCommand() {
    return _$executeCurrentCommandAsyncAction.run(
      () => super.executeCurrentCommand(),
    );
  }

  late final _$executeCommandOnDeviceAsyncAction = AsyncAction(
    '_TerminalStore.executeCommandOnDevice',
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
    '_TerminalStore.runScript',
    context: context,
  );

  @override
  Future<void> runScript(ScriptEntity script) {
    return _$runScriptAsyncAction.run(() => super.runScript(script));
  }

  late final _$_TerminalStoreActionController = ActionController(
    name: '_TerminalStore',
    context: context,
  );

  @override
  void setCommandInput(String value) {
    final _$actionInfo = _$_TerminalStoreActionController.startAction(
      name: '_TerminalStore.setCommandInput',
    );
    try {
      return super.setCommandInput(value);
    } finally {
      _$_TerminalStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleTiledView() {
    final _$actionInfo = _$_TerminalStoreActionController.startAction(
      name: '_TerminalStore.toggleTiledView',
    );
    try {
      return super.toggleTiledView();
    } finally {
      _$_TerminalStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void navigateHistory(bool up) {
    final _$actionInfo = _$_TerminalStoreActionController.startAction(
      name: '_TerminalStore.navigateHistory',
    );
    try {
      return super.navigateHistory(up);
    } finally {
      _$_TerminalStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearTerminal() {
    final _$actionInfo = _$_TerminalStoreActionController.startAction(
      name: '_TerminalStore.clearTerminal',
    );
    try {
      return super.clearTerminal();
    } finally {
      _$_TerminalStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void stopCommand(String serial) {
    final _$actionInfo = _$_TerminalStoreActionController.startAction(
      name: '_TerminalStore.stopCommand',
    );
    try {
      return super.stopCommand(serial);
    } finally {
      _$_TerminalStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void stopAll() {
    final _$actionInfo = _$_TerminalStoreActionController.startAction(
      name: '_TerminalStore.stopAll',
    );
    try {
      return super.stopAll();
    } finally {
      _$_TerminalStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectDevicesByRange(int start, int end) {
    final _$actionInfo = _$_TerminalStoreActionController.startAction(
      name: '_TerminalStore.selectDevicesByRange',
    );
    try {
      return super.selectDevicesByRange(start, end);
    } finally {
      _$_TerminalStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectDevicesByGroup(String groupId) {
    final _$actionInfo = _$_TerminalStoreActionController.startAction(
      name: '_TerminalStore.selectDevicesByGroup',
    );
    try {
      return super.selectDevicesByGroup(groupId);
    } finally {
      _$_TerminalStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
terminalOutput: ${terminalOutput},
deviceLogs: ${deviceLogs},
isExecuting: ${isExecuting},
commandInput: ${commandInput},
commandHistory: ${commandHistory},
historyIndex: ${historyIndex},
isTiledView: ${isTiledView},
selectedSerials: ${selectedSerials},
devices: ${devices},
hasActiveExecution: ${hasActiveExecution}
    ''';
  }
}
