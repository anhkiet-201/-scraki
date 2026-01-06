import 'package:flutter/material.dart';

class GeminiPosterSkeleton extends StatefulWidget {
  const GeminiPosterSkeleton({super.key});

  @override
  State<GeminiPosterSkeleton> createState() => _GeminiPosterSkeletonState();
}

class _GeminiPosterSkeletonState extends State<GeminiPosterSkeleton> {
  @override
  Widget build(BuildContext context) {
    return const GeminiSkeletonLayout();
  }
}

class GeminiShimmerEffect extends StatefulWidget {
  final Widget child;
  const GeminiShimmerEffect({super.key, required this.child});

  @override
  State<GeminiShimmerEffect> createState() => _GeminiShimmerEffectState();
}

class _GeminiShimmerEffectState extends State<GeminiShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: [
                Colors.grey[300]!,
                // Gemini-like shimmer burst
                const Color(0xFF8AB4F8), // Light Blue
                const Color(0xFFC58AF9), // Light Purple
                Colors.grey[300]!,
              ],
              stops: const [0.0, 0.45, 0.55, 1.0],
              transform: _SlidingGradientTransform(percent: _controller.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double percent;
  const _SlidingGradientTransform({required this.percent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Move the gradient from left to right
    return Matrix4.translationValues(bounds.width * (percent * 3 - 1), 0, 0);
  }
}

class GeminiSkeletonLayout extends StatelessWidget {
  const GeminiSkeletonLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return GeminiShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header Placeholder
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey, // Base color for mask
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 20),

            // Title Lines
            Container(height: 24, width: 200, color: Colors.grey),
            const SizedBox(height: 10),
            Container(height: 24, width: 150, color: Colors.grey),
            const SizedBox(height: 30),

            // Salary Badge - big pill
            Center(
              child: Container(
                height: 50,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Content Lines
            Container(height: 16, width: double.infinity, color: Colors.grey),
            const SizedBox(height: 8),
            Container(height: 16, width: double.infinity, color: Colors.grey),
            const SizedBox(height: 8),
            Container(height: 16, width: 250, color: Colors.grey),
            const SizedBox(height: 8),
            Container(height: 16, width: 280, color: Colors.grey),

            const Spacer(),

            // Footer
            Container(height: 60, width: double.infinity, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
