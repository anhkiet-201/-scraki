import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/store/floating_tool_box_store.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_job_selector.dart';
import 'package:flutter/services.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box_card.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/core/widgets/gemini_poster_skeleton.dart';
import 'package:scraki/features/poster/presentation/widgets/modern_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/minimalist_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/bold_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/corporate_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/creative_poster.dart';
import 'package:scraki/features/poster/presentation/store/poster_customization_store.dart';

/// Floating Tool Box widget với thiết kế Glassmorphism.
///
/// Cung cấp các công cụ nhanh:
/// - Power: Bật/tắt màn hình
/// - Poster: Tạo ảnh tuyển dụng (AI Job Poster)
///
/// Tự động thu gọn khi không gian hẹp.
class FloatingToolBox extends StatefulWidget {
  final String serial;
  final double height;
  final double availableSpace;
  final void Function(PosterData) onJobSelected;
  final PosterData? posterData;
  final bool isGenerating;

  const FloatingToolBox({
    super.key,
    required this.serial,
    required this.height,
    required this.availableSpace,
    required this.onJobSelected,
    this.posterData,
    this.isGenerating = false,
  });

  @override
  State<FloatingToolBox> createState() => FloatingToolBoxState();
}

class FloatingToolBoxState extends State<FloatingToolBox> {
  late final FloatingToolBoxStore _store;
  late final PosterCustomizationStore _customizationStore;
  final GlobalKey _posterKey = GlobalKey();
  int _selectedTemplateIndex = 0;

  final List<String> _templateNames = [
    'Modern',
    'Minimalist',
    'Bold',
    'Corporate',
    'Creative',
  ];

  @override
  void initState() {
    super.initState();
    _store = FloatingToolBoxStore();
    _customizationStore = PosterCustomizationStore();
  }

