import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
import 'package:scraki/features/device/presentation/widgets/dialogs/create_group_dialog.dart';

class GroupSidebar extends StatelessWidget {
  const GroupSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final store = getIt<DeviceGroupStore>();
    // Ensure groups are loaded
    if (store.groups.isEmpty) {
      store.loadGroups();
    }

    final theme = Theme.of(context);

    return Container(
      width: 250,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GROUPS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const CreateGroupDialog(),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Observer(
              builder: (_) {
                if (store.groups.isEmpty) {
                  return Center(
                    child: Text(
                      'No groups',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: store.groups.length + 1, // +1 for "All Devices"
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // All Devices Option
                      return Observer(
                        builder: (_) {
                          final isSelected = store.selectedGroupId == null;
                          return ListTile(
                            leading: const Icon(Icons.apps),
                            title: const Text('All Devices'),
                            selected: isSelected,
                            onTap: () => store.selectGroup(null),
                          );
                        },
                      );
                    }

                    final group = store.groups[index - 1];

                    return Observer(
                      builder: (_) {
                        final isSelected = store.selectedGroupId == group.id;

                        return ListTile(
                          leading: Icon(
                            Icons.circle,
                            color: Color(group.colorValue),
                            size: 12,
                          ),
                          title: Text(group.name),
                          selected: isSelected,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.visibility
                                    : Icons.visibility_off_outlined,
                                size: 18,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                tooltip: 'Delete Group',
                                onPressed: () {
                                  showDialog<void>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('Delete "${group.name}"?'),
                                        content: const Text(
                                          'This will remove the group but devices will remain.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () {
                                              store.deleteGroup(group.id);
                                              Navigator.pop(context);
                                            },
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  theme.colorScheme.error,
                                              foregroundColor:
                                                  theme.colorScheme.onError,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () => store.selectGroup(group.id),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
