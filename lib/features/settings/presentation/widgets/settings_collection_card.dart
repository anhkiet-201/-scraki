import 'package:flutter/material.dart';

const _kCollections = ['device_groups', 'device_groups_b'];

/// Card widget để chọn Firestore collection cho device groups
class SettingsCollectionCard extends StatelessWidget {
  final String selectedCollection;
  final ValueChanged<String> onChanged;

  const SettingsCollectionCard({
    super.key,
    required this.selectedCollection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 480),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.storage_rounded,
                    size: 18,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Collection',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Firestore collection source',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SegmentedButton để chọn collection
            SegmentedButton<String>(
              segments: _kCollections
                  .map(
                    (name) => ButtonSegment<String>(
                      value: name,
                      label: Text(name, overflow: TextOverflow.ellipsis),
                      icon: const Icon(Icons.folder_outlined, size: 16),
                    ),
                  )
                  .toList(),
              selected: {selectedCollection},
              onSelectionChanged: (selection) => onChanged(selection.first),
              style: SegmentedButton.styleFrom(
                textStyle: theme.textTheme.bodySmall,
              ),
            ),

            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Chọn collection Firestore để đọc dữ liệu thiết bị',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
