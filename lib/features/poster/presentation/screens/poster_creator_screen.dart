import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/core/widgets/gemini_poster_skeleton.dart';
import 'package:scraki/core/widgets/skeleton_loader.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/poster/domain/usecases/save_poster_usecase.dart';
import 'package:scraki/features/poster/presentation/store/poster_customization_store.dart';
import 'package:scraki/features/poster/presentation/stores/poster_creation_store.dart';
import 'package:scraki/features/poster/presentation/widgets/bold_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/corporate_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/creative_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/elegant_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/minimalist_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/modern_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/playful_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/retro_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/swiss_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/tech_poster.dart';
import 'package:url_launcher/url_launcher.dart';

/// Desktop Poster Creator Screen (Refactored 3-Column Layout)
class PosterCreatorScreen extends StatefulWidget {
  const PosterCreatorScreen({super.key});

  @override
  State<PosterCreatorScreen> createState() => _PosterCreatorScreenState();
}

class _PosterCreatorScreenState extends State<PosterCreatorScreen> {
  late final PosterCreationStore _posterStore;
  late final PosterCustomizationStore _customizationStore;
  late final SavePosterUseCase _savePosterUseCase;
  final GlobalKey _posterKey = GlobalKey();
  int _selectedTemplateIndex = 0;
  bool _isSaving = false;

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

