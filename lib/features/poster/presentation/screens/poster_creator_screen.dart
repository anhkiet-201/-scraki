import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/core/widgets/gemini_poster_skeleton.dart';
import 'package:scraki/core/widgets/skeleton_loader.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/poster/domain/usecases/save_poster_usecase.dart';
import 'package:scraki/features/poster/presentation/store/poster_customization_store.dart';
import 'package:scraki/features/poster/presentation/stores/poster_creation_store.dart';
import 'package:scraki/features/poster/domain/enums/poster_template_type.dart';
import 'package:scraki/features/poster/presentation/extensions/poster_template_extensions.dart';

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

  // Customization State
  late final TextEditingController _textEditingController;
  ReactionDisposer? _textSyncDisposer;

  PosterTemplateType _selectedTemplate = PosterTemplateType.modern;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _posterStore = inject<PosterCreationStore>();
    _customizationStore = inject<PosterCustomizationStore>();
    _savePosterUseCase = inject<SavePosterUseCase>();

    _textEditingController = TextEditingController();
    _posterStore.loadAvailableJobs();

    // Sync text controller with store selection
    _textSyncDisposer = reaction((_) => _customizationStore.selectedFieldId, (
      selectedField,
    ) {
      if (selectedField != null) {
        final currentText =
            _customizationStore.getText(selectedField) ??
            _customizationStore.selectedDefaultText ??
            '';
        if (_textEditingController.text != currentText) {
          _textEditingController.text = currentText;
        }
      }
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _textSyncDisposer?.call();
    super.dispose();
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
              final hasMore = _posterStore.hasMore;

              if (jobs.isEmpty && _posterStore.isLoading) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 4,
                  itemBuilder: (_, index) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: JobCardSkeleton(),
                  ),
                );
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200 &&
                      !_posterStore.isLoading &&
                      !_posterStore.isLoadMore &&
                      hasMore) {
                    _posterStore.loadAvailableJobs(loadMore: true);
                  }
                  return false;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: jobs.length + (hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == jobs.length) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        child: JobCardSkeleton(),
                      );
                    }
                    final job = jobs[index];
                    final isSelected =
                        _posterStore.currentPosterData?.jobTitle ==
                        job.jobTitle;

                    return _buildEnhancedJobCard(theme, job, isSelected);
                  },
                ),
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
              ? theme.colorScheme.primaryContainer.withOpacity(0.2)
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
                        _selectedTemplate.label,
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

                        // Observe customization changes to force rebuild preview
                        // ignore: unused_local_variable
                        final tick = _customizationStore.selectedFieldId;

                        if (isLoading) {
                          return const SizedBox(
                            width: 480, // ~9:16 base width
                            child: AspectRatio(
                              aspectRatio: 0.7,
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
                  '480 x 685 px (0.7:1)',
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
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
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
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thiết kế',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Regenerate Button
              Observer(
                builder: (_) {
                  final canRegenerate = _posterStore.currentPosterData != null;
                  return Tooltip(
                    message: 'Tạo lại nội dung',
                    child: InkWell(
                      onTap: canRegenerate
                          ? () {
                              _customizationStore.reset(); // Reset edits
                              _posterStore.regenerate();
                            }
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _posterStore.isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : Icon(
                                Icons.auto_awesome,
                                size: 18,
                                color: canRegenerate
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ],
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

              // Caption Recommendation
              _buildSectionHeader(
                theme,
                Icons.lightbulb_outline_rounded,
                'Gợi ý Caption',
              ),
              const SizedBox(height: 16),
              _buildCaptionBox(theme),

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
                color: Colors.black.withOpacity(0.05),
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

  Widget _buildCaptionBox(ThemeData theme) {
    return Observer(
      builder: (_) {
        final posterData = _posterStore.currentPosterData;
        final caption = posterData?.tikTokCaption;

        if (posterData == null) {
          return _buildInfoBox(theme, 'Chọn công việc để xem gợi ý caption.');
        }

        if (caption == null || caption.isEmpty) {
          return _buildInfoBox(
            theme,
            'Không có gợi ý caption cho công việc này.',
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NỘI DUNG',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Tooltip(
                      message: 'Sao chép',
                      child: InkWell(
                        onTap: () {
                          // Note: Clipboard requires 'flutter/services.dart'
                          // I'll assume it's available or add import if needed.
                          // It is usually exported by material, but explicit import is better.
                          // Actually, Clipboard is in services.
                          // I will add import if it fails, but let's try.
                          // Actually, I should use the helper method _copyToClipboard if I had one,
                          // but I'll write logic here.
                          // Wait, Clipboard class needs 'package:flutter/services.dart'.
                          // It is NOT in material.dart.
                          // I should check imports. 'scraki/features/poster/presentation/screens/poster_creator_screen.dart' has imports at top.
                          // I will check imports in next step if this fails or just add logic.
                          // For now, I will use a simple method call that I will implement if needed or just inline code.
                          _copyCaption(context, caption);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                child: SelectableText(
                  caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _copyCaption(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép caption!'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
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
      itemCount: PosterTemplateType.values.length,
      itemBuilder: (context, index) {
        final template = PosterTemplateType.values[index];
        final isSelected = _selectedTemplate == template;

        return InkWell(
          onTap: () => setState(() => _selectedTemplate = template),
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
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  size: 24,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                const SizedBox(height: 8),
                Text(
                  template.label,
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
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getFriendlyName(selectedField),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Tooltip(
                      message: 'Đặt lại',
                      child: InkWell(
                        onTap: () {
                          _customizationStore.updateScale(1.0);
                          _customizationStore
                              .resetText(); // Will trigger store update
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Text Editing Field
              Padding(
                padding: const EdgeInsets.all(12),
                child: _AutoSyncTextField(
                  key: ValueKey('input_$selectedField'),
                  initialValue:
                      _customizationStore.getText(selectedField) ??
                      _customizationStore.selectedDefaultText ??
                      '',
                  onChanged: (val) => _customizationStore.updateText(val),
                ),
              ),

              // Scale Slider
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Kích thước',
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.remove_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            final current = _customizationStore.getScale(
                              selectedField,
                            );
                            final newScale = (current - 0.1).clamp(0.5, 3.0);
                            _customizationStore.updateScale(newScale);
                          },
                          tooltip: 'Giảm cỡ chữ',
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: theme.colorScheme.primary,
                              inactiveTrackColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              thumbColor: theme.colorScheme.primary,
                              overlayColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
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
                              value: _customizationStore.getScale(
                                selectedField,
                              ),
                              min: 0.5,
                              max: 3.0,
                              divisions: 25,
                              label:
                                  '${(_customizationStore.getScale(selectedField) * 100).toInt()}%',
                              onChanged: (val) =>
                                  _customizationStore.updateScale(val),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            final current = _customizationStore.getScale(
                              selectedField,
                            );
                            final newScale = (current + 0.1).clamp(0.5, 3.0);
                            _customizationStore.updateScale(newScale);
                          },
                          tooltip: 'Tăng cỡ chữ',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getFriendlyName(String scopedId) {
    final parts = scopedId.split('_');
    final String id;
    if (parts.length > 1) {
      id = parts.sublist(1).join('_');
    } else {
      id = scopedId;
    }

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
    return id;
  }

  // ... [Other methods unchanged]
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

  Widget _buildPosterWidget(PosterData data) {
    return _selectedTemplate.buildWidget(
      data: data,
      width: 480,
      height: 685,
      customizationStore: _customizationStore,
    );
  }

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

/// A TextField that initializes its controller with [initialValue]
/// and updates when [initialValue] changes via [didUpdateWidget].
class _AutoSyncTextField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _AutoSyncTextField({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_AutoSyncTextField> createState() => _AutoSyncTextFieldState();
}

class _AutoSyncTextFieldState extends State<_AutoSyncTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _AutoSyncTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync if initialValue differs from current text (e.g. Reset or external change)
    if (widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
      // Reset selection to end
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(),
        isDense: true,
        hintText: 'Nhập nội dung...',
      ),
      maxLines: 3,
      minLines: 1,
    );
  }
}
