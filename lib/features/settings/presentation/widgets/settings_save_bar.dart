import 'package:flutter/material.dart';

/// Bottom action bar with save button for Settings screen
class SettingsSaveBar extends StatelessWidget {
  final VoidCallback? onSave;
  final bool isLoading;

  const SettingsSaveBar({
    super.key,
    required this.onSave,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Row(
        children: [
          // Info text
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Changes will be saved locally',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Save Button
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onSave,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