  @override
  void initState() {
    super.initState();
    _posterStore = inject<PosterCreationStore>();
    _customizationStore = inject<PosterCustomizationStore>();
    _savePosterUseCase = inject<SavePosterUseCase>();
    _posterStore.loadAvailableJobs();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 3-Column Layout: Jobs (Data) -> Preview (Visual) -> Inspector (Tools)
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Row(
        children: [
          // 1. Jobs Sidebar (Fixed width)
          SizedBox(width: 320, child: _buildJobsSidebar(theme)),

          const VerticalDivider(width: 1, thickness: 1),

          // 2. Preview Stage (Flexible)
          Expanded(child: _buildPreviewStage(theme)),

          const VerticalDivider(width: 1, thickness: 1),

          // 3. Inspector Sidebar (Fixed width)
          SizedBox(width: 340, child: _buildInspectorSidebar(theme)),
        ],
      ),
    );
  }

  // region 1. Jobs Sidebar
  Widget _buildJobsSidebar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Công việc',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Chọn nguồn dữ liệu',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Observer(
            builder: (_) {
              final jobs = _posterStore.availableJobs;
              if (jobs.isEmpty) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 4,
                  itemBuilder: (_, index) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: JobCardSkeleton(),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: jobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  final isSelected =
                      _posterStore.currentPosterData?.jobTitle == job.jobTitle;

                  return _buildEnhancedJobCard(theme, job, isSelected);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedJobCard(
    ThemeData theme,
    PosterData job,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => _posterStore.selectJob(job),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.jobTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.business,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.companyName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (job.salaryRange.isNotEmpty)
                  _buildMetadataChip(
                    theme,
                    Icons.attach_money,
                    job.salaryRange,
                  ),
                if (job.location.isNotEmpty)
                  _buildMetadataChip(
                    theme,
                    Icons.location_on,
                    job.location,
                    isLongText: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataChip(
    ThemeData theme,
    IconData icon,
    String label, {
    bool isLongText = false,
  }) {
    return Container(
      constraints: isLongText ? const BoxConstraints(maxWidth: 240) : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          if (isLongText)
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            )
          else
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
  // endregion

  // region 2. Preview Stage
  Widget _buildPreviewStage(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.preview_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Xem trước',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Observer(
                  builder: (_) {
                    final template = _templateNames[_selectedTemplateIndex];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        template,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Canvas Area
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Observer(
                      builder: (_) {
                        final posterData = _posterStore.currentPosterData;
                        final isLoading = _posterStore.isLoading;

                        if (isLoading) {
                          return const SizedBox(
                            width: 360, // ~9:16 base width
                            child: AspectRatio(
                              aspectRatio: 9 / 16,
                              child: GeminiPosterSkeleton(),
                            ),
                          );
                        }

                        if (posterData == null) {
                          return _buildEmptyState(theme);
                        }

                        return _buildPosterCanvas(posterData);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Status Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: theme.colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.aspect_ratio,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '1080 x 1920 px (9:16)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterCanvas(PosterData posterData) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          0,
        ), // Sharp edges for poster like real file
        child: RepaintBoundary(
          key: _posterKey,
          child: _buildPosterWidget(posterData),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.dashboard_customize_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Chưa có poster',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn một công việc từ cột bên trái\nđể bắt đầu thiết kế',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
  // endregion

  // region 3. Inspector Sidebar
  Widget _buildInspectorSidebar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Thiết kế',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionHeader(
                theme,
                Icons.grid_view_rounded,
                'Mẫu Template',
              ),
              const SizedBox(height: 16),
              _buildTemplateGrid(theme),

              const SizedBox(height: 32),

              _buildSectionHeader(theme, Icons.tune_rounded, 'Tùy chỉnh'),
              const SizedBox(height: 16),
              _buildCustomizationPanel(theme),
            ],
          ),
        ),

        // Bottom Action Area
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, -4),
                blurRadius: 16,
              ),
            ],
          ),
          child: _buildSaveButton(theme),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateGrid(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _templateNames.length,
      itemBuilder: (context, index) {
        final isSelected = _selectedTemplateIndex == index;
        final templateName = _templateNames[index];

        return InkWell(
          onTap: () => setState(() => _selectedTemplateIndex = index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                  : theme.colorScheme.surface,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mini preview placeholder could go here
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  size: 24,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                const SizedBox(height: 8),
                Text(
                  templateName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // endregion

  // region Logic & Widgets Helpers
  // [Keep _buildCustomizationPanel logic from previous step, just refined UI]
  Widget _buildCustomizationPanel(ThemeData theme) {
    return Observer(
      builder: (_) {
        final selectedField = _customizationStore.selectedFieldId;
        final posterData = _posterStore.currentPosterData;

        // State 1: No Poster
        if (posterData == null) {
          return _buildInfoBox(theme, 'Chọn công việc để bắt đầu chỉnh sửa.');
        }

        // State 2: No Selection
        if (selectedField == null) {
          return _buildInfoBox(
            theme,
            'Chạm vào văn bản trên poster để chỉnh sửa nội dung hoặc kích thước.',
          );
        }

        // State 3: Editing
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Nội dung', style: theme.textTheme.labelMedium),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      _customizationStore.resetText();
                      _customizationStore.updateScale(1.0);
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    tooltip: 'Đặt lại',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue:
                    _customizationStore.getText(selectedField) ??
                    _customizationStore.selectedDefaultText,
                onChanged: (val) => _customizationStore.updateText(val),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 3,
                minLines: 1,
              ),

              const SizedBox(height: 16),

              Text('Kích thước', style: theme.textTheme.labelMedium),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _customizationStore.getScale(selectedField),
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      onChanged: (val) => _customizationStore.updateScale(val),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(_customizationStore.getScale(selectedField) * 100).toInt()}%',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoBox(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [Keep _buildPosterWidget switch case]
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
      case 5:
        return TechPoster(data: data, customizationStore: _customizationStore);
      case 6:
        return ElegantPoster(
          data: data,
          customizationStore: _customizationStore,
        );
      case 7:
        return PlayfulPoster(
          data: data,
          customizationStore: _customizationStore,
        );
      case 8:
        return RetroPoster(data: data, customizationStore: _customizationStore);
      case 9:
        return SwissPoster(data: data, customizationStore: _customizationStore);
      default:
        return ModernPoster(
          data: data,
          customizationStore: _customizationStore,
        );
    }
  }

  // [Keep Save logic]
  Widget _buildSaveButton(ThemeData theme) {
    return Observer(
      builder: (_) {
        final posterData = _posterStore.currentPosterData;
        final canSave = posterData != null && !_isSaving;

        return FilledButton.icon(
          onPressed: canSave ? _handleSavePoster : null,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.download_rounded),
          label: Text(_isSaving ? 'Đang lưu...' : 'Lưu Poster'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSavePoster() async {
    // ... [Keep existing save logic] ...
    final posterData = _posterStore.currentPosterData;
    if (posterData == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      _customizationStore.selectField(null); // Clear selection
      await Future<void>.delayed(
        const Duration(milliseconds: 100),
      ); // Wait repaint

      final boundary =
          _posterKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return; // Error handling

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final sanitizedTitle = posterData.jobTitle
            .replaceAll(RegExp(r'[^\w\s-]'), '')
            .replaceAll(RegExp(r'\s+'), '_')
            .trim();
        final filename =
            '${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.png';

        final result = await _savePosterUseCase(
          pngBytes: pngBytes,
          fileName: filename,
        );

        result.fold(
          (l) => _showSnackBar(l, isError: true),
          (r) => _showSnackBar(
            'Lưu thành công: $r',
            actionLabel: 'Mở thư mục',
            actionPath: r,
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Lỗi: $e', isError: true);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSnackBar(
    String msg, {
    bool isError = false,
    String? actionLabel,
    String? actionPath,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        action: actionLabel != null && actionPath != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: () {
                  final dir = actionPath.substring(
                    0,
                    actionPath.lastIndexOf('/') + 1,
                  );
                  launchUrl(Uri.file(dir));
                },
              )
            : null,
      ),
    );
  }
}
