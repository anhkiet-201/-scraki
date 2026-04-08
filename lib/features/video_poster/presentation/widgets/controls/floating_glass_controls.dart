import 'package:flutter/material.dart';
import 'dart:ui';

/// Floating glass-morphism player controls overlay
///
/// Features:
/// - Play/pause button
/// - Seek slider
/// - Time display (position/duration)
/// - Mute/unmute button
/// - Glass morphism design with backdrop blur
class FloatingGlassControls extends StatelessWidget {
  final bool isPlaying;
  final bool isMuted;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final VoidCallback onToggleMute;
  final ValueChanged<Duration> onSeek;

  const FloatingGlassControls({
    super.key,
    required this.isPlaying,
    required this.isMuted,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onToggleMute,
    required this.onSeek,
  });

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return '00:00';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // ── Play/Pause ─────────────────────────────────────────
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                  onPressed: onPlayPause,
                ),
                const SizedBox(width: 4),
                // ── Thời gian hiện tại ─────────────────────────────────
                Text(
                  _formatDuration(position),
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // ── Slider seek ────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        activeTrackColor: const Color(0xFF6366F1),
                        inactiveTrackColor:
                            Colors.white.withValues(alpha: 0.2),
                        thumbColor: Colors.white,
                        overlayColor:
                            const Color(0xFF6366F1).withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: position.inMilliseconds
                            .toDouble()
                            .clamp(
                              0.0,
                              duration.inMilliseconds.toDouble(),
                            ),
                        max: duration.inMilliseconds.toDouble(),
                        onChanged: (v) =>
                            onSeek(Duration(milliseconds: v.toInt())),
                      ),
                    ),
                  ),
                ),
                // ── Tổng thời gian ─────────────────────────────────────
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                // ── Mute / Unmute ──────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: IconButton(
                    key: ValueKey(isMuted),
                    tooltip: isMuted ? 'Bật âm thanh' : 'Tắt tiếng',
                    icon: Icon(
                      isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: isMuted
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.white,
                      size: 22,
                    ),
                    onPressed: onToggleMute,
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
