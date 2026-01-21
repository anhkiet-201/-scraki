import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';

class AntiReupSettingsPanel extends StatelessWidget {
  final VideoPosterStore store;

  const AntiReupSettingsPanel({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final config = store.antiReupConfig;
        final isRandom = config.isRandomized;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Status Indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isRandom
                          ? Colors.greenAccent.withOpacity(0.1)
                          : Colors.orangeAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRandom ? Icons.security : Icons.tune,
                      color: isRandom
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "CÔNG NGHỆ CHỐNG REUP",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isRandom
                              ? "Đang bảo vệ tự động"
                              : "Cấu hình thủ công",
                          style: TextStyle(
                            color: isRandom
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Mode Selection Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  value: isRandom,
                  onChanged: (val) => store.toggleRandomizeAntiReup(val),
                  activeColor: Colors.greenAccent,
                  activeTrackColor: Colors.greenAccent.withOpacity(0.2),
                  title: const Text(
                    "Ngẫu nhiên hoá (AI Auto)",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      isRandom
                          ? "Hệ thống tự động biến đổi thông số video để tạo chuỗi mã hoá duy nhất."
                          : "Tự điều chỉnh các thông số kỹ thuật.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),

              // Manual Controls Section
              if (!isRandom) ...[
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Text(
                      "THÔNG SỐ KỸ THUẬT",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(child: Divider(color: Colors.white10)),
                  ],
                ),
                const SizedBox(height: 16),

                // Speed
                _buildControlItem(
                  icon: Icons.speed,
                  label: "Tốc độ (Speed)",
                  value: config.speedMultiplier,
                  min: 1.0,
                  max: 1.15,
                  displayValue:
                      "+${((config.speedMultiplier - 1.0) * 100).toStringAsFixed(1)}%",
                  onChanged: (val) => store.updateAntiReupConfig(
                    config.copyWith(speedMultiplier: val),
                  ),
                ),
                const SizedBox(height: 16),

                // Noise
                _buildControlItem(
                  icon: Icons.grain,
                  label: "Nhiễu hạt (Noise)",
                  value: config.noiseLevel,
                  min: 0.0,
                  max: 0.2,
                  displayValue:
                      "${(config.noiseLevel * 100).toStringAsFixed(0)}%",
                  onChanged: (val) => store.updateAntiReupConfig(
                    config.copyWith(noiseLevel: val),
                  ),
                ),
                const SizedBox(height: 16),

                // Color
                _buildControlItem(
                  icon: Icons.color_lens_outlined,
                  label: "Đổi màu (Color)",
                  value: config.colorShiftIntensity,
                  min: 0.0,
                  max: 0.2,
                  displayValue:
                      "${(config.colorShiftIntensity * 100).toStringAsFixed(0)}%",
                  onChanged: (val) => store.updateAntiReupConfig(
                    config.copyWith(colorShiftIntensity: val),
                  ),
                ),
                const SizedBox(height: 24),

                // Pitch Shift Toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: CheckboxListTile(
                    value: config.enableAudioPitchShift,
                    onChanged: (val) => store.updateAntiReupConfig(
                      config.copyWith(enableAudioPitchShift: val ?? false),
                    ),
                    title: const Text(
                      "Đổi tông giọng (Smart Pitch)",
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    activeColor: Colors.greenAccent,
                    checkColor: Colors.black,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlItem({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required void Function(double) onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.white54),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                displayValue,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 24,
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.greenAccent,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