  /// Chụp ảnh widget poster thành file ảnh PNG.
  Future<File?> capturePoster() async {
    // Clear selection so no borders are captured
    _customizationStore.selectField(null);

    // Wait for frame to repaint to remove highlights
    await Future<void>.delayed(const Duration(milliseconds: 100));

    try {
      final boundary =
          _posterKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null) return null;

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/poster_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      debugPrint('Error capturing poster: $e');
      return null;
    }
  }

  bool get _isCollapsed => widget.availableSpace < 100;

  Widget _buildPosterWidget(PosterData data) {
    switch (_selectedTemplateIndex) {
      case 0:
        return ModernPoster(
          data: data,
          customizationStore: _customizationStore,
        );
      case 1:
        return MinimalistPoster(
          data: data,
          customizationStore: _customizationStore,
        );
      case 2:
        return BoldPoster(data: data, customizationStore: _customizationStore);
      case 3:
        return CorporatePoster(
          data: data,
          customizationStore: _customizationStore,
        );
      case 4:
        return CreativePoster(
          data: data,
          customizationStore: _customizationStore,
        );
      default:
        return ModernPoster(
          data: data,
          customizationStore: _customizationStore,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        return Row(
          children: [
            _buildToolBoxAction(context),
            if (_store.showJobSelector)
              _buildJobSelector(context)
            else if (widget.isGenerating || widget.posterData != null) ...[
              _buildPosterGenerator(context),
              Column(
                children: [
                  _buildCaptionPanel(context),
                  _buildTextScaleSlider(context),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  /// Xây dựng menu chọn việc làm.
  Widget _buildJobSelector(BuildContext context) {
    return FloatingToolBoxCard(
      width: 300,
      height: widget.height,
      child: FloatingJobSelector(
        onJobSelected: (job) {
          _store.hideJobSelector();
          widget.onJobSelected(job);
        },
        onCancel: () {
          _store.hideJobSelector();
        },
      ),
    );
  }

  /// Xây dựng thanh công cụ chính (Power, Poster button).
  Widget _buildToolBoxAction(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return FloatingToolBoxCard(
      width: _isCollapsed ? 56 : 100,
      height: widget.height,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _isCollapsed
              ? _buildIconButton(
                  colorScheme: colorScheme,
                  icon: Icons.power_settings_new_rounded,
                  label: 'Power',
                  onTap: () => _store.sendPowerButton(widget.serial),
                  isError: true,
                )
              : _buildExpandedButton(
                  colorScheme: colorScheme,
                  icon: Icons.power_settings_new_rounded,
                  label: 'Power',
                  onTap: () => _store.sendPowerButton(widget.serial),
                  isError: true,
                ),
          const SizedBox(height: 12),
          _isCollapsed
              ? _buildIconButton(
                  colorScheme: colorScheme,
                  icon: Icons.art_track_rounded,
                  label: 'Poster',
                  onTap: () => _store.toggleJobSelector(),
                  isError: false,
                )
              : _buildExpandedButton(
                  colorScheme: colorScheme,
                  icon: Icons.art_track_rounded,
                  label: 'Poster',
                  onTap: () => _store.toggleJobSelector(),
                  isError: false,
                ),
        ],
      ),
    );
  }

  /// Xây dựng khu vực tạo Poster (Hiển thị Skeleton hoặc Poster thật).
  Widget _buildPosterGenerator(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingToolBoxCard(
            height: 75,
            width: widget.height * (9 / 19),
            child: widget.isGenerating || widget.posterData == null
                ? const SizedBox()
                : _buildTemplateSelector(),
          ),
          FloatingToolBoxCard(
            width: widget.height * (9 / 19),
            height: widget.height - 87,
            child: widget.isGenerating
                ? GeminiSkeletonLayout()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final data =
                          widget.posterData ??
                          PosterData(
                            jobTitle: '',
                            companyName: '',
                            location: '',
                            salaryRange: '',
                            contactInfo: '',
                          );

                      // Cache widget to avoid rebuilding everything on drag
                      final posterWidget = _buildPosterWidget(data);

                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Transform.translate(
                              offset: const Offset(10000, 0),
                              child: RepaintBoundary(
                                key: _posterKey,
                                child: AspectRatio(
                                  aspectRatio:
                                      (widget.height * (9 / 19)) /
                                      (widget.height - 87),
                                  child: posterWidget,
                                ),
                              ),
                            ),
                          ),
                          Draggable<PosterData>(
                            data: data,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Container(
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: posterWidget,
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.5,
                              child: AspectRatio(
                                aspectRatio:
                                    (widget.height * (9 / 19)) /
                                    (widget.height - 87),
                                child: posterWidget,
                              ),
                            ),
                            child: AspectRatio(
                              aspectRatio:
                                  (widget.height * (9 / 19)) /
                                  (widget.height - 87),
                              child: posterWidget,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelector() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: _templateNames.length,
      itemBuilder: (context, index) {
        final isSelected = _selectedTemplateIndex == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedTemplateIndex = index),
          child: Container(
            margin: EdgeInsets.only(right: 8),
            padding: EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? null
                  : Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Text(
              _templateNames[index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Xây dựng panel gợi ý caption
  Widget _buildCaptionPanel(BuildContext context) {
    final caption = widget.posterData?.tikTokCaption;
    if (caption == null) return const SizedBox();
    final theme = Theme.of(context);

    // Tính toán chiều rộng khả dụng: Tổng - (Action + Poster Generator)
    // Action: 100 (expanded) + padding margin
    // Poster Generator: height * (9/19) (Column chứa Selector + Preview)
    // Card padding/margin: ~32
    final usedWidth = 100.0 + (widget.height * (9 / 19)) + 32;
    final remainingSpace = widget.availableSpace - usedWidth;

    // Nếu không đủ chỗ hiển thị tối thiểu 150px thì ẩn
    if (remainingSpace < 150) return const SizedBox();

    return FloatingToolBoxCard(
      width: remainingSpace.clamp(150.0, 350.0), // Max 350px
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GỢI Ý CAPTION',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: caption));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã copy caption!'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.3,
                  ),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    caption,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextScaleSlider(BuildContext context) {
    if (widget.posterData == null) return const SizedBox();

    return Observer(
      builder: (context) {
        if (_customizationStore.selectedFieldId == null) {
          return const SizedBox();
        }

        final currentScale = _customizationStore.getScale(
          _customizationStore.selectedFieldId!,
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
                          _getFriendlyName(
                            _customizationStore.selectedFieldId!,
                          ),
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
                          onTap: () => _customizationStore.updateScale(1.0),
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
                          _customizationStore.updateScale(newScale);
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
                            overlayColor: colorScheme.primary.withOpacity(0.1),
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
                              _customizationStore.updateScale(value);
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
                          _customizationStore.updateScale(newScale);
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

  /// Icon button cho collapsed mode
  Widget _buildIconButton({
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isError = false,
  }) {
    final color = isError ? colorScheme.error : colorScheme.primary;
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
      ),
    );
  }

  /// Full button cho expanded mode
  Widget _buildExpandedButton({
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isError = false,
  }) {
    final color = isError ? colorScheme.error : colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
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
