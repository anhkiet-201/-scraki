import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:scraki/core/widgets/mesh_background.dart';

class ConnectionLostView extends StatefulWidget {
  final VoidCallback? onReconnect;
  final bool isConnecting;
  final bool showBackground;

  const ConnectionLostView({
    super.key,
    this.onReconnect,
    this.isConnecting = false,
    this.showBackground = true,
  });

  @override
  State<ConnectionLostView> createState() => _ConnectionLostViewState();
}

class _ConnectionLostViewState extends State<ConnectionLostView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    Widget content = Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glass Card
              _buildErrorGlassCard(isLight, colorScheme, theme),
            ],
          );
        },
      ),
    );

    if (widget.showBackground) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: MeshBackground(
          child: Container(
            color: colorScheme.error.withValues(alpha: 0.05), // Subtle error tint
            child: content,
          ),
        ),
      );
    }

    return content;
  }

  Widget _buildErrorGlassCard(bool isLight, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colorScheme.error.withValues(alpha: 0.1),
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
              color: colorScheme.surface.withValues(alpha: isLight ? 0.8 : 0.45),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing Error Aura
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.error.withValues(
                              alpha: 0.15 + (_pulseController.value * 0.15),
                            ),
                            blurRadius: 20 + (_pulseController.value * 20),
                            spreadRadius: 5 + (_pulseController.value * 10),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.signal_wifi_off_rounded,
                      size: 48,
                      color: colorScheme.error,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Header
                Text(
                  'Connection Lost'.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The device connection was interrupted.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.onReconnect != null) ...[
                  const SizedBox(height: 40),
                  _buildReconnectButton(colorScheme, theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReconnectButton(ColorScheme colorScheme, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isConnecting
              ? [
                  colorScheme.surfaceContainerHighest,
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                ]
              : [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
        ),
        boxShadow: [
          if (!widget.isConnecting)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isConnecting ? null : widget.onReconnect,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isConnecting) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else ...[
                  const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.isConnecting ? 'RECONNECTING...' : 'RECONNECT NOW',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.2,
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
