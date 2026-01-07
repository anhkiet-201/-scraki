import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/dashboard/presentation/stores/dashboard_store.dart';

class DeviceSearchBar extends StatefulWidget {
  final DashboardStore dashboardStore;

  const DeviceSearchBar({super.key, required this.dashboardStore});

  @override
  State<DeviceSearchBar> createState() => _DeviceSearchBarState();
}

class _DeviceSearchBarState extends State<DeviceSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.dashboardStore.searchQuery;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    widget.dashboardStore.setSearchQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Observer(
      builder: (_) {
        final hasText = widget.dashboardStore.searchQuery.isNotEmpty;

        return SearchBar(
          controller: _controller,
          hintText: 'Search devices...',
          leading: const Icon(Icons.search),
          elevation: WidgetStateProperty.all(0),
          backgroundColor: WidgetStateProperty.all(
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16),
          ),
          onChanged: (value) => widget.dashboardStore.setSearchQuery(value),
          trailing: hasText
              ? [
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: _clearSearch,
                    tooltip: 'Clear search',
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ]
              : null,
        );
      },
    );
  }
}
