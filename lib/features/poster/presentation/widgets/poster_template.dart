import 'package:flutter/material.dart';
import '../../../../features/poster/domain/entities/poster_data.dart';
import '../store/poster_customization_store.dart';
import 'editable_poster_element.dart';

/// Abstract base class for all poster templates.
///
/// Handles the common logic of:
/// 1. Accepting dimensions (width/height).
/// 2. Using [LayoutBuilder] to determine effective size.
/// 3. Calculating a [scale] factor based on a reference design size (target mobile screen 375x667).
abstract class PosterTemplate extends StatelessWidget {
  final PosterData data;
  final double width;
  final double height;
  final PosterCustomizationStore? customizationStore;

  const PosterTemplate({
    super.key,
    required this.data,
    this.width = 375,
    this.height = 667,
    this.customizationStore,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Effective dimensions
        final double w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : width;
        final double h = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : height;

        // Calculate scale factor using the limiting dimension to ensure fit
        // Base reference: 375 x 667
        final double scaleX = w / 375.0;
        final double scaleY = h / 667.0;
        final double scale = (scaleX < scaleY) ? scaleX : scaleY;

        return Container(
          width: w,
          height: h,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(color: Colors.white),
          child: buildPoster(context, scale, w, h),
        );
      },
    );
  }

  /// Build the actual poster content.
  ///
  /// [scale]: The scaling factor to apply to fonts and paddings.
  /// [w]: The effective width of the poster.
  /// [h]: The effective height of the poster.
  Widget buildPoster(BuildContext context, double scale, double w, double h);

  /// Unique ID for this template (e.g., 'modern', 'tech', 'retro').
  /// Used for scoping edits to avoid conflicts between templates.
  String get templateId;

  /// Helper to wrap content in [EditablePosterElement] if customization is enabled.
  Widget wrapEditable(
    String id,
    Widget Function(String text, double textScale) builder, {
    String? defaultText,
  }) {
    if (customizationStore == null) {
      return builder(defaultText ?? '', 1.0);
    }

    // If no default text is provided, try to infer it from the builder or use empty
    // But ideally refactor templates to pass it explicitely.
    // For now we just use a placeholder if not provided, assuming builder handles text.
    // However, to support text editing, we need the text.

    // Better signature:
    // Widget wrapEditable(String id, String defaultText, Widget Function(String text, double scale) builder)
    // But since we are doing stepwise refactor, let's stick to the plan.
    // The previous plan said:
    // wrapEditable(String id, String defaultText, Widget Function(String text, double scale) builder)

    // Wait, I cannot change the builder signature yet because all templates use the old one.
    // I need to update the signature AND the implementation in one go for each file, OR provide backward compatibility.
    // Given the request "Refactor all poster templates", I should update the signature here first, then fix the errors in subclasses.

    final scopedId = '${templateId}_$id';
    return EditablePosterElement(
      id: scopedId,
      defaultText: defaultText ?? '',
      store: customizationStore!,
      builder: builder,
    );
  }
}
