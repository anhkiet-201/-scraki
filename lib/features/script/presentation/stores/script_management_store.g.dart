// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_management_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ScriptManagementStore on _ScriptManagementStore, Store {
  Computed<List<ScriptEntity>>? _$filteredScriptsComputed;

  @override
  List<ScriptEntity> get filteredScripts =>
      (_$filteredScriptsComputed ??= Computed<List<ScriptEntity>>(
        () => super.filteredScripts,
        name: '_ScriptManagementStore.filteredScripts',
      )).value;

  late final _$scriptsAtom = Atom(
    name: '_ScriptManagementStore.scripts',
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

  late final _$editingScriptAtom = Atom(
    name: '_ScriptManagementStore.editingScript',
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

  late final _$searchQueryAtom = Atom(
    name: '_ScriptManagementStore.searchQuery',
    context: context,
  );

  @override
  String get searchQuery {
    _$searchQueryAtom.reportRead();
    return super.searchQuery;
  }

  @override
  set searchQuery(String value) {
    _$searchQueryAtom.reportWrite(value, super.searchQuery, () {
      super.searchQuery = value;
    });
  }

  late final _$loadScriptsAsyncAction = AsyncAction(
    '_ScriptManagementStore.loadScripts',
    context: context,
  );

  @override
  Future<void> loadScripts() {
    return _$loadScriptsAsyncAction.run(() => super.loadScripts());
  }

  late final _$saveCurrentScriptAsyncAction = AsyncAction(
    '_ScriptManagementStore.saveCurrentScript',
    context: context,
  );

  @override
  Future<void> saveCurrentScript() {
    return _$saveCurrentScriptAsyncAction.run(() => super.saveCurrentScript());
  }

  late final _$deleteScriptAsyncAction = AsyncAction(
    '_ScriptManagementStore.deleteScript',
    context: context,
  );

  @override
  Future<void> deleteScript(String id) {
    return _$deleteScriptAsyncAction.run(() => super.deleteScript(id));
  }

  late final _$_ScriptManagementStoreActionController = ActionController(
    name: '_ScriptManagementStore',
    context: context,
  );

  @override
  void setSearchQuery(String query) {
    final _$actionInfo = _$_ScriptManagementStoreActionController.startAction(
      name: '_ScriptManagementStore.setSearchQuery',
    );
    try {
      return super.setSearchQuery(query);
    } finally {
      _$_ScriptManagementStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void init() {
    final _$actionInfo = _$_ScriptManagementStoreActionController.startAction(
      name: '_ScriptManagementStore.init',
    );
    try {
      return super.init();
    } finally {
      _$_ScriptManagementStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void watchScripts() {
    final _$actionInfo = _$_ScriptManagementStoreActionController.startAction(
      name: '_ScriptManagementStore.watchScripts',
    );
    try {
      return super.watchScripts();
    } finally {
      _$_ScriptManagementStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setEditingScript(ScriptEntity? script) {
    final _$actionInfo = _$_ScriptManagementStoreActionController.startAction(
      name: '_ScriptManagementStore.setEditingScript',
    );
    try {
      return super.setEditingScript(script);
    } finally {
      _$_ScriptManagementStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateEditingScript({
    String? name,
    String? description,
    List<String>? commands,
    ScriptTileType? tileType,
    bool? enableFileDrop,
  }) {
    final _$actionInfo = _$_ScriptManagementStoreActionController.startAction(
      name: '_ScriptManagementStore.updateEditingScript',
    );
    try {
      return super.updateEditingScript(
        name: name,
        description: description,
        commands: commands,
        tileType: tileType,
        enableFileDrop: enableFileDrop,
      );
    } finally {
      _$_ScriptManagementStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
scripts: ${scripts},
editingScript: ${editingScript},
searchQuery: ${searchQuery},
filteredScripts: ${filteredScripts}
    ''';
  }
}
