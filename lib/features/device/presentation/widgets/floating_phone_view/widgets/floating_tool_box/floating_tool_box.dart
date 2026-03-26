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
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/email_panel.dart';
import 'package:scraki/features/auth/presentation/widgets/auth_panel.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/poster/presentation/stores/poster_customization_store.dart';

/// Floating Tool Box widget với thiết kế Glassmorphism.
class FloatingToolBox extends StatefulWidget {
  final String serial;
  final double height;
  final FloatingToolBoxStore store;
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
    required this.store,
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
  late final PosterCustomizationStore _customizationStore;
  final GlobalKey _posterKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _customizationStore = PosterCustomizationStore();
  }

  Future<File?> capturePoster() async {
    _customizationStore.selectField(null);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    try {
      final boundary = _posterKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();
      if (pngBytes == null) return null;
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/poster_${DateTime.now().millisecondsSinceEpoch}.png');
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ToolBoxMenu(
              isCollapsed: _isCollapsed,
              height: widget.height,
              onPowerTap: () => widget.store.sendPowerButton(widget.serial),
              onPosterTap: () => widget.store.toggleJobSelector(),
              onEmailTap: () => widget.store.toggleEmailPanel(),
              onInboxTap: () => widget.store.openTikTokInbox(widget.serial),
              onProfileTap: () => widget.store.openTikTokProfile(widget.serial),
              onAuthTap: () => widget.store.toggleAuthPanel(),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey(widget.store.showJobSelector || 
                              widget.store.showEmailPanel || 
                              widget.store.showAuthPanel || 
                              widget.posterData != null || 
                              widget.isGenerating),
                alignment: Alignment.topLeft,
                child: _buildPanel(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPanel() {
    if (widget.store.showJobSelector) {
      return JobSelectorPanel(
        key: const ValueKey('job_selector'),
        height: widget.height,
        onJobSelected: (job) {
          widget.store.hideJobSelector();
          widget.onJobSelected(job);
        },
        onCancel: () {
          widget.store.hideJobSelector();
        },
      );
    } else if (widget.store.showEmailPanel) {
      return EmailPanel(
        key: const ValueKey('email_panel'),
        height: widget.height,
        deviceSerial: widget.serial,
        onCancel: () {
          widget.store.hideEmailPanel();
        },
      );
    } else if (widget.store.showAuthPanel) {
      return AuthPanel(
        key: const ValueKey('auth_panel'),
        serial: widget.serial,
      );
    } else if (widget.isGenerating || widget.posterData != null) {
      return Row(
        key: const ValueKey('poster_panel_group'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            mainAxisSize: MainAxisSize.min,
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
      );
    }
    return const SizedBox.shrink(key: ValueKey('empty_panel'));
  }
}
