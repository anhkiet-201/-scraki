import 'package:flutter/material.dart';

/// TikTok safe zone overlay visualization
///
/// Shows the areas where TikTok UI elements appear, helping users
/// position their content to avoid overlapping with buttons and captions.
///
/// Features:
/// - Bottom interaction zone (180px)
/// - Right side safe margin (60px)
/// - Semi-transparent gradient overlays
class TikTokSafeZone extends StatelessWidget {
  const TikTokSafeZone({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.symmetric(
              vertical: BorderSide(
                color: Colors.white.withValues(alpha: 0.02),
                width: 20,
              ),
              horizontal: BorderSide(
                color: Colors.white.withValues(alpha: 0.02),
                width: 80,
              ),
            ),
          ),
          child: Stack(
            children: [
              // Bottom interaction zone
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 180,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    "VÙNG TƯƠNG TÁC TIKTOK",
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white.withValues(alpha: 0.2),
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              // Right side safe margin
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
