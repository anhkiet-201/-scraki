import 'package:flutter/material.dart';
import 'package:scraki/core/widgets/gemini_poster_skeleton.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/floating_tool_box_card.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/template_selector.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/poster/presentation/store/poster_customization_store.dart';
import 'package:scraki/features/poster/presentation/widgets/bold_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/corporate_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/creative_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/minimalist_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/modern_poster.dart';

import 'package:scraki/features/poster/presentation/widgets/tech_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/elegant_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/playful_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/retro_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/swiss_poster.dart';

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
  int _selectedTemplateIndex = 0;

  final List<String> _templateNames = [
    'Modern',
    'Minimalist',
    'Bold',
    'Corporate',
    'Creative',
    'Tech',
    'Elegant',
    'Playful',
    'Retro',
    'Swiss',
  ];

  Widget _buildPosterWidget(PosterData data) {
    switch (_selectedTemplateIndex) {
      case 0:
        return ModernPoster(
          data: data,
          customizationStore: widget.customizationStore,
        );
      case 1:
        return MinimalistPoster(
          data: data,
          customizationStore: widget.customizationStore,
        );
      case 2:
        return BoldPoster(
          data: data,
          customizationStore: widget.customizationStore,
        );
      case 3:
        return CorporatePoster(
          data: data,
          customizationStore: widget.customizationStore,
        );
      case 4:
        return CreativePoster(
          data: data,
          customizationStore: widget.customizationStore,
        );
      case 5:
        return TechPoster(
          data: data,
          customizationStore: widget.customizationStore,
        );
      case 6:
        return ElegantPoster(
          data: data,
          customizationStore: widget.customizationStore,
        );
      case 7:
        return PlayfulPoster(
          data: data,
          customizationStore: widget.customizationStore,
        );
      case 8:
        return RetroPoster(
          data: data,
          customizationStore: widget.customizationStore,
        );
      case 9:
        return SwissPoster(
          data: data,
          customizationStore: widget.customizationStore,
        );
      default:
        return ModernPoster(
          data: data,
          customizationStore: widget.customizationStore,
        );
    }
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
            width: widget.height * (9 / 19),
            child: widget.isGenerating || widget.posterData == null
                ? const SizedBox()
                : TemplateSelector(
                    selectedIndex: _selectedTemplateIndex,
                    onSelect: (index) =>
                        setState(() => _selectedTemplateIndex = index),
                    templateNames: _templateNames,
                  ),
          ),
          FloatingToolBoxCard(
            width: widget.height * (9 / 19),
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
                          Positioned.fill(
                            child: Transform.translate(
                              offset: const Offset(10000, 0),
                              child: RepaintBoundary(
                                key: widget.posterKey,
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
}
