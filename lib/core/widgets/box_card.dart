import 'dart:ui';
import 'package:flutter/material.dart';

class BoxCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const BoxCard({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // Shadow mờ hơn và rộng hơn để tạo chiều sâu
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
          // Subtle glow của primary color
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          // Tăng độ nhòe lên 16/16 để hiệu ứng kính rõ rệt hơn
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              // Màu nền kính với độ trong suốt tinh tế
              color: colorScheme.surface.withValues(alpha: 0.65),
              // Viền kính (Glass border) với gradient nhẹ
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
