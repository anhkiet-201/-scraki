import 'package:flutter/material.dart';
import '../../../../../core/constants/ui_constants.dart';

/// Progress indicator shown when files are being pushed to device.
///
/// Displays during file upload operations.
class PushProgressView extends StatelessWidget {
  const PushProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      top: 40,
      left: 40,
      right: 40,
      child: Center(
        child: Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: UIConstants.progressIndicatorSize,
                height: UIConstants.progressIndicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: UIConstants.progressIndicatorStroke,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Pushing files to phone...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
