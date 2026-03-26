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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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
    // Need to observe both stores to update nicknames and group dots
    return Observer(
      builder: (_) {
        final deviceGroups = _deviceGroupStore.groups
            .where((g) => g.deviceSerials.contains(widget.device.serial))
            .toList();
            
        final modelName = widget.device.modelName;
        final displayName = _nicknameStore.getNickname(
          widget.device.serial,
          modelName,
        );

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
                            displayName,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withValues(alpha: 0.9),
                              fontSize: 13,
                              letterSpacing: 0.2,
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
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Color(g.colorValue),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 1,
                                  ),
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
