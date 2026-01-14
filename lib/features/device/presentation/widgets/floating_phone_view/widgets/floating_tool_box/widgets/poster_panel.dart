import 'package:flutter/material.dart';
import 'package:scraki/core/widgets/gemini_poster_skeleton.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/floating_tool_box_card.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/template_selector.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/poster/domain/enums/poster_template_type.dart';
import 'package:scraki/features/poster/presentation/extensions/poster_template_extensions.dart';
import 'package:scraki/features/poster/presentation/stores/poster_customization_store.dart';

class PosterPanel extends StatefulWidget {
  final double height;
  final bool isGenerating;
  final PosterData? posterData;
  final PosterCustomizationStore customizationStore;
  final GlobalKey posterKey;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const PosterPanel({
    super.key,
    required this.height,
    required this.isGenerating,
    required this.posterData,
    required this.customizationStore,
    required this.posterKey,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<PosterPanel> createState() => _PosterPanelState();
}

class _PosterPanelState extends State<PosterPanel> {
  PosterTemplateType _selectedTemplate = PosterTemplateType.modern;

  final double _aspectRatio = 0.7;

  Widget _buildPosterWidget(PosterData data) {
    return _selectedTemplate.buildWidget(
      data: data,
      customizationStore: widget.customizationStore,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingToolBoxCard(
            height: 75,
            width: (widget.height - 87) * _aspectRatio,
            child: widget.isGenerating || widget.posterData == null
                ? const SizedBox()
                : TemplateSelector(
                    selectedIndex: PosterTemplateType.values.indexOf(
                      _selectedTemplate,
                    ),
                    onSelect: (index) => setState(
                      () =>
                          _selectedTemplate = PosterTemplateType.values[index],
                    ),
                    templateNames: PosterTemplateType.values
                        .map((e) => e.label)
                        .toList(),
                  ),
          ),
          FloatingToolBoxCard(
            width: (widget.height - 87) * _aspectRatio,
            height: widget.height - 87,
            child: widget.isGenerating
                ? GeminiSkeletonLayout()
                : widget.errorMessage != null
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.onRetry != null) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: widget.onRetry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: Colors.red,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Colors.red.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ],
                    ),
                  )
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
                          Positioned(
                            left: 10000, // Move off-screen
                            top: 0,
                            child: RepaintBoundary(
                              key: widget.posterKey,
                              child: SizedBox(
                                width: 360,
                                height: 360 / _aspectRatio,
                                child: posterWidget,
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
                                aspectRatio: _aspectRatio,
                                child: posterWidget,
                              ),
                            ),
                            child: AspectRatio(
                              aspectRatio: _aspectRatio,
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
}
