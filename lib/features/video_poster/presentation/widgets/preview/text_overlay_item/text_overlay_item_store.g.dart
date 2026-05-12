// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_overlay_item_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$TextOverlayItemStore on _TextOverlayItemStore, Store {
  late final _$propertiesAtom = Atom(
    name: '_TextOverlayItemStore.properties',
    context: context,
  );

  @override
  TextOverlayProperties get properties {
    _$propertiesAtom.reportRead();
    return super.properties;
  }

  @override
  set properties(TextOverlayProperties value) {
    _$propertiesAtom.reportWrite(value, super.properties, () {
      super.properties = value;
    });
  }

  late final _$_TextOverlayItemStoreActionController = ActionController(
    name: '_TextOverlayItemStore',
    context: context,
  );

  @override
  void setEditing(bool value) {
    final _$actionInfo = _$_TextOverlayItemStoreActionController.startAction(
      name: '_TextOverlayItemStore.setEditing',
    );
    try {
      return super.setEditing(value);
    } finally {
      _$_TextOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setHovered(bool value) {
    final _$actionInfo = _$_TextOverlayItemStoreActionController.startAction(
      name: '_TextOverlayItemStore.setHovered',
    );
    try {
      return super.setHovered(value);
    } finally {
      _$_TextOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setInteracting(bool value) {
    final _$actionInfo = _$_TextOverlayItemStoreActionController.startAction(
      name: '_TextOverlayItemStore.setInteracting',
    );
    try {
      return super.setInteracting(value);
    } finally {
      _$_TextOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void onTextChange(String text) {
    final _$actionInfo = _$_TextOverlayItemStoreActionController.startAction(
      name: '_TextOverlayItemStore.onTextChange',
    );
    try {
      return super.onTextChange(text);
    } finally {
      _$_TextOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setTextAlign(TextAlign textAlign) {
    final _$actionInfo = _$_TextOverlayItemStoreActionController.startAction(
      name: '_TextOverlayItemStore.setTextAlign',
    );
    try {
      return super.setTextAlign(textAlign);
    } finally {
      _$_TextOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
properties: ${properties}
    ''';
  }
}
