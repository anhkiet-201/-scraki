import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/floating_tool_box_card.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/poster/presentation/store/poster_customization_store.dart';

class TextScaleSlider extends StatelessWidget {
  final PosterData? posterData;
  final PosterCustomizationStore customizationStore;

  const TextScaleSlider({
    super.key,
    required this.posterData,
    required this.customizationStore,
  });

  @override
  Widget build(BuildContext context) {
    if (posterData == null) return const SizedBox();

    return Observer(
      builder: (context) {
        if (customizationStore.selectedFieldId == null) {
          return const SizedBox();
        }

        final currentScale = customizationStore.getScale(
          customizationStore.selectedFieldId!,
        );

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: FloatingToolBoxCard(
            width: 350,
            margin: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.format_size_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getFriendlyName(customizationStore.selectedFieldId!),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Tooltip(
                        message: 'Đặt lại',
                        child: InkWell(
                          onTap: () => customizationStore.updateScale(1.0),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.refresh_rounded,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Slider Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.remove_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          final newScale = (currentScale - 0.1).clamp(0.5, 3.0);
                          customizationStore.updateScale(newScale);
                        },
                        tooltip: 'Giảm cỡ chữ',
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: colorScheme.primary,
                            inactiveTrackColor:
                                colorScheme.surfaceContainerHighest,
                            thumbColor: colorScheme.primary,
                            overlayColor: colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                              elevation: 2,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                          ),
                          child: Slider(
                            value: currentScale,
                            min: 0.5,
                            max: 3.0,
                            divisions: 25,
                            label: '${(currentScale * 100).toInt()}%',
                            onChanged: (value) {
                              customizationStore.updateScale(value);
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          final newScale = (currentScale + 0.1).clamp(0.5, 3.0);
                          customizationStore.updateScale(newScale);
                        },
                        tooltip: 'Tăng cỡ chữ',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFriendlyName(String id) {
    if (id == 'jobTitle') return 'Chức danh';
    if (id == 'companyName') return 'Tên công ty';
    if (id == 'headline') return 'Tiêu đề chính';
    if (id == 'salary') return 'Mức lương';
    if (id == 'location') return 'Địa điểm';
    if (id == 'locationShort') return 'Địa điểm (Ngắn)';
    if (id == 'contactInfo') return 'Liên hệ';
    if (id.startsWith('req_')) {
      final index = int.tryParse(id.split('_').last) ?? 0;
      return 'Yêu cầu ${index + 1}';
    }
    if (id.startsWith('ben_')) {
      final index = int.tryParse(id.split('_').last) ?? 0;
      return 'Quyền lợi ${index + 1}';
    }
    return id; // Fallback
  }
}
