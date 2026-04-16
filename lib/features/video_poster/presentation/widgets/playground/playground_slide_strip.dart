import 'dart:ui' show lerpDouble;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';

class PlaygroundSlideStrip extends StatelessWidget {
  final VideoPosterStore store;
  final ScrollController scrollController;

  const PlaygroundSlideStrip({
    super.key,
    required this.store,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        if (!store.isImagePosterMode || store.slides.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent && scrollController.hasClients) {
                      final newOffset = scrollController.offset + pointerSignal.scrollDelta.dy;
                      if (newOffset >= 0 && newOffset <= scrollController.position.maxScrollExtent) {
                        scrollController.jumpTo(newOffset);
                      }
                    }
                  },
                  child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    scrollController: scrollController,
                    buildDefaultDragHandles: false,
                    itemCount: store.slides.length,
                    onReorder: store.reorderSlides,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final double animValue = Curves.easeInOut.transform(animation.value);
                          final double scale = lerpDouble(1, 1.05, animValue)!;
                          return Transform.scale(
                            scale: scale,
                            child: Material(
                              color: Colors.transparent,
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final slide = store.slides[index];
                      final isActive = store.currentSlideIndex == index;

                      return ReorderableDragStartListener(
                        key: ValueKey(slide.id),
                        index: index,
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => store.selectSlide(index),
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive
                                      ? const Color(0xFF6366F1)
                                      : Colors.black.withValues(alpha: 0.05),
                                  width: isActive ? 2 : 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.copy_all_rounded,
                                          size: 20,
                                          color: isActive ? const Color(0xFF6366F1) : Colors.grey,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          slide.name,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isActive ? const Color(0xFF6366F1) : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (store.slides.length > 1)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () => store.removeSlide(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: 'Ngẫu nhiên nội dung',
                child: GestureDetector(
                  onTap: store.randomizePreviewFrame,
                  child: Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      ),
                    ),
                    child: const Icon(
                      Icons.shuffle_rounded,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: store.addSlide,
                child: Container(
                  width: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
