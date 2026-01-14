// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poster_customization_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PosterCustomizationStore on _PosterCustomizationStore, Store {
  late final _$selectedFieldIdAtom = Atom(
    name: '_PosterCustomizationStore.selectedFieldId',
    context: context,
  );

  @override
  String? get selectedFieldId {
    _$selectedFieldIdAtom.reportRead();
    return super.selectedFieldId;
  }

  @override
  set selectedFieldId(String? value) {
    _$selectedFieldIdAtom.reportWrite(value, super.selectedFieldId, () {
      super.selectedFieldId = value;
    });
  }

  late final _$selectedDefaultTextAtom = Atom(
    name: '_PosterCustomizationStore.selectedDefaultText',
    context: context,
  );

  @override
  String? get selectedDefaultText {
    _$selectedDefaultTextAtom.reportRead();
    return super.selectedDefaultText;
  }

  @override
  set selectedDefaultText(String? value) {
    _$selectedDefaultTextAtom.reportWrite(value, super.selectedDefaultText, () {
      super.selectedDefaultText = value;
    });
  }

  late final _$textScalesAtom = Atom(
    name: '_PosterCustomizationStore.textScales',
    context: context,
  );

  @override
  ObservableMap<String, double> get textScales {
    _$textScalesAtom.reportRead();
    return super.textScales;
  }

  @override
  set textScales(ObservableMap<String, double> value) {
    _$textScalesAtom.reportWrite(value, super.textScales, () {
      super.textScales = value;
    });
  }

  late final _$textOverridesAtom = Atom(
    name: '_PosterCustomizationStore.textOverrides',
    context: context,
  );

  @override
  ObservableMap<String, String> get textOverrides {
    _$textOverridesAtom.reportRead();
    return super.textOverrides;
  }

  @override
  set textOverrides(ObservableMap<String, String> value) {
    _$textOverridesAtom.reportWrite(value, super.textOverrides, () {
      super.textOverrides = value;
    });
  }

  late final _$_PosterCustomizationStoreActionController = ActionController(
    name: '_PosterCustomizationStore',
    context: context,
  );

  @override
  void selectField(String? id, {String? defaultText}) {
    final _$actionInfo = _$_PosterCustomizationStoreActionController
        .startAction(name: '_PosterCustomizationStore.selectField');
    try {
      return super.selectField(id, defaultText: defaultText);
    } finally {
      _$_PosterCustomizationStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateScale(double scale) {
    final _$actionInfo = _$_PosterCustomizationStoreActionController
        .startAction(name: '_PosterCustomizationStore.updateScale');
    try {
      return super.updateScale(scale);
    } finally {
      _$_PosterCustomizationStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateText(String text) {
    final _$actionInfo = _$_PosterCustomizationStoreActionController
        .startAction(name: '_PosterCustomizationStore.updateText');
    try {
      return super.updateText(text);
    } finally {
      _$_PosterCustomizationStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resetText() {
    final _$actionInfo = _$_PosterCustomizationStoreActionController
        .startAction(name: '_PosterCustomizationStore.resetText');
    try {
      return super.resetText();
    } finally {
      _$_PosterCustomizationStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void reset() {
    final _$actionInfo = _$_PosterCustomizationStoreActionController
        .startAction(name: '_PosterCustomizationStore.reset');
    try {
      return super.reset();
    } finally {
      _$_PosterCustomizationStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
selectedFieldId: ${selectedFieldId},
selectedDefaultText: ${selectedDefaultText},
textScales: ${textScales},
textOverrides: ${textOverrides}
    ''';
  }
}
