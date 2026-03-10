// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'image_overlay_item_store.g.dart';

class ImageOverlayItemStore = _ImageOverlayItemStore
    with _$ImageOverlayItemStore;

abstract class _ImageOverlayItemStore with Store {
  _ImageOverlayItemStore({
    required this.id,
    required double initialX,
    required double initialY,
    required this.constraints,
    required double initialWidth,
    required double initialHeight,
    required this.onPositionUpdate,
    required this.onSelect,
    required this.onResize,
  }) {
    x = initialX;
    y = initialY;
    width = initialWidth;
    height = initialHeight;
  }

  // Properties
  final String id;
  final BoxConstraints constraints;
  final void Function(String id, double x, double y) onPositionUpdate;
  final void Function(String id) onSelect;
  final void Function(String id, double newWidth, double newHeight) onResize;

  final GlobalKey contentKey = GlobalKey();

  // Observable state
  @observable
  double x = 0.0;

  @observable
  double y = 0.0;

  @observable
  double width = 200.0;

  @observable
  double height = 200.0;

  @observable
  bool isSelected = false;

  @observable
  bool isHovered = false;

  @observable
  bool isInteracting = false;

  // Actions
  @action
  void updatePosition(double newX, double newY) {
    x = newX;
    y = newY;
  }

  @action
  void updateSize(double newWidth, double newHeight) {
    width = newWidth;
    height = newHeight;
  }

  @action
  void setSelected(bool value) {
    isSelected = value;
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
  void handleResize({
    required DragUpdateDetails details,
    required double multiplierX, // -1: left, 1: right, 0: mid
    required double multiplierY, // -1: top, 1: bottom, 0: mid
  }) {
    // Resize by directly modifying width/height constraints based on pan delta
    final dx = details.delta.dx;
    final dy = details.delta.dy;

    // Scale proportionally if dragged from a corner
    bool proportional = multiplierX != 0 && multiplierY != 0;

    double newWidth = width;
    double newHeight = height;

    if (multiplierX != 0) {
      newWidth = width + (multiplierX * dx);
      if (proportional) {
        // maintain ratio
        newHeight = newWidth * (height / width);
      }
    }
    if (multiplierY != 0 && !proportional) {
      newHeight = height + (multiplierY * dy);
    }

    newWidth = newWidth.clamp(20.0, 1000.0);
    newHeight = newHeight.clamp(20.0, 1000.0);

    // Calc diff to maintain anchor
    final dW = newWidth - width;
    final dH = newHeight - height;

    if (dW.abs() < 0.1 && dH.abs() < 0.1) return;

    updateSize(newWidth, newHeight);
    onResize(id, newWidth, newHeight);

    // Shift X/Y based on the anchor that resized
    final newX = (x + (multiplierX * dW / 2) / constraints.maxWidth).clamp(
      0.0,
      1.0,
    );
    final newY = (y + (multiplierY * dH / 2) / constraints.maxHeight).clamp(
      0.0,
      1.0,
    );

    updatePosition(newX, newY);
    onPositionUpdate(id, newX, newY);
  }

  @action
  void handleDrag(DragUpdateDetails details) {
    final newX = (x + details.delta.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final newY = (y + details.delta.dy / constraints.maxHeight).clamp(0.0, 1.0);

    updatePosition(newX, newY);
    onPositionUpdate(id, newX, newY);
  }

  @action
  void handleSelect() {
    onSelect(id);
  }
}
