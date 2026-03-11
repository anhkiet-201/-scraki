// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'dart:math' as math;

part 'video_overlay_item_store.g.dart';

class VideoOverlayItemStore = _VideoOverlayItemStore
    with _$VideoOverlayItemStore;

abstract class _VideoOverlayItemStore with Store {
  _VideoOverlayItemStore({
    required this.type,
    required String initialLabel,
    required double initialX,
    required double initialY,
    required this.constraints,
    required this.color,
    required double initialFontSize,
    required this.onPositionUpdate,
    required this.onSelect,
    required this.onResize,
    required this.onTextChange,
  }) {
    label = initialLabel;
    x = initialX;
    y = initialY;
    fontSize = initialFontSize;
    controller = TextEditingController(text: initialLabel);
    focusNode = FocusNode();

    // Setup focus listener
    focusNode.addListener(() {
      if (!focusNode.hasFocus && isEditing) {
        setEditing(false);
        onTextChange(type, controller.text);
      }
    });
  }

  // Properties
  final String type;
  final BoxConstraints constraints;
  final Color color;
  final void Function(String type, double x, double y) onPositionUpdate;
  final void Function(String type) onSelect;
  final void Function(String type, double newSize) onResize;
  final void Function(String type, String newValue) onTextChange;

  // Controllers
  late final TextEditingController controller;
  late final FocusNode focusNode;
  final GlobalKey contentKey = GlobalKey();

  // Observable state
  @observable
  String label = '';

  @observable
  double x = 0.0;

  @observable
  double y = 0.0;

  @observable
  double fontSize = 24.0;

  @observable
  bool isSelected = false;

  @observable
  bool isEditing = false;

  @observable
  bool isHovered = false;

  @observable
  bool isInteracting = false;

  // Actions
  @action
  void updateLabel(String newLabel) {
    if (!isEditing) {
      label = newLabel;
      controller.text = newLabel;
    }
  }

  @action
  void updatePosition(double newX, double newY) {
    x = newX;
    y = newY;
  }

  @action
  void updateFontSize(double newSize) {
    fontSize = newSize;
  }

  @action
  void setSelected(bool value) {
    isSelected = value;
    // If we are deselected while editing, force finish editing (save text)
    if (!value && isEditing) {
      setEditing(false);
      // Ensure focus is lost
      focusNode.unfocus();
      // Save changes
      onTextChange(type, controller.text);
    }
  }

  @action
  void setEditing(bool value) {
    isEditing = value;
  }

  @action
  void setHovered(bool value) {
    isHovered = value;
  }

  @action
  void setInteracting(bool value) {
    isInteracting = value;
  }

  @action
  void startEditing() {
    setEditing(true);
    focusNode.requestFocus();
    // Professional touch: Auto-select all text on double click
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  @action
  void handleResize({
    required DragUpdateDetails details,
    required double multiplierX, // -1: left, 1: right, 0: mid
    required double multiplierY, // -1: top, 1: bottom, 0: mid
    double rotation = 0.0,
  }) {
    // 1. Measure ACTUAL starting size BEFORE font change
    final renderBox =
        contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final startSize = renderBox.size;

    // 2. Rotate delta based on object angle
    final angle = rotation * (math.pi / 180);
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    final dx = details.delta.dx * cosA - details.delta.dy * sinA;
    final dy = details.delta.dx * sinA + details.delta.dy * cosA;

    // 3. Calculate size delta based on handle type
    double deltaScale;
    if (multiplierX != 0 && multiplierY != 0) {
      // Corner: Responsive to both (diagonal)
      deltaScale = (multiplierX * dx + multiplierY * dy) * 0.05;
    } else if (multiplierX != 0) {
      // Mid-Side: Horizontal focus
      deltaScale = multiplierX * dx * 0.05;
    } else {
      // Mid-Top/Bottom: Vertical focus
      deltaScale = multiplierY * dy * 0.05;
    }

    final newFontSize = (fontSize + deltaScale).clamp(10.0, 200.0);
    if ((newFontSize - fontSize).abs() < 0.01) return;

    // 3. Calculate growth based on standard scaling
    final growthFactor = newFontSize / fontSize;
    final dW = startSize.width * (growthFactor - 1);
    final dH = startSize.height * (growthFactor - 1);

    // 4. Update Font Size
    updateFontSize(newFontSize);
    onResize(type, newFontSize);

    // 5. Apply calculated shift to maintain anchor
    final newX = (x + (multiplierX * dW / 2) / constraints.maxWidth).clamp(
      0.0,
      1.0,
    );
    final newY = (y + (multiplierY * dH / 2) / constraints.maxHeight).clamp(
      0.0,
      1.0,
    );

    updatePosition(newX, newY);
    onPositionUpdate(type, newX, newY);
  }

  @action
  void handleDrag(DragUpdateDetails details) {
    if (isEditing) return;

    final newX = (x + details.delta.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final newY = (y + details.delta.dy / constraints.maxHeight).clamp(0.0, 1.0);

    updatePosition(newX, newY);
    onPositionUpdate(type, newX, newY);
  }

  @action
  void handleSelect() {
    onSelect(type);
  }

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}
