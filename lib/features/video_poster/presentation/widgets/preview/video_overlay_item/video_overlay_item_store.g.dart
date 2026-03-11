// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_overlay_item_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$VideoOverlayItemStore on _VideoOverlayItemStore, Store {
  late final _$labelAtom = Atom(
    name: '_VideoOverlayItemStore.label',
    context: context,
  );

  @override
  String get label {
    _$labelAtom.reportRead();
    return super.label;
  }

  @override
  set label(String value) {
    _$labelAtom.reportWrite(value, super.label, () {
      super.label = value;
    });
  }

  late final _$xAtom = Atom(name: '_VideoOverlayItemStore.x', context: context);

  @override
  double get x {
    _$xAtom.reportRead();
    return super.x;
  }

  @override
  set x(double value) {
    _$xAtom.reportWrite(value, super.x, () {
      super.x = value;
    });
  }

  late final _$yAtom = Atom(name: '_VideoOverlayItemStore.y', context: context);

  @override
  double get y {
    _$yAtom.reportRead();
    return super.y;
  }

  @override
  set y(double value) {
    _$yAtom.reportWrite(value, super.y, () {
      super.y = value;
    });
  }

  late final _$fontSizeAtom = Atom(
    name: '_VideoOverlayItemStore.fontSize',
    context: context,
  );

  @override
  double get fontSize {
    _$fontSizeAtom.reportRead();
    return super.fontSize;
  }

  @override
  set fontSize(double value) {
    _$fontSizeAtom.reportWrite(value, super.fontSize, () {
      super.fontSize = value;
    });
  }

  late final _$isSelectedAtom = Atom(
    name: '_VideoOverlayItemStore.isSelected',
    context: context,
  );

  @override
  bool get isSelected {
    _$isSelectedAtom.reportRead();
    return super.isSelected;
  }

  @override
  set isSelected(bool value) {
    _$isSelectedAtom.reportWrite(value, super.isSelected, () {
      super.isSelected = value;
    });
  }

  late final _$isEditingAtom = Atom(
    name: '_VideoOverlayItemStore.isEditing',
    context: context,
  );

  @override
  bool get isEditing {
    _$isEditingAtom.reportRead();
    return super.isEditing;
  }

  @override
  set isEditing(bool value) {
    _$isEditingAtom.reportWrite(value, super.isEditing, () {
      super.isEditing = value;
    });
  }

  late final _$isHoveredAtom = Atom(
    name: '_VideoOverlayItemStore.isHovered',
    context: context,
  );

  @override
  bool get isHovered {
    _$isHoveredAtom.reportRead();
    return super.isHovered;
  }

  @override
  set isHovered(bool value) {
    _$isHoveredAtom.reportWrite(value, super.isHovered, () {
      super.isHovered = value;
    });
  }

  late final _$isInteractingAtom = Atom(
    name: '_VideoOverlayItemStore.isInteracting',
    context: context,
  );

  @override
  bool get isInteracting {
    _$isInteractingAtom.reportRead();
    return super.isInteracting;
  }

  @override
  set isInteracting(bool value) {
    _$isInteractingAtom.reportWrite(value, super.isInteracting, () {
      super.isInteracting = value;
    });
  }

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
label: ${label},
x: ${x},
y: ${y},
fontSize: ${fontSize},
isSelected: ${isSelected},
isEditing: ${isEditing},
isHovered: ${isHovered},
isInteracting: ${isInteracting}
    ''';
  }
}
