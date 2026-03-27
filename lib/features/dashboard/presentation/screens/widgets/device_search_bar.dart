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
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.dashboardStore.searchQuery;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    widget.dashboardStore.setSearchQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Observer(
      builder: (_) {
        final hasText = widget.dashboardStore.searchQuery.isNotEmpty;

        return Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _isFocused
                ? (isLight ? Colors.white : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3))
                : (isLight ? Colors.black.withValues(alpha: 0.04) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.15)),
            border: Border.all(
              color: _isFocused
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              if (_isFocused)
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Icons.search_rounded,
                size: 20,
                color: _isFocused
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (value) => widget.dashboardStore.setSearchQuery(value),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search devices...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (hasText)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: _clearSearch,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  tooltip: 'Clear search',
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        );
      },
    );
  }
}
