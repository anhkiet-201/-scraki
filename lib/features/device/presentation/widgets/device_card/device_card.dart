import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/core/widgets/status_badge.dart';
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
import 'package:scraki/core/widgets/box_card_menu.dart';

import '../phone_view/phone_view.dart';

/// A card widget that displays information about a device and provides a mirror action.
class DeviceCard extends StatefulWidget {
  final DeviceEntity device;
  final VoidCallback onDisconnect;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onDisconnect,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard>
    with AutomaticKeepAliveClientMixin {
  // Local UI state using MobX observables
  final Observable<bool> _isHovered = Observable(false);
  final Observable<bool> _hasFocus = Observable(false);
  final FocusNode _cardFocusNode = FocusNode();

  void _setupFocusListener() {
    _cardFocusNode.addListener(() {
      runInAction(() => _hasFocus.value = _cardFocusNode.hasFocus);
    });
  }

  void _handleCardTap(BuildContext context) {
    FocusScope.of(context).requestFocus(_cardFocusNode);
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final store = getIt<DeviceGroupStore>();
    final allGroups = store.groups;
    final deviceGroups = allGroups
        .where((g) => g.deviceSerials.contains(widget.device.serial))
        .toList();
    final availableGroups = allGroups
        .where((g) => !g.deviceSerials.contains(widget.device.serial))
        .toList();

    BoxCardMenu.show<void>(
      context: context,
      position: position,
      width: 250,
      items: [
        if (availableGroups.isNotEmpty) ...[
          const BoxCardMenuHeader(title: 'Add to Group'),
          ...availableGroups.map(
            (group) => BoxCardMenuItem(
              icon: Icon(
                Icons.add_circle_outline,
                color: Color(group.colorValue),
              ),
              label: Text(group.name),
              onTap: () =>
                  store.addDeviceToGroup(group.id, widget.device.serial),
            ),
          ),
        ],
        if (deviceGroups.isNotEmpty) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          const BoxCardMenuHeader(title: 'Remove from Group'),
          ...deviceGroups.map(
            (group) => BoxCardMenuItem(
              icon: Icon(
                Icons.remove_circle_outline,
                color: Color(group.colorValue),
              ),
              label: Text(group.name),
              onTap: () =>
                  store.removeDeviceFromGroup(group.id, widget.device.serial),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _setupFocusListener();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Observer(
      builder: (_) {
        return MouseRegion(
          onEnter: (_) => runInAction(() => _isHovered.value = true),
          onExit: (_) => runInAction(() => _isHovered.value = false),
          child: GestureDetector(
            onTap: () => _handleCardTap(context),
            onSecondaryTapDown: (details) =>
                _showContextMenu(context, details.globalPosition),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.fastOutSlowIn,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (_isHovered.value || _hasFocus.value)
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Card(
                elevation: 0,
                color: _isHovered.value
                    ? colorScheme.surfaceContainerLow
                    : colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _hasFocus.value
                        ? colorScheme.primary
                        : (_isHovered.value
                              ? colorScheme.outline
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.3,
                                )),
                    width: _hasFocus.value ? 2.0 : 1.0,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 56,
                      child: _buildHeader(theme, colorScheme),
                    ),
                    Expanded(
                      child: PhoneView(
                        serial: widget.device.serial,
                        fit: BoxFit.fill,
                        focusNode: _cardFocusNode,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    final store = getIt<DeviceGroupStore>();
    // Need to observe store to update dots
    return Observer(
      builder: (_) {
        final deviceGroups = store.groups
            .where((g) => g.deviceSerials.contains(widget.device.serial))
            .toList();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.device.connectionType == ConnectionType.tcp
                      ? Icons.wifi_rounded
                      : Icons.usb_rounded,
                  color: colorScheme.onSecondaryContainer,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.device.modelName,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Group Dots
                        if (deviceGroups.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ...deviceGroups.map(
                            (g) => Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Color(g.colorValue),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      widget.device.serial,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: widget.device.status),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: widget.onDisconnect,
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
