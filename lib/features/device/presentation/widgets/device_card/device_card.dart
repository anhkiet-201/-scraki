import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/core/widgets/status_badge.dart';
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
import 'package:scraki/features/device/presentation/stores/device_nickname_store.dart';
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
  
  // Stores and controllers
  final _nicknameController = TextEditingController();
  final _deviceGroupStore = getIt<DeviceGroupStore>();
  final _nicknameStore = getIt<DeviceNicknameStore>();

  @override
  void initState() {
    super.initState();
    _setupFocusListener();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _cardFocusNode.dispose();
    super.dispose();
  }

  void _setupFocusListener() {
    _cardFocusNode.addListener(() {
      runInAction(() => _hasFocus.value = _cardFocusNode.hasFocus);
    });
  }

  void _handleCardTap(BuildContext context) {
    FocusScope.of(context).requestFocus(_cardFocusNode);
  }

  void _handleRename(BuildContext context) {
    final currentNickname = _nicknameStore.getNickname(
      widget.device.serial,
      widget.device.modelName,
    );
    _nicknameController.text = currentNickname;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên thiết bị'),
        content: TextField(
          controller: _nicknameController,
          decoration: const InputDecoration(
            labelText: 'Tên gợi nhớ',
            hintText: 'Nhập tên thiết bị...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final newName = _nicknameController.text.trim();
              _nicknameStore.saveNickname(widget.device.serial, newName);
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final allGroups = _deviceGroupStore.groups;
    final deviceGroups = allGroups
        .where((g) => g.deviceSerials.contains(widget.device.serial))
        .toList();
    final availableGroups = allGroups
        .where((g) => !g.deviceSerials.contains(widget.device.serial))
        .toList();

    BoxCardMenu.show<void>(
      context: context,
      position: position,
      width: 240,
      items: [
        BoxCardMenuItem(
          icon: const Icon(Icons.drive_file_rename_outline_rounded),
          label: const Text('Đổi tên thiết bị'),
          onTap: () => _handleRename(context),
        ),
        if (availableGroups.isNotEmpty) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          const BoxCardMenuHeader(
            title: 'Add to Group',
            icon: Icons.group_add_rounded,
          ),
          ...availableGroups.map(
            (group) => BoxCardMenuItem(
              icon: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Color(group.colorValue).withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
              ),
              label: Text(group.name),
              onTap: () =>
                  _deviceGroupStore.addDeviceToGroup(group.id, widget.device.serial),
            ),
          ),
        ],
        if (deviceGroups.isNotEmpty) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          const BoxCardMenuHeader(
            title: 'Remove from Group',
            icon: Icons.group_remove_rounded,
          ),
          ...deviceGroups.map(
            (group) => BoxCardMenuItem(
              icon: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Color(group.colorValue).withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
              ),
              label: Text(group.name),
              onTap: () =>
                  _deviceGroupStore.removeDeviceFromGroup(group.id, widget.device.serial),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: _isHovered.value
                        ? colorScheme.surface.withValues(alpha: 0.8)
                        : colorScheme.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _hasFocus.value
                          ? colorScheme.primary.withValues(alpha: 0.5)
                          : colorScheme.outlineVariant.withValues(alpha: 0.2),
                      width: _hasFocus.value ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      if (_isHovered.value || _hasFocus.value)
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.05),
                          blurRadius: 16,
                          spreadRadius: -4,
                        ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 52,
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
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Observer(
      builder: (_) {
        final deviceGroups = _deviceGroupStore.groups
            .where((g) => g.deviceSerials.contains(widget.device.serial))
            .toList();

        final displayName = _nicknameStore.getNickname(
          widget.device.serial,
          widget.device.modelName,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              _ConnectionIcon(
                connectionType: widget.device.connectionType,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DeviceIdentity(
                  displayName: displayName,
                  serial: widget.device.serial,
                  deviceGroups: deviceGroups,
                  theme: theme,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 4),
              StatusBadge(status: widget.device.status),
              const SizedBox(width: 2),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: widget.onDisconnect,
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  hoverColor: colorScheme.errorContainer.withValues(alpha: 0.1),
                ),
                tooltip: 'Ngắt kết nối',
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

/// [Rule #18] Component hóa Icon kết nối
class _ConnectionIcon extends StatelessWidget {
  final ConnectionType connectionType;
  final ColorScheme colorScheme;

  const _ConnectionIcon({
    required this.connectionType,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isTcp = connectionType == ConnectionType.tcp;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          isTcp ? Icons.wifi_rounded : Icons.usb_rounded,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          size: 16,
        ),
      ),
    );
  }
}

/// [Rule #18] Component hóa Thông tin thiết bị
class _DeviceIdentity extends StatelessWidget {
  final String displayName;
  final String serial;
  final List<dynamic> deviceGroups;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _DeviceIdentity({
    required this.displayName,
    required this.serial,
    required this.deviceGroups,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                displayName,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  letterSpacing: -0.2,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (deviceGroups.isNotEmpty) ...[
              const SizedBox(width: 6),
              _GroupIndicatorList(groups: deviceGroups, colorScheme: colorScheme),
            ],
          ],
        ),
        Text(
          serial,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// [Rule #18] Component hóa Chấm màu Group
class _GroupIndicatorList extends StatelessWidget {
  final List<dynamic> groups;
  final ColorScheme colorScheme;

  const _GroupIndicatorList({
    required this.groups,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: groups.map((g) {
        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
            color: Color(g.colorValue as int),
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.surface.withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(g.colorValue as int).withValues(alpha: 0.2),
                  blurRadius: 2,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
