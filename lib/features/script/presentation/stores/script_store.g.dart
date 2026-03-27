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

  late final _$predefinedScriptsAtom = Atom(
    name: '_ScriptStore.predefinedScripts',
    context: context,
  );

  @override
  ObservableList<ScriptEntity> get predefinedScripts {
    _$predefinedScriptsAtom.reportRead();
    return super.predefinedScripts;
  }

  @override
  set predefinedScripts(ObservableList<ScriptEntity> value) {
    _$predefinedScriptsAtom.reportWrite(value, super.predefinedScripts, () {
      super.predefinedScripts = value;
    });
  }

  late final _$terminalOutputAtom = Atom(
    name: '_ScriptStore.terminalOutput',
    context: context,
  );

  @override
  ObservableList<String> get terminalOutput {
    _$terminalOutputAtom.reportRead();
    return super.terminalOutput;
  }

  @override
  set terminalOutput(ObservableList<String> value) {
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
predefinedScripts: ${predefinedScripts},
terminalOutput: ${terminalOutput},
isExecuting: ${isExecuting},
commandInput: ${commandInput},
selectedSerials: ${selectedSerials},
devices: ${devices}
    ''';
  }
}
