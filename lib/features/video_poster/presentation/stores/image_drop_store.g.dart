// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_drop_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ImageDropStore on _ImageDropStoreBase, Store {
  late final _$isDraggingAtom = Atom(
    name: '_ImageDropStoreBase.isDragging',
    context: context,
  );

  @override
  bool get isDragging {
    _$isDraggingAtom.reportRead();
    return super.isDragging;
  }

  @override
  set isDragging(bool value) {
    _$isDraggingAtom.reportWrite(value, super.isDragging, () {
      super.isDragging = value;
    });
  }

  late final _$isProcessingAtom = Atom(
    name: '_ImageDropStoreBase.isProcessing',
    context: context,
  );

  @override
  bool get isProcessing {
    _$isProcessingAtom.reportRead();
    return super.isProcessing;
  }

  @override
  set isProcessing(bool value) {
    _$isProcessingAtom.reportWrite(value, super.isProcessing, () {
      super.isProcessing = value;
    });
  }

  late final _$_ImageDropStoreBaseActionController = ActionController(
    name: '_ImageDropStoreBase',
    context: context,
  );

  @override
  void setDragging(bool value) {
    final _$actionInfo = _$_ImageDropStoreBaseActionController.startAction(
      name: '_ImageDropStoreBase.setDragging',
    );
    try {
      return super.setDragging(value);
    } finally {
      _$_ImageDropStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void handlePerformDrop(
    PerformDropEvent event, {
    required void Function(String, bool) onImageFound,
  }) {
    final _$actionInfo = _$_ImageDropStoreBaseActionController.startAction(
      name: '_ImageDropStoreBase.handlePerformDrop',
    );
    try {
      return super.handlePerformDrop(event, onImageFound: onImageFound);
    } finally {
      _$_ImageDropStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  DropOperation handleDropOver(DropOverEvent event, bool isOnVideoEditorTab) {
    final _$actionInfo = _$_ImageDropStoreBaseActionController.startAction(
      name: '_ImageDropStoreBase.handleDropOver',
    );
    try {
      return super.handleDropOver(event, isOnVideoEditorTab);
    } finally {
      _$_ImageDropStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isDragging: ${isDragging},
isProcessing: ${isProcessing}
    ''';
  }
}
