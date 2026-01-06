import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/mixins/session_manager_store_mixin.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';

part 'floating_phone_view_store.g.dart';

// ignore: library_private_types_in_public_api
class FloatingPhoneViewStore = _FloatingPhoneViewStore
    with _$FloatingPhoneViewStore;

/// Store responsible for managing FloatingPhoneView UI state.
///
/// Handles:
/// - Window position (dragging)
/// - Window size (resizing)
/// - Poster workflow state
abstract class _FloatingPhoneViewStore with Store, SessionManagerStoreMixin {
  final Size parentSize;

  _FloatingPhoneViewStore(this.parentSize) {
    _initializeStore();
  }

  ReactionDisposer? _aspectRatioDisposer;

  void _initializeStore() {
    // Initialize position and dimensions based on aspect ratio
    final aspectRatio = sessionManagerStore.deviceAspectRatio;
    final initialHeight = (320 / aspectRatio) + 40 + 12;
    initializePositionAndSize(const Offset(100, 100), 320, initialHeight);

    // React to aspect ratio changes (e.g. when session starts)
    _aspectRatioDisposer ??= reaction(
      (_) => sessionManagerStore.deviceAspectRatio,
      (ratio) {
        runInAction(() {
          final newHeight = (width / ratio) + 40 + 12;
          updateDimensions(width, newHeight);
          updatePosition(getClampedPosition(position, parentSize));
        });
      },
    );
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

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Clamp position to stay within parent bounds accounting for ToolBox
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

  /// Calculate available space for Tool Box
  double getToolBoxAvailableSpace(Size parentSize) {
    if (parentSize.isEmpty) return 0;

    final floatingWindowRight = position.dx + width + 12; // + margin
    return parentSize.width - floatingWindowRight;
  }
}
