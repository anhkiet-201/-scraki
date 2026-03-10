// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_overlay_item_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ImageOverlayItemStore on _ImageOverlayItemStore, Store {
  late final _$xAtom = Atom(name: '_ImageOverlayItemStore.x', context: context);

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

  late final _$yAtom = Atom(name: '_ImageOverlayItemStore.y', context: context);

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

  late final _$widthAtom = Atom(
    name: '_ImageOverlayItemStore.width',
    context: context,
  );

  @override
  double get width {
    _$widthAtom.reportRead();
    return super.width;
  }

  @override
  set width(double value) {
    _$widthAtom.reportWrite(value, super.width, () {
      super.width = value;
    });
  }

  late final _$heightAtom = Atom(
    name: '_ImageOverlayItemStore.height',
    context: context,
  );

  @override
  double get height {
    _$heightAtom.reportRead();
    return super.height;
  }

  @override
  set height(double value) {
    _$heightAtom.reportWrite(value, super.height, () {
      super.height = value;
    });
  }

  late final _$isSelectedAtom = Atom(
    name: '_ImageOverlayItemStore.isSelected',
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

  late final _$isHoveredAtom = Atom(
    name: '_ImageOverlayItemStore.isHovered',
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
    name: '_ImageOverlayItemStore.isInteracting',
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

  late final _$_ImageOverlayItemStoreActionController = ActionController(
    name: '_ImageOverlayItemStore',
    context: context,
  );

  @override
  void updatePosition(double newX, double newY) {
    final _$actionInfo = _$_ImageOverlayItemStoreActionController.startAction(
      name: '_ImageOverlayItemStore.updatePosition',
    );
    try {
      return super.updatePosition(newX, newY);
    } finally {
      _$_ImageOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateSize(double newWidth, double newHeight) {
    final _$actionInfo = _$_ImageOverlayItemStoreActionController.startAction(
      name: '_ImageOverlayItemStore.updateSize',
    );
    try {
      return super.updateSize(newWidth, newHeight);
    } finally {
      _$_ImageOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSelected(bool value) {
    final _$actionInfo = _$_ImageOverlayItemStoreActionController.startAction(
      name: '_ImageOverlayItemStore.setSelected',
    );
    try {
      return super.setSelected(value);
    } finally {
      _$_ImageOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setHovered(bool value) {
    final _$actionInfo = _$_ImageOverlayItemStoreActionController.startAction(
      name: '_ImageOverlayItemStore.setHovered',
    );
    try {
      return super.setHovered(value);
    } finally {
      _$_ImageOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setInteracting(bool value) {
    final _$actionInfo = _$_ImageOverlayItemStoreActionController.startAction(
      name: '_ImageOverlayItemStore.setInteracting',
    );
    try {
      return super.setInteracting(value);
    } finally {
      _$_ImageOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void handleResize({
    required DragUpdateDetails details,
    required double multiplierX,
    required double multiplierY,
  }) {
    final _$actionInfo = _$_ImageOverlayItemStoreActionController.startAction(
      name: '_ImageOverlayItemStore.handleResize',
    );
    try {
      return super.handleResize(
        details: details,
        multiplierX: multiplierX,
        multiplierY: multiplierY,
      );
    } finally {
      _$_ImageOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void handleDrag(DragUpdateDetails details) {
    final _$actionInfo = _$_ImageOverlayItemStoreActionController.startAction(
      name: '_ImageOverlayItemStore.handleDrag',
    );
    try {
      return super.handleDrag(details);
    } finally {
      _$_ImageOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void handleSelect() {
    final _$actionInfo = _$_ImageOverlayItemStoreActionController.startAction(
      name: '_ImageOverlayItemStore.handleSelect',
    );
    try {
      return super.handleSelect();
    } finally {
      _$_ImageOverlayItemStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
x: ${x},
y: ${y},
width: ${width},
height: ${height},
isSelected: ${isSelected},
isHovered: ${isHovered},
isInteracting: ${isInteracting}
    ''';
  }
}
