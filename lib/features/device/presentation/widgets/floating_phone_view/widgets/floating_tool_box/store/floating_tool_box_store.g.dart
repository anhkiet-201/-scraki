// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'floating_tool_box_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$FloatingToolBoxStore on _FloatingToolBoxStore, Store {
  late final _$showJobSelectorAtom = Atom(
    name: '_FloatingToolBoxStore.showJobSelector',
    context: context,
  );

  @override
  bool get showJobSelector {
    _$showJobSelectorAtom.reportRead();
    return super.showJobSelector;
  }

  @override
  set showJobSelector(bool value) {
    _$showJobSelectorAtom.reportWrite(value, super.showJobSelector, () {
      super.showJobSelector = value;
    });
  }

  late final _$showEmailPanelAtom = Atom(
    name: '_FloatingToolBoxStore.showEmailPanel',
    context: context,
  );

  @override
  bool get showEmailPanel {
    _$showEmailPanelAtom.reportRead();
    return super.showEmailPanel;
  }

  @override
  set showEmailPanel(bool value) {
    _$showEmailPanelAtom.reportWrite(value, super.showEmailPanel, () {
      super.showEmailPanel = value;
    });
  }

  late final _$showAuthPanelAtom = Atom(
    name: '_FloatingToolBoxStore.showAuthPanel',
    context: context,
  );

  @override
  bool get showAuthPanel {
    _$showAuthPanelAtom.reportRead();
    return super.showAuthPanel;
  }

  @override
  set showAuthPanel(bool value) {
    _$showAuthPanelAtom.reportWrite(value, super.showAuthPanel, () {
      super.showAuthPanel = value;
    });
  }

  late final _$sendPowerButtonAsyncAction = AsyncAction(
    '_FloatingToolBoxStore.sendPowerButton',
    context: context,
  );

  @override
  Future<void> sendPowerButton(String serial) {
    return _$sendPowerButtonAsyncAction.run(
      () => super.sendPowerButton(serial),
    );
  }

  late final _$sendBackButtonAsyncAction = AsyncAction(
    '_FloatingToolBoxStore.sendBackButton',
    context: context,
  );

  @override
  Future<void> sendBackButton(String serial) {
    return _$sendBackButtonAsyncAction.run(() => super.sendBackButton(serial));
  }

  late final _$sendHomeButtonAsyncAction = AsyncAction(
    '_FloatingToolBoxStore.sendHomeButton',
    context: context,
  );

  @override
  Future<void> sendHomeButton(String serial) {
    return _$sendHomeButtonAsyncAction.run(() => super.sendHomeButton(serial));
  }

  late final _$sendRecentAppsButtonAsyncAction = AsyncAction(
    '_FloatingToolBoxStore.sendRecentAppsButton',
    context: context,
  );

  @override
  Future<void> sendRecentAppsButton(String serial) {
    return _$sendRecentAppsButtonAsyncAction.run(
      () => super.sendRecentAppsButton(serial),
    );
  }

  late final _$openTikTokInboxAsyncAction = AsyncAction(
    '_FloatingToolBoxStore.openTikTokInbox',
    context: context,
  );

  @override
  Future<void> openTikTokInbox(String serial) {
    return _$openTikTokInboxAsyncAction.run(
      () => super.openTikTokInbox(serial),
    );
  }

  late final _$openTikTokProfileAsyncAction = AsyncAction(
    '_FloatingToolBoxStore.openTikTokProfile',
    context: context,
  );

  @override
  Future<void> openTikTokProfile(String serial) {
    return _$openTikTokProfileAsyncAction.run(
      () => super.openTikTokProfile(serial),
    );
  }

  late final _$_FloatingToolBoxStoreActionController = ActionController(
    name: '_FloatingToolBoxStore',
    context: context,
  );

  @override
  void toggleJobSelector() {
    final _$actionInfo = _$_FloatingToolBoxStoreActionController.startAction(
      name: '_FloatingToolBoxStore.toggleJobSelector',
    );
    try {
      return super.toggleJobSelector();
    } finally {
      _$_FloatingToolBoxStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void hideJobSelector() {
    final _$actionInfo = _$_FloatingToolBoxStoreActionController.startAction(
      name: '_FloatingToolBoxStore.hideJobSelector',
    );
    try {
      return super.hideJobSelector();
    } finally {
      _$_FloatingToolBoxStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleEmailPanel() {
    final _$actionInfo = _$_FloatingToolBoxStoreActionController.startAction(
      name: '_FloatingToolBoxStore.toggleEmailPanel',
    );
    try {
      return super.toggleEmailPanel();
    } finally {
      _$_FloatingToolBoxStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void hideEmailPanel() {
    final _$actionInfo = _$_FloatingToolBoxStoreActionController.startAction(
      name: '_FloatingToolBoxStore.hideEmailPanel',
    );
    try {
      return super.hideEmailPanel();
    } finally {
      _$_FloatingToolBoxStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleAuthPanel() {
    final _$actionInfo = _$_FloatingToolBoxStoreActionController.startAction(
      name: '_FloatingToolBoxStore.toggleAuthPanel',
    );
    try {
      return super.toggleAuthPanel();
    } finally {
      _$_FloatingToolBoxStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void hideAuthPanel() {
    final _$actionInfo = _$_FloatingToolBoxStoreActionController.startAction(
      name: '_FloatingToolBoxStore.hideAuthPanel',
    );
    try {
      return super.hideAuthPanel();
    } finally {
      _$_FloatingToolBoxStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
showJobSelector: ${showJobSelector},
showEmailPanel: ${showEmailPanel},
showAuthPanel: ${showAuthPanel}
    ''';
  }
}
