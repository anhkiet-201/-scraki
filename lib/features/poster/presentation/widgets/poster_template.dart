import 'package:flutter/material.dart';
import '../../../../features/poster/domain/entities/poster_data.dart';

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

  const PosterTemplate({
    super.key,
    required this.data,
    this.width = 375,
    this.height = 667,
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
}
