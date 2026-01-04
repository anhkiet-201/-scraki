import 'dart:ui';
import 'package:flutter/material.dart';
import '../store/floating_tool_box_store.dart';

/// Floating Tool Box widget với glassmorphism design
///
/// Simplified version - chỉ có Power button
class FloatingToolBox extends StatefulWidget {
  final String serial;
  final double height;
  final double availableSpace;

  const FloatingToolBox({
    super.key,
    required this.serial,
    required this.height,
    required this.availableSpace,
  });

  @override
  State<FloatingToolBox> createState() => _FloatingToolBoxState();
}

class _FloatingToolBoxState extends State<FloatingToolBox> {
  late final FloatingToolBoxStore _store;

  @override
  void initState() {
    super.initState();
    _store = FloatingToolBoxStore();
  }

  bool get _isCollapsed => widget.availableSpace < 100;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: _isCollapsed ? 56 : 100,
      height: widget.height,
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.7),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: _isCollapsed
                  ? _buildIconButton(colorScheme)
                  : _buildExpandedButton(colorScheme),
            ),
          ),
        ),
      ),
    );
  }

  /// Icon button cho collapsed mode
  Widget _buildIconButton(ColorScheme colorScheme) {
    return Tooltip(
      message: 'Power',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _store.sendPowerButton(widget.serial),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.power_settings_new_rounded,
              color: colorScheme.error,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  /// Full button cho expanded mode
  Widget _buildExpandedButton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _store.sendPowerButton(widget.serial),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.error.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.power_settings_new_rounded,
                  color: colorScheme.error,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  'Power',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
