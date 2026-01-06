import 'package:flutter/material.dart';
import 'package:scraki/core/widgets/gemini_poster_skeleton.dart';

class FloatingLoadingOverlay extends StatelessWidget {
  final bool isVisible;

  const FloatingLoadingOverlay({super.key, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: Container(
        color: Colors.white, // Opaque background for skeleton
        child: Column(
          children: [
            // Status Bar Mimic
            const SizedBox(height: 40),

            // Status Text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI đang phân tích & thiết kế...',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Skeleton Content
            const Expanded(child: GeminiSkeletonLayout()),
          ],
        ),
      ),
    );
  }
}
