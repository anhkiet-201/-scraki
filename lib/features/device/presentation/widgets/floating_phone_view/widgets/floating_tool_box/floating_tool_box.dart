import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/store/floating_tool_box_store.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/caption_panel.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/job_selector_panel.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/poster_panel.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/text_scale_slider.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/tool_box_menu.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/poster/presentation/store/poster_customization_store.dart';

/// Floating Tool Box widget với thiết kế Glassmorphism.
///
/// Cung cấp các công cụ nhanh:
/// - Power: Bật/tắt màn hình
/// - Poster: Tạo ảnh tuyển dụng (AI Job Poster)
///
/// Tự động thu gọn khi không gian hẹp.
class FloatingToolBox extends StatefulWidget {
  final String serial;
  final double height;
  final double availableSpace;
  final void Function(PosterData) onJobSelected;
  final PosterData? posterData;
  final bool isGenerating;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const FloatingToolBox({
    super.key,
    required this.serial,
    required this.height,
    required this.availableSpace,
    required this.onJobSelected,
    this.posterData,
    this.isGenerating = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<FloatingToolBox> createState() => FloatingToolBoxState();
}

class FloatingToolBoxState extends State<FloatingToolBox> {
  late final FloatingToolBoxStore _store;
  late final PosterCustomizationStore _customizationStore;
  final GlobalKey _posterKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _store = FloatingToolBoxStore();
    _customizationStore = PosterCustomizationStore();
  }

  /// Chụp ảnh widget poster thành file ảnh PNG.
  Future<File?> capturePoster() async {
    // Clear selection so no borders are captured
    _customizationStore.selectField(null);

    // Wait for frame to repaint to remove highlights
    await Future<void>.delayed(const Duration(milliseconds: 100));

    try {
      final boundary =
          _posterKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null) return null;

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/poster_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      debugPrint('Error capturing poster: $e');
      return null;
    }
  }

  bool get _isCollapsed => widget.availableSpace < 100;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        return Row(
          children: [
            ToolBoxMenu(
              isCollapsed: _isCollapsed,
              height: widget.height,
              onPowerTap: () => _store.sendPowerButton(widget.serial),
              onPosterTap: () => _store.toggleJobSelector(),
            ),
            if (_store.showJobSelector)
              JobSelectorPanel(
                height: widget.height,
                onJobSelected: (job) {
                  _store.hideJobSelector();
                  widget.onJobSelected(job);
                },
                onCancel: () {
                  _store.hideJobSelector();
                },
              )
            else if (widget.isGenerating || widget.posterData != null) ...[
              PosterPanel(
                height: widget.height,
                isGenerating: widget.isGenerating,
                posterData: widget.posterData,
                customizationStore: _customizationStore,
                posterKey: _posterKey,
                errorMessage: widget.errorMessage,
                onRetry: widget.onRetry,
              ),
              Column(
                children: [
                  CaptionPanel(
                    caption: widget.posterData?.tikTokCaption,
                    availableSpace: widget.availableSpace,
                    height: widget.height,
                  ),
                  TextScaleSlider(
                    posterData: widget.posterData,
                    customizationStore: _customizationStore,
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
