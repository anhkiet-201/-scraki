import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/store/floating_tool_box_store.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_job_selector.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box_card.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/core/widgets/gemini_poster_skeleton.dart';
import 'package:scraki/features/poster/presentation/widgets/modern_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/minimalist_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/bold_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/corporate_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/creative_poster.dart';

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
  }

  /// Chụp ảnh widget poster thành file ảnh PNG.
  Future<File?> capturePoster() async {
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
        return ModernPoster(data: data);
      case 1:
        return MinimalistPoster(data: data);
      case 2:
        return BoldPoster(data: data);
      case 3:
        return CorporatePoster(data: data);
      case 4:
        return CreativePoster(data: data);
      default:
        return ModernPoster(data: data);
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
            else if (widget.isGenerating || widget.posterData != null)
              _buildPosterGenerator(context),
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
