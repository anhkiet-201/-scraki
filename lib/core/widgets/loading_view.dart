import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:scraki/core/widgets/mesh_background.dart';

class LoadingView extends StatefulWidget {
  final String? message;
  final bool showBackground;

  const LoadingView({
    super.key,
    this.message,
    this.showBackground = true,
  });

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    Widget content = Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _pulseController, _shimmerController]),
        builder: (context, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shimmering Glass Card
              _buildShimmeringGlassCard(isLight, colorScheme, theme),
            ],
          );
        },
      ),
    );

    if (widget.showBackground) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: MeshBackground(
          child: Opacity(
            opacity: 0.8, // Make background slightly more subtle
            child: content,
          ),
        ),
      );
    }

    return content;
  }

  Widget _buildShimmeringGlassCard(bool isLight, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: isLight ? 0.75 : 0.45),
              borderRadius: BorderRadius.circular(32),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  transform: _SlidingGradientTransform(percent: _shimmerController.value),
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcATop,
              child: _buildInnerContent(colorScheme, theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInnerContent(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Premium Energy Flow Loader
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Energy Aura (Pulse)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(
                        alpha: 0.2 + (_pulseController.value * 0.15),
                      ),
                      blurRadius: 20 + (_pulseController.value * 20),
                      spreadRadius: 5 + (_pulseController.value * 10),
                    ),
                  ],
                ),
              ),
              // The Energy Arcs
              CustomPaint(
                size: const Size(100, 100),
                painter: EnergyFlowPainter(
                  rotation: _mainController.value,
                  primaryColor: colorScheme.primary,
                  tertiaryColor: colorScheme.tertiary,
                ),
              ),
              // Central Bolt Icon
              Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: Icon(
                  Icons.bolt_rounded,
                  size: 36,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 32),
          Text(
            widget.message!.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0),
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class EnergyFlowPainter extends CustomPainter {
  final double rotation;
  final Color primaryColor;
  final Color tertiaryColor;

  EnergyFlowPainter({
    required this.rotation,
    required this.primaryColor,
    required this.tertiaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Layer 1: Fast Thin Arc (Tertiary)
    _drawEnergyArc(
      canvas,
      center,
      radius,
      paint
        ..strokeWidth = 2
        ..color = tertiaryColor.withValues(alpha: 0.6),
      startAngle: rotation * 2 * math.pi * 2,
      sweepAngle: math.pi / 2,
    );

    // Layer 2: Slow Thick Arc (Primary)
    _drawEnergyArc(
      canvas,
      center,
      radius - 4,
      paint
        ..strokeWidth = 4
        ..color = primaryColor,
      startAngle: -rotation * 2 * math.pi,
      sweepAngle: math.pi * 0.7,
    );

    // Layer 3: Trailing Dots
    final dotPaint = Paint()..color = primaryColor.withValues(alpha: 0.4);
    for (int i = 0; i < 3; i++) {
      final angle = (rotation * 2 * math.pi) + (i * 0.2);
      final offset = Offset(
        center.dx + math.cos(angle) * (radius + 6),
        center.dy + math.sin(angle) * (radius + 6),
      );
      canvas.drawCircle(offset, 1.5, dotPaint);
    }
  }

  void _drawEnergyArc(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint, {
    required double startAngle,
    required double sweepAngle,
  }) {
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant EnergyFlowPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

class _SlidingGradientTransform extends GradientTransform {
  final double percent;
  const _SlidingGradientTransform({required this.percent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (percent * 2 - 1), 0, 0);
  }
}
