import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
import 'package:scraki/features/device/presentation/widgets/dialogs/create_group_dialog.dart';
import 'package:scraki/features/device/domain/entities/device_group_entity.dart';
import 'package:scraki/core/widgets/box_card.dart';

class GroupHorizontalSelector extends StatefulWidget {
  const GroupHorizontalSelector({super.key});

  @override
  State<GroupHorizontalSelector> createState() =>
      _GroupHorizontalSelectorState();
}

class _GroupHorizontalSelectorState extends State<GroupHorizontalSelector> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = getIt<DeviceGroupStore>();
    final theme = Theme.of(context);

    // Ensure groups are loaded via stream
    if (store.groups.isEmpty && store.errorMessage == null) {
      store.listenToGroups();
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent, // Let parent glass backdrop show through
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
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
                label: 'Tất cả thiết bị',
                isSelected: isSelected,
                color: theme.colorScheme.primary,
                onTap: () => store.selectGroup(null),
              );
            },
          ),
          const VerticalDivider(width: 32, indent: 8, endIndent: 8),
          // Group List
          Expanded(
            child: Observer(
              builder: (_) {
                if (store.groups.isEmpty) {
                  return Center(
                    child: Text(
                      'Chưa có nhóm nào',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }

                return Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      final newOffset = _scrollController.offset + pointerSignal.scrollDelta.dy;
                      if (newOffset < 0) {
                        _scrollController.jumpTo(0);
                      } else if (newOffset > _scrollController.position.maxScrollExtent) {
                        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                      } else {
                        _scrollController.jumpTo(newOffset);
                      }
                    }
                  },
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                        PointerDeviceKind.stylus,
                      },
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: store.groups.length,
                      itemBuilder: (context, index) {
                        final group = store.groups[index];

                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Observer(
                            key: ValueKey('group_${group.id}'),
                            builder: (_) {
                              final isSelected =
                                  store.selectedGroupId == group.id;
                              return _GroupChip(
                                label: group.name,
                                isSelected: isSelected,
                                color: Color(group.colorValue),
                                count: group.deviceSerials.length,
                                onTap: () => store.selectGroup(group.id),
                                onDelete: () => _showDeleteConfirmation(
                                  context,
                                  store,
                                  group,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          // Add Button
          const SizedBox(width: 12),
          _buildAddGroupButton(theme),
        ],
      ),
    );
  }

  Widget _buildAddGroupButton(ThemeData theme) {
    return Tooltip(
      message: 'Tạo nhóm',
      child: Material(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (_) => const CreateGroupDialog(),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.add_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
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
                  'Xóa "${group.name}"?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Hành động này sẽ xóa nhóm, các thiết bị bên trong sẽ không bị ảnh hưởng.',
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
                        child: const Text('Hủy'),
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
                        child: const Text('Xóa'),
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
  final int? count;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _GroupChip({
    required this.label,
    required this.isSelected,
    required this.color,
    this.count,
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
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.9) : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.1),
              width: 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Colorful Dot with Glow (Same as Context Menu)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                count != null ? '$label ($count)' : label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  letterSpacing: isSelected ? 0.3 : 0,
                ),
              ),
              if (onDelete != null && isSelected) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
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
