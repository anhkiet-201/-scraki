import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/constants/ui_constants.dart';
import '../store/phone_view_store.dart';

/// Overlay shown when files are being dragged over the phone view.
///
/// Matches the app's professional aesthetic with a clean dashed-border drop zone.
/// Refined to be brighter and more integrated with the Material 3 theme.
class DragOverlayView extends StatelessWidget {
  final PhoneViewStore store;
  const DragOverlayView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: Observer(
        builder: (_) {
          final isApk = store.isDraggingApk;
          final primaryColor = theme.colorScheme.primary;

          return ClipRRect(
            borderRadius: BorderRadius.circular(UIConstants.componentBorderRadius),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              builder: (context, opacity, child) {
                return Opacity(
                  opacity: opacity,
                  child: Stack(
                    children: [
                      // Semi-transparent Surface Background
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      
                      // Dashed Border Drop Zone
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: CustomPaint(
                            painter: DashedBorderPainter(
                              color: primaryColor.withValues(alpha: 0.6),
                              strokeWidth: 2,
                              gap: 8,
                              borderRadius: 16,
                            ),
                          ),
                        ),
                      ),

                      // Content
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon Container
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isApk 
                                    ? Icons.install_mobile_rounded 
                                    : Icons.upload_file_rounded,
                                color: primaryColor,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Title
                            Text(
                              isApk ? 'INSTALL APK' : 'PUSH FILES',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Subtitle pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                isApk
                                    ? 'Drop to install on device'
                                    : 'Files will be sent to /sdcard/Download',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// A painter that draws a dashed rounded rectangle border.
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.gap = 5.0,
    this.borderRadius = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = Path();
    double distance = 0.0;

    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
           oldDelegate.gap != gap ||
           oldDelegate.borderRadius != borderRadius;
  }
}
