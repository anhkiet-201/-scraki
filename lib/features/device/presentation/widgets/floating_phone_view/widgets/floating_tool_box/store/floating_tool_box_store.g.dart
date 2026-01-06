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
  String toString() {
    return '''
showJobSelector: ${showJobSelector}
    ''';
  }
}
