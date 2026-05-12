// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_overlay_item_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$VideoOverlayItemStore<T extends OverlayProperties>
    on _VideoOverlayItemStore<T>, Store {
  Computed<Color>? _$editingBackgroundColorComputed;

  @override
  Color get editingBackgroundColor =>
      (_$editingBackgroundColorComputed ??= Computed<Color>(
        () => super.editingBackgroundColor,
        name: '_VideoOverlayItemStore.editingBackgroundColor',
      )).value;

  late final _$_VideoOverlayItemStoreActionController = ActionController(
    name: '_VideoOverlayItemStore',
    context: context,
  );

  @override
  void updateLabel(String newLabel) {
    final _$actionInfo = _$_VideoOverlayItemStoreActionController.startAction(
      name: '_VideoOverlayItemStore.updateLabel',
    );
    try {
      return super.updateLabel(newLabel);
    } finally {
      _$_VideoOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updatePosition(double newX, double newY) {
    final _$actionInfo = _$_VideoOverlayItemStoreActionController.startAction(
      name: '_VideoOverlayItemStore.updatePosition',
    );
    try {
      return super.updatePosition(newX, newY);
    } finally {
      _$_VideoOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateFontSize(double newSize) {
    final _$actionInfo = _$_VideoOverlayItemStoreActionController.startAction(
      name: '_VideoOverlayItemStore.updateFontSize',
    );
    try {
      return super.updateFontSize(newSize);
    } finally {
      _$_VideoOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSelected(bool value) {
    final _$actionInfo = _$_VideoOverlayItemStoreActionController.startAction(
      name: '_VideoOverlayItemStore.setSelected',
    );
    try {
      return super.setSelected(value);
    } finally {
      _$_VideoOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setEditing(bool value) {
    final _$actionInfo = _$_VideoOverlayItemStoreActionController.startAction(
      name: '_VideoOverlayItemStore.setEditing',
    );
    try {
      return super.setEditing(value);
    } finally {
      _$_VideoOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setHovered(bool value) {
    final _$actionInfo = _$_VideoOverlayItemStoreActionController.startAction(
      name: '_VideoOverlayItemStore.setHovered',
    );
    try {
      return super.setHovered(value);
    } finally {
      _$_VideoOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setInteracting(bool value) {
    final _$actionInfo = _$_VideoOverlayItemStoreActionController.startAction(
      name: '_VideoOverlayItemStore.setInteracting',
    );
    try {
      return super.setInteracting(value);
    } finally {
      _$_VideoOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void startEditing() {
    final _$actionInfo = _$_VideoOverlayItemStoreActionController.startAction(
      name: '_VideoOverlayItemStore.startEditing',
    );
    try {
      return super.startEditing();
    } finally {
      _$_VideoOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void handleResize({
    required DragUpdateDetails details,
    required double multiplierX,
    required double multiplierY,
    double rotation = 0.0,
  }) {
    final _$actionInfo = _$_VideoOverlayItemStoreActionController.startAction(
      name: '_VideoOverlayItemStore.handleResize',
    );
    try {
      return super.handleResize(
        details: details,
        multiplierX: multiplierX,
        multiplierY: multiplierY,
        rotation: rotation,
      );
    } finally {
      _$_VideoOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void handleDrag(DragUpdateDetails details) {
    final _$actionInfo = _$_VideoOverlayItemStoreActionController.startAction(
      name: '_VideoOverlayItemStore.handleDrag',
    );
    try {
      return super.handleDrag(details);
    } finally {
      _$_VideoOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void handleSelect() {
    final _$actionInfo = _$_VideoOverlayItemStoreActionController.startAction(
      name: '_VideoOverlayItemStore.handleSelect',
    );
    try {
      return super.handleSelect();
    } finally {
      _$_VideoOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
editingBackgroundColor: ${editingBackgroundColor}
    ''';
  }
}
