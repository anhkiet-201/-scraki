import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/constants/ui_constants.dart';
import 'package:scraki/core/mixins/session_manager_store_mixin.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';

part 'floating_phone_view_store.g.dart';

// ignore: library_private_types_in_public_api
class FloatingPhoneViewStore = _FloatingPhoneViewStore
    with _$FloatingPhoneViewStore;

/// Store chịu trách nhiệm quản lý trạng thái UI của FloatingPhoneView.
///
/// Chức năng chính:
/// - Quản lý vị trí cửa sổ (kéo thả)
/// - Quản lý kích thước cửa sổ (thay đổi kích thước)
/// - Quản lý trạng thái luồng tạo Poster
abstract class _FloatingPhoneViewStore with Store, SessionManagerStoreMixin {
  final Size parentSize;
  final String serial;

  _FloatingPhoneViewStore(this.parentSize, this.serial) {
    _initializeStore();
  }

  ReactionDisposer? _aspectRatioDisposer;
  double _lastKnownRatio = UIConstants.defaultDeviceAspectRatio;

  void _initializeStore() {
    // Khởi tạo vị trí và kích thước dựa trên tỷ lệ khung hình thực tế của thiết bị này
    final aspectRatio =
        sessionManagerStore.deviceAspectRatios[serial] ??
        UIConstants.defaultDeviceAspectRatio;
    _lastKnownRatio = aspectRatio;

    final isLandscape = aspectRatio > 1.0;
    final initialWidth = isLandscape ? 560.0 : 320.0;
    final initialHeight = (initialWidth / aspectRatio) +
        40 +  
        UIConstants.floatingNavigationBarHeight +
        12;
    initializePositionAndSize(const Offset(100, 100), initialWidth, initialHeight);

    // Phản ứng với thay đổi tỷ lệ khung hình khi thiết bị xoay màn hình
    _aspectRatioDisposer ??= reaction(
      (_) =>
          sessionManagerStore.deviceAspectRatios[serial] ??
          UIConstants.defaultDeviceAspectRatio,
      (ratio) {
        syncWithAspectRatio(ratio);
      },
    );
  }

  @action
  void syncWithAspectRatio(double ratio) {
    if ((_lastKnownRatio - ratio).abs() > 0.01) {
      _lastKnownRatio = ratio;
      final isLandscape = ratio > 1.0;
      final targetWidth = isLandscape
          ? (width < 450 ? 560.0 : width)
          : (width > 450 ? 320.0 : width);
      final newHeight = (targetWidth / ratio) +
          40 +
          UIConstants.floatingNavigationBarHeight +
          12;
      width = targetWidth;
      height = newHeight;
      position = getClampedPosition(position, parentSize);
    }
  }

  void dispose() {
    _aspectRatioDisposer?.call();
    _aspectRatioDisposer = null;
  }

  // ═══════════════════════════════════════════════════════════════
  // WINDOW STATE
  // ═══════════════════════════════════════════════════════════════

  @observable
  Offset position = const Offset(100, 100);

  @observable
  double width = 320;

  @observable
  double height = 600;

  // ═══════════════════════════════════════════════════════════════
  // POSTER WORKFLOW STATE
  // ═══════════════════════════════════════════════════════════════

  @observable
  bool isGeneratingPoster = false;

  @observable
  PosterData? selectedPosterData;

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS - WINDOW MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  @action
  void updatePosition(Offset newPosition) {
    position = newPosition;
  }

  @action
  void updateDimensions(double newWidth, double newHeight) {
    width = newWidth;
    height = newHeight;
  }

  @action
  void initializePositionAndSize(
    Offset initialPosition,
    double initialWidth,
    double initialHeight,
  ) {
    position = initialPosition;
    width = initialWidth;
    height = initialHeight;
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS - POSTER WORKFLOW
  // ═══════════════════════════════════════════════════════════════

  @action
  void setGeneratingPoster(bool generating) {
    isGeneratingPoster = generating;
  }

  @action
  void setSelectedPosterData(PosterData? data) {
    selectedPosterData = data;
  }

  @observable
  String? errorMessage;

  @action
  void setErrorMessage(String? message) {
    errorMessage = message;
  }

  @observable
  PosterData? lastSelectedJob;

  @action
  void setLastSelectedJob(PosterData? job) {
    lastSelectedJob = job;
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Giới hạn vị trí để cửa sổ nằm trong phạm vi màn hình cha, có tính đến ToolBox
  Offset getClampedPosition(Offset target, Size parentSize) {
    if (parentSize.isEmpty) return target;

    const toolBoxMaxWidth = 100 + 12 + 12; // expanded width + margins
    final totalWidth = width + toolBoxMaxWidth;

    final maxX = parentSize.width - totalWidth;
    final maxY = parentSize.height - height;

    return Offset(
      target.dx.clamp(0.0, maxX > 0 ? maxX : 0.0),
      target.dy.clamp(0.0, maxY > 0 ? maxY : 0.0),
    );
  }

  /// Tính toán không gian hiển thị khả dụng cho ToolBox
  double getToolBoxAvailableSpace(Size parentSize) {
    if (parentSize.isEmpty) return 0;

    final floatingWindowRight = position.dx + width + 12; // + margin
    return parentSize.width - floatingWindowRight;
  }
}
