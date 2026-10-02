import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
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

  _FloatingPhoneViewStore(this.parentSize) {
    _initializeStore();
  }

  ReactionDisposer? _aspectRatioDisposer;

  void _initializeStore() {
    // Khởi tạo vị trí và kích thước dựa trên tỷ lệ khung hình
    final aspectRatio = sessionManagerStore.floatingAspectRatio;
    final safeRatio = aspectRatio > 0.1 ? aspectRatio : (9 / 16);
    double initialWidth = 320;
    double initialHeight = 600;
    const double chromeHeight = 104.0; // Header 48px + Nav bar 40px + Resize handle 16px
    const double chromeWidth = 4.0;    // Margins 4px

    if (safeRatio > 1.0) {
      final maxW = !parentSize.isEmpty && parentSize.width > 200
          ? (parentSize.width - 150).clamp(320.0, 800.0)
          : 800.0;
      const targetContentHeight = 360.0;
      initialWidth = ((targetContentHeight * safeRatio) + chromeWidth).clamp(480.0, maxW);
      initialHeight = ((initialWidth - chromeWidth) / safeRatio) + chromeHeight;
    } else {
      initialHeight = ((initialWidth - chromeWidth) / safeRatio) + chromeHeight;
    }
    initializePositionAndSize(const Offset(100, 100), initialWidth, initialHeight);

    // Phản ứng với thay đổi tỷ lệ khung hình (ví dụ: khi xoay màn hình hoặc bắt đầu session)
    _aspectRatioDisposer ??= reaction(
      (_) => sessionManagerStore.floatingAspectRatio,
      (ratio) {
        final safeRatio = ratio > 0.1 ? ratio : (9 / 16);
        runInAction(() {
          double newWidth;
          double newHeight;
          const double chromeH = 104.0; // Header 48px + Nav bar 40px + Resize handle 16px
          const double chromeW = 4.0;
          if (safeRatio > 1.0) {
            final maxW = !parentSize.isEmpty && parentSize.width > 200
                ? (parentSize.width - 150).clamp(320.0, 800.0)
                : 800.0;
            const targetContentHeight = 360.0;
            newWidth = ((targetContentHeight * safeRatio) + chromeW).clamp(480.0, maxW);
            newHeight = ((newWidth - chromeW) / safeRatio) + chromeH;
          } else {
            newWidth = 320.0;
            newHeight = ((newWidth - chromeW) / safeRatio) + chromeH;
          }
          updateDimensions(newWidth, newHeight);
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
