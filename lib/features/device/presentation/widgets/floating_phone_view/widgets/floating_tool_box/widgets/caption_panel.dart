import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scraki/core/constants/ui_constants.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/floating_tool_box_card.dart';

class CaptionPanel extends StatelessWidget {
  final String? caption;
  final double availableSpace;
  final double height;

  const CaptionPanel({
    super.key,
    required this.caption,
    required this.availableSpace,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (caption == null) return const SizedBox();
    final theme = Theme.of(context);

    // Tính toán chiều rộng khả dụng: Tổng - (Action + Poster Generator)
    // Action: 100 (expanded) + padding margin
    // Poster Generator: height * defaultDeviceAspectRatio (Column chứa Selector + Preview)
    // Card padding/margin: ~32
    final usedWidth = 100.0 + (height * UIConstants.defaultDeviceAspectRatio) + 32;
    final remainingSpace = availableSpace - usedWidth;

    // Nếu không đủ chỗ hiển thị tối thiểu 150px thì ẩn
    if (remainingSpace < 150) return const SizedBox();

    return FloatingToolBoxCard(
      width: remainingSpace.clamp(150.0, 350.0), // Max 350px
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GỢI Ý CAPTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: caption!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã copy gợi ý đăng bài!'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectionArea(
                  child: Text(
                    caption!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
