import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/floating_tool_box_card.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/poster/presentation/stores/poster_customization_store.dart';

class TextScaleSlider extends StatefulWidget {
  final PosterData? posterData;
  final PosterCustomizationStore customizationStore;

  const TextScaleSlider({
    super.key,
    required this.posterData,
    required this.customizationStore,
  });

  @override
  State<TextScaleSlider> createState() => _TextScaleSliderState();
}

class _TextScaleSliderState extends State<TextScaleSlider> {
  late final TextEditingController _textController;
  ReactionDisposer? _disposer;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    // Sync controller when selection changes
    _disposer = reaction((_) => widget.customizationStore.selectedFieldId, (
      id,
    ) {
      if (id != null) {
        final text =
            widget.customizationStore.getText(id) ??
            widget.customizationStore.selectedDefaultText ??
            '';

        // Only update if different to avoid cursor jumping if we were to use this listener for text changes too
        if (_textController.text != text) {
          _textController.text = text;
        }
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _disposer?.call();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.posterData == null) return const SizedBox();

    return Observer(
      builder: (context) {
        if (widget.customizationStore.selectedFieldId == null) {
          return const SizedBox();
        }

        final selectedId = widget.customizationStore.selectedFieldId!;
        final currentScale = widget.customizationStore.getScale(selectedId);

        // Update controller text if it's different from store (syncing)
        // We only update if the user is NOT typing (or we just selected a new field)
        // But since this is a stateless build method called on store update, we need to be careful.
        // A simple way is to update the controller only when selection changes.
        // However, here we are inside Observer.
        // Let's rely on a reaction in initState or just checking against current selection.

        final currentTextOverride = widget.customizationStore.getText(
          selectedId,
        );
        // Note: For now we don't know the "default text" here easily without passing it from the widget layer.
        // But the user can start typing. If override is null, the text field shows empty or "Edit text...".
        // Improved UX: The implementation plan didn't strictly say we must pre-fill the default text
        // if it's not in the store. But strictly, we can't unless we store default text in store too.
        // For this iteration, let's show placeholder if empty, or the overridden text.

        // Actually, to pre-fill the text field with the current text on the poster,
        // we would need the store to know about the default text when the field is selected.
        // That's a nice-to-have. For now, we will just show what's in textOverrides.

        if (_textController.text != currentTextOverride &&
            currentTextOverride != null) {
          // This might conflict with typing if we are not careful.
          // We'll leave it simple: Controller is driven by user.
          // If we really want to sync, we should use a reaction outside build.
          // For now, let's just set it when selection changes (we can't easily detect that here without state).
          // Let's just use the value from store for initial value if we could...
          // Simplification: just allow editing overrides.
        }

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
                        Icons.edit_note_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getFriendlyName(selectedId),
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
                          onTap: () {
                            widget.customizationStore.updateScale(1.0);
                            widget.customizationStore
                                .resetText(); // Reset text to default (null)
                            _textController.text =
                                widget.customizationStore.selectedDefaultText ??
                                '';
                          },
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

                // Text Editing Field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _textController,
                      style: theme.textTheme.bodySmall,
                      decoration: InputDecoration(
                        hintText: 'Nhập nội dung thay thế...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                      ),
                      onChanged: (value) {
                        widget.customizationStore.updateText(value);
                      },
                    ),
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
                          widget.customizationStore.updateScale(newScale);
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
                              widget.customizationStore.updateScale(value);
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
                          widget.customizationStore.updateScale(newScale);
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

  String _getFriendlyName(String scopedId) {
    // scopedId format: templateId_fieldId
    // We want to extract fieldId.
    final parts = scopedId.split('_');
    final String id;
    if (parts.length > 1) {
      // Combine all parts after the first one to handle potential underscores in fieldId itself?
      // Currently our fieldIds are simple camelCase or prefix_index.
      // But 'req_0' has an underscore.
      // So 'swiss_req_0'. parts = ['swiss', 'req', '0'].
      // We want 'req_0'.
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
    return id; // Fallback
  }
}
