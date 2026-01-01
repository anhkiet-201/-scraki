import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../../core/constants/ui_constants.dart';

/// Overlay shown when files are being dragged over the phone view.
///
/// Provides visual feedback for drag and drop file operations.
class DragOverlayView extends StatelessWidget {
  const DragOverlayView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(UIConstants.componentBorderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: theme.colorScheme.primaryContainer.withOpacity(0.7),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.file_copy_rounded,
                      size: UIConstants.dragOverlayIconSize,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Drop Files to Sync',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: UIConstants.dragOverlayTitleSize,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Files will be copied to /sdcard/Download',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(
                        0.7,
                      ),
                      fontSize: UIConstants.dragOverlaySubtitleSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
