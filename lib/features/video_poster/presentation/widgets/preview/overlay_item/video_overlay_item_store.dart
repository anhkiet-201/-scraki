// ignore_for_file: library_private_types_in_public_api
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import 'package:scraki/overlay/overlay.dart';

part 'video_overlay_item_store.g.dart';

class VideoOverlayItemStore<T extends OverlayProperties> = _VideoOverlayItemStore<T> with _$VideoOverlayItemStore<T>;

abstract class _VideoOverlayItemStore<T extends OverlayProperties> with Store {

  _VideoOverlayItemStore({required this.properties}) {
    controller = TextEditingController(text: properties.label);
    focusNode = FocusNode();

    // Setup focus listener
    focusNode.addListener(() {
      if (!focusNode.hasFocus && properties.isEditing) {
        setEditing(false);
        // onTextChange(properties.id, controller.text);
      }
    });
  }

  // final void Function(String type, double x, double y) onPositionUpdate;
  // final void Function(String type) onSelect;
  // final void Function(String type, double newSize) onResize;
  // final void Function(String type, String newValue) onTextChange;

  // Controllers
  late final TextEditingController controller;
  late final FocusNode focusNode;
  final GlobalKey contentKey = GlobalKey();

  final T properties;

  @computed
  Color get editingBackgroundColor {
    final p = properties;

    if (p.isEditing && p is TextOverlayProperties && p.backgroundColor != null) {
      return p.backgroundColor!.withValues(alpha: p.backgroundOpacity);
    }

    return (p.isHovered || p.isSelected)
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.transparent;
  }

  // Actions
  @action
  void updateLabel(String newLabel) {
    if (!properties.isEditing) {
      properties.label = newLabel;
      controller.text = newLabel;
    }
  }

  @action
  void updatePosition(double newX, double newY) {
    properties.x = newX;
    properties.y = newY;
  }

  @action
  void updateFontSize(double newSize) {
    properties.fontSize = newSize;
  }

  @action
  void setSelected(bool value) {
    properties.isSelected = value;
    if (!value && properties.isEditing) {
      setEditing(false);
      focusNode.unfocus();
    }
  }

  @action
  void setEditing(bool value) {
    properties.isEditing = value;
  }

  @action
  void setHovered(bool value) {
    properties.isHovered = value;
  }

  @action
  void setInteracting(bool value) {
    properties.isInteracting = value;
  }

  @action
  void startEditing() {
    setEditing(true);
    focusNode.requestFocus();
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  @action
  void handleResize({
    required DragUpdateDetails details,
    required double multiplierX,
    required double multiplierY,
    double rotation = 0.0,
  }) {
    final angle = rotation * (math.pi / 180);
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    final dxLocal = details.delta.dx * cosA + details.delta.dy * sinA;
    final dyLocal = -details.delta.dx * sinA + details.delta.dy * cosA;

    double dW = 0;
    double dH = 0;

    final p = properties;
    switch (p) {
      case TextOverlayProperties():
        final renderBox = contentKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        final startSize = renderBox.size;

        double deltaScale = (multiplierX != 0 && multiplierY != 0)
            ? (multiplierX * dxLocal + multiplierY * dyLocal) * 0.05
            : (multiplierX != 0 ? multiplierX * dxLocal * 0.05 : multiplierY * dyLocal * 0.05);

        final newFontSize = (p.fontSize + deltaScale).clamp(10.0, 200.0);
        if ((newFontSize - p.fontSize).abs() < 0.01) return;

        final growthFactor = newFontSize / p.fontSize;
        dW = startSize.width * (growthFactor - 1);
        dH = startSize.height * (growthFactor - 1);
        p.fontSize = newFontSize;

      case ImageOverlayProperties():
        final oldW = p.width;
        final oldH = p.height;
        p.width = (oldW + multiplierX * dxLocal).clamp(20.0, 1000.0);
        p.height = (oldH + multiplierY * dyLocal).clamp(20.0, 1000.0);
        dW = p.width - oldW;
        dH = p.height - oldH;
        
      default:
        return;
    }

    if (dW.abs() < 0.01 && dH.abs() < 0.01) return;

    final sxLocal = (multiplierX * dW) / 2;
    final syLocal = (multiplierY * dH) / 2;

    p.x = (p.x + (sxLocal * cosA - syLocal * sinA) / p.constraints.maxWidth).clamp(0.0, 1.0);
    p.y = (p.y + (sxLocal * sinA + syLocal * cosA) / p.constraints.maxHeight).clamp(0.0, 1.0);
  }

  @action
  void handleDrag(DragUpdateDetails details) {
    if (properties.isEditing) return;

    final newX = (properties.x + details.delta.dx / properties.constraints.maxWidth).clamp(0.0, 1.0);
    final newY = (properties.y + details.delta.dy / properties.constraints.maxHeight).clamp(0.0, 1.0);

    updatePosition(newX, newY);
    // onPositionUpdate(properties.type, newX, newY);
  }

  @action
  void handleSelect() {
    // onSelect(properties.type);
  }

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}
