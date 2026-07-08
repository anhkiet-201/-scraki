import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';
import 'package:scraki/features/video_poster/presentation/widgets/preview/video_overlay_item/video_overlay_item.dart';
import 'package:scraki/features/video_poster/presentation/widgets/preview/image_overlay_item/image_overlay_item.dart';
import 'image_drop_zone.dart';

class PlaygroundInteractivePreview extends StatelessWidget {
  final VideoPosterStore store;

  const PlaygroundInteractivePreview({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return ImageDropZone(
      store: store,
      child: Container(
        color: const Color(0xFFF1F5F9),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Observer(
            builder: (context) {
              final is4x5Ratio = store.is4x5Ratio;
              return AspectRatio(
                aspectRatio: is4x5Ratio ? 4 / 5 : 9 / 16,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        Observer(
                          builder: (context) {
                            if (store.sourceVideoPaths.isEmpty) {
                              return Container(
                                color: Colors.white,
                                child: const Center(
                                  child: Text(
                                    'No Video Selected',
                                    style: TextStyle(color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              );
                            }
                            return Video(
                              controller: store.videoController,
                              fit: BoxFit.cover,
                              controls: (state) => const SizedBox.shrink(),
                            );
                          },
                        ),
                        Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            clipBehavior: Clip.none,
                            child: SizedBox(
                              width: 720,
                              height: is4x5Ratio ? 900 : 1280,
                              child: RepaintBoundary(
                                key: store.previewKey,
                                child: Observer(
                                  builder: (context) {
                                    final virtualConstraints = BoxConstraints(
                                      maxWidth: 720,
                                      maxHeight: is4x5Ratio ? 900 : 1280,
                                    );
              
                                    return GestureDetector(
                                      onTap: () {
                                        store.selectCustomText(null);
                                        store.selectCustomImage(null);
                                      },
                                      behavior: HitTestBehavior.translucent,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Positioned.fill(
                                            child: DragTarget<Map<String, dynamic>>(
                                              onAcceptWithDetails: (details) {
                                                final renderBox = store.previewKey.currentContext?.findRenderObject() as RenderBox?;
                                                if (renderBox != null) {
                                                  final localOffset = renderBox.globalToLocal(details.offset);
                                                  final adjustedX = (localOffset.dx + 50) / renderBox.size.width;
                                                  final adjustedY = (localOffset.dy + 50) / renderBox.size.height;
              
                                                  store.addCustomImage(
                                                    details.data['url'] as String,
                                                    adjustedX.clamp(0.0, 1.0),
                                                    adjustedY.clamp(0.0, 1.0),
                                                    isGif: details.data['isGif'] as bool,
                                                  );
                                                }
                                              },
                                              builder: (context, candidateData, rejectedData) => Container(
                                                color: candidateData.isNotEmpty
                                                    ? Colors.white.withValues(alpha: 0.1)
                                                    : Colors.transparent,
                                              ),
                                            ),
                                          ),
                                          if (!store.isHidingImagesForCapture)
                                            ...store.customImages.where((image) {
                                              if (!store.isPreviewMode) return true;
                                              final pos = store.position.inMilliseconds / 1000.0;
                                              return pos >= image.startTime && (image.endTime == null || pos <= image.endTime!);
                                            }).map((image) => ImageOverlayItem(
                                              key: ValueKey(image.id),
                                              id: image.id,
                                              imageUrl: image.imageUrl,
                                              isGif: image.isGif,
                                              x: image.x,
                                              y: image.y,
                                              width: image.width,
                                              height: image.height,
                                              rotation: image.rotation,
                                              constraints: virtualConstraints,
                                              isSelected: store.selectedCustomImageId == image.id,
                                              onPositionUpdate: store.updateCustomImagePosition,
                                              onSelect: store.selectCustomImage,
                                              onResize: store.updateCustomImageSize,
                                              borderColor: image.borderColor,
                                              borderWidth: image.borderWidth,
                                              borderRadius: image.borderRadius,
                                            )),
                                          ...store.customTexts.where((text) {
                                            if (!store.isPreviewMode) return true;
                                            final pos = store.position.inMilliseconds / 1000.0;
                                            return pos >= text.startTime && (text.endTime == null || pos <= text.endTime!);
                                          }).map((text) => Observer(
                                            key: ValueKey('text_wrapper_${text.id}'),
                                            builder: (context) {
                                              final shouldHide = store.isHidingAnimatedTextsForCapture && text.isAnimated;
                                              return VideoOverlayItem(
                                                key: ValueKey(text.id),
                                                label: text.label,
                                                x: text.x,
                                                y: text.y,
                                                type: text.id,
                                                constraints: virtualConstraints,
                                                color: text.color,
                                                fontSize: text.fontSize,
                                                textHeight: text.textHeight,
                                                fontWeight: text.fontWeight,
                                                fontStyle: text.fontStyle,
                                                textAlign: text.textAlign,
                                                backgroundColor: text.backgroundColor,
                                                backgroundOpacity: text.backgroundOpacity,
                                                backgroundRadius: text.backgroundRadius,
                                                backgroundStyle: text.backgroundStyle,
                                                backgroundBorderColor: text.backgroundBorderColor,
                                                backgroundBorderWidth: text.backgroundBorderWidth,
                                                fontFamily: text.fontFamily,
                                                rotation: text.rotation,
                                                strokeColor: text.strokeColor,
                                                strokeWidth: text.strokeWidth,
                                                letterSpacing: text.letterSpacing,
                                                isSelected: store.selectedCustomTextId == text.id,
                                                opacity: shouldHide ? 0.0 : 1.0,
                                                captureKey: text.isAnimated ? store.getTextCaptureKey(text.id) : null,
                                                onPositionUpdate: (_, x, y) => store.updateCustomTextPosition(text.id, x, y),
                                                onSelect: (_) => store.selectCustomText(text.id),
                                                onResize: (_, size) => store.updateCustomTextFontSize(text.id, size),
                                                onTextChange: (_, val) => store.updateCustomTextLabel(text.id, val),
                                                animationInType: text.animationInType,
                                                animationInDuration: text.animationInDuration,
                                                animationOutType: text.animationOutType,
                                                animationOutDuration: text.animationOutDuration,
                                                isPreviewMode: store.isPreviewMode,
                                                currentTime: store.position.inMilliseconds / 1000.0,
                                                startTime: text.startTime,
                                                endTime: text.endTime ?? (store.duration.inMilliseconds.toDouble()) / 1000.0,
                                                triggerPreviewCounter: store.animationPreviewCounters[text.id] ?? 0,
                                                triggerOutPreviewCounter: store.animationOutPreviewCounters[text.id] ?? 0,
                                                brushIntensity: text.brushIntensity,
                                                brushThickness: text.brushThickness,
                                                brushComplexity: text.brushComplexity,
                                                backgroundPadding: text.backgroundPadding,
                                                styleParams: text.styleParams,
                                              );
                                            },
                                          )),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            }
          ),
        ),
      ),
    );
  }
}
