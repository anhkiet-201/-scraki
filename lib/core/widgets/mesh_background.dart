import 'package:flutter/material.dart';

class MeshBackground extends StatelessWidget {
  final Widget child;

  const MeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        // Base background
        Positioned.fill(
          child: Container(color: colorScheme.surface),
        ),
        
        // Mesh Orbs with animations
        _MeshOrb(
          color: colorScheme.primary.withValues(alpha: 0.18),
          alignment: Alignment.topLeft,
          size: 650,
          durationSeconds: 15,
        ),
        _MeshOrb(
          color: colorScheme.tertiary.withValues(alpha: 0.15),
          alignment: Alignment.bottomRight,
          size: 750,
          durationSeconds: 20,
        ),
        _MeshOrb(
          color: colorScheme.secondary.withValues(alpha: 0.12),
          alignment: Alignment.centerRight,
          size: 550,
          durationSeconds: 12,
        ),
        
        Positioned.fill(child: child),
      ],
    );
  }
}

class _MeshOrb extends StatefulWidget {
  final Color color;
  final Alignment alignment;
  final double size;
  final int durationSeconds;

  const _MeshOrb({
    required this.color,
    required this.alignment,
    required this.size,
    required this.durationSeconds,
  });

  @override
  State<_MeshOrb> createState() => _MeshOrbState();
}

class _MeshOrbState extends State<_MeshOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    )..repeat(reverse: true);
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        final offset = (value - 0.5) * 60;
        final scale = 1.0 + (value - 0.5) * 0.15;

        return Align(
          alignment: widget.alignment,
          child: Transform.translate(
            offset: Offset(offset, -offset * 0.5),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.color,
                      widget.color.withValues(alpha: 0),
                    ],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
