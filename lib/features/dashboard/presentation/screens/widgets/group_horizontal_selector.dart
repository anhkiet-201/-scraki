import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
import 'package:scraki/features/device/presentation/widgets/dialogs/create_group_dialog.dart';
import 'package:scraki/features/device/domain/entities/device_group_entity.dart';
import 'package:scraki/core/widgets/box_card.dart';

class GroupHorizontalSelector extends StatelessWidget {
  const GroupHorizontalSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final store = getIt<DeviceGroupStore>();
    final theme = Theme.of(context);

    // Ensure groups are loaded
    if (store.groups.isEmpty) {
      store.loadGroups();
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // "All" Chip
          Observer(
            builder: (_) {
              final isSelected = store.selectedGroupId == null;
              return _GroupChip(
                label: 'All Devices',
                isSelected: isSelected,
                color: theme.colorScheme.primary,
                onTap: () => store.selectGroup(null),
              );
            },
          ),
          const VerticalDivider(width: 24, indent: 8, endIndent: 8),
          // Group List
          Expanded(
            child: Observer(
              builder: (_) {
                if (store.groups.isEmpty) {
                  return Text(
                    'No groups created',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: store.groups.length,
                  itemBuilder: (context, index) {
                    final group = store.groups[index];

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Observer(
                        key: ValueKey('group_${group.id}'),
                        builder: (_) {
                          final isSelected = store.selectedGroupId == group.id;
                          return _GroupChip(
                            label: group.name,
                            isSelected: isSelected,
                            color: Color(group.colorValue),
                            onTap: () => store.selectGroup(group.id),
                            onDelete: () =>
                                _showDeleteConfirmation(context, store, group),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Add Button
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 24),
            tooltip: 'Create Group',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => const CreateGroupDialog(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    DeviceGroupStore store,
    DeviceGroupEntity group,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          backgroundColor: Colors.transparent,
          child: BoxCard(
            width: 350,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete "${group.name}"?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'This will remove the group but devices will remain unaffected.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          store.deleteGroup(group.id);
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _GroupChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : theme.colorScheme.outlineVariant,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isSelected)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              if (!isSelected) const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                  letterSpacing: isSelected ? 0.5 : 0,
                ),
              ),
              if (onDelete != null && isSelected) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    // Prevent propagation to the chip's onTap
                    onDelete!();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
