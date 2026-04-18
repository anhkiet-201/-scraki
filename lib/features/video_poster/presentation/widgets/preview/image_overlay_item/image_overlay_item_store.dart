// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'dart:math' as math;

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
    double rotation = 0.0,
  }) {
    final angle = rotation * (math.pi / 180);
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    // 1. Chuyển delta từ Global (màn hình) về Local (không gian ảnh đã xoay)
    // dx_local = dx_g * cos + dy_g * sin
    // dy_local = -dx_g * sin + dy_g * cos
    final dxLocal = details.delta.dx * cosA + details.delta.dy * sinA;
    final dyLocal = -details.delta.dx * sinA + details.delta.dy * cosA;

    double newWidth = width;
    double newHeight = height;

    if (multiplierX != 0) {
      newWidth = width + multiplierX * dxLocal;
    }
    if (multiplierY != 0) {
      newHeight = height + multiplierY * dyLocal;
    }

    newWidth = newWidth.clamp(20.0, 1000.0);
    newHeight = newHeight.clamp(20.0, 1000.0);

    final dW = newWidth - width;
    final dH = newHeight - height;

    if (dW.abs() < 0.01 && dH.abs() < 0.01) return;

    // 2. Tính toán dịch chuyển tâm trong không gian Local
    final sxLocal = (multiplierX * dW) / 2;
    final syLocal = (multiplierY * dH) / 2;

    // 3. Xoay dịch chuyển tâm ngược lại Global để cập nhật x, y đúng vị trí trên màn hình
    // sx_g = sx_l * cos - sy_l * sin
    // sy_g = sx_l * sin + sy_l * cos
    final sxGlobal = sxLocal * cosA - syLocal * sinA;
    final syGlobal = sxLocal * sinA + syLocal * cosA;

    updateSize(newWidth, newHeight);
    onResize(id, newWidth, newHeight);

    final newX = (x + sxGlobal / constraints.maxWidth).clamp(0.0, 1.0);
    final newY = (y + syGlobal / constraints.maxHeight).clamp(0.0, 1.0);

    updatePosition(newX, newY);
    onPositionUpdate(id, newX, newY);
  }

  @action
  void handleDrag(DragUpdateDetails details, double rotation) {
    // Di chuyển toàn bộ vật thể: delta của chuột và (x, y) đều cùng không gian cha
    // Không cần xoay delta ở đây.
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
