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
    final isLight = Theme.of(context).brightness == Brightness.light;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 480),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: null,
          boxShadow: isLight 
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))] 
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storage_rounded,
                    size: 18,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEVICE COLLECTION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isLight ? const Color(0xFF1E293B) : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nguồn dữ liệu Firestore nhóm thiết bị',
                        style: TextStyle(
                          fontSize: 10,
                          color: isLight ? const Color(0xFF64748B) : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // SegmentedButton để chọn collection
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: _kCollections
                    .map(
                      (name) => ButtonSegment<String>(
                        value: name,
                        label: Text(name, overflow: TextOverflow.ellipsis),
                        icon: const Icon(Icons.folder_outlined, size: 14),
                      ),
                    )
                    .toList(),
                selected: {selectedCollection},
                onSelectionChanged: (selection) => onChanged(selection.first),
                style: SegmentedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: isLight ? Colors.black.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.02),
                  selectedBackgroundColor: const Color(0xFF6366F1),
                  selectedForegroundColor: Colors.white,
                  side: BorderSide(color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chọn collection Firestore để đọc dữ liệu thiết bị',
                    style: TextStyle(
                      fontSize: 10,
                      color: isLight ? const Color(0xFF64748B) : Colors.white38,
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
