import 'package:flutter/material.dart';
import 'dart:ui';

/// Duration status overlay indicator
///
/// Shows video duration status at the top of preview:
/// - Optimal for TikTok (15-30s)
/// - Too short (auto-loop)
/// - Too long (auto-cut)
///
/// Features colored status indicator and glass morphism backdrop
class DurationStatusOverlay extends StatelessWidget {
  final Duration duration;
  final double playbackSpeed;

  const DurationStatusOverlay({
    super.key,
    required this.duration,
    required this.playbackSpeed,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDuration =
        duration.inSeconds / (playbackSpeed > 0 ? playbackSpeed : 1.0);

    String status = "Tối ưu TikTok: Sẵn sàng";
    Color color = Colors.greenAccent;

    if (effectiveDuration < 15) {
      status = "Thời lượng: Ngắn (Tự động lặp)";
      color = Colors.orangeAccent;
    } else if (effectiveDuration > 30) {
      status = "Thời lượng: Dài (Tự động cắt)";
      color = Colors.lightBlueAccent;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.black.withValues(alpha: 0.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
