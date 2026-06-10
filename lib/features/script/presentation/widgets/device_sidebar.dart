import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobx/mobx.dart' as mobx;
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/core/stores/device_manager_store.dart';
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import 'package:scraki/features/device/domain/entities/device_group_entity.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
import 'package:scraki/features/script/presentation/stores/terminal_store.dart';
import 'package:scraki/features/script/presentation/widgets/log_line_item.dart'; // For getDeviceColor

class DeviceSidebar extends StatefulWidget {
  final DeviceManagerStore deviceManagerStore;
  final TerminalStore terminalStore;

  const DeviceSidebar({
    super.key,
    required this.deviceManagerStore,
    required this.terminalStore,
  });

  @override
  State<DeviceSidebar> createState() => _DeviceSidebarState();
}

class _DeviceSidebarState extends State<DeviceSidebar> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _groupScrollController = ScrollController();
  String _searchQuery = '';
  int? _lastClickedIndex;
  late final DeviceGroupStore _groupStore;

  @override
  void initState() {
    super.initState();
    _groupStore = inject<DeviceGroupStore>();
    _groupStore.listenToGroups();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupScrollController.dispose();
    super.dispose();
  }

  List<DeviceEntity> _getFilteredDevices() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.deviceManagerStore.devices;
    }

    return widget.deviceManagerStore.devices.where((device) {
      final nickname = _groupStore.getNicknameForDevice(device.serial) ?? '';
      final email = _groupStore.getEmailForDevice(device.serial) ?? '';
      final serial = device.serial;
      final model = device.modelName;

      return model.toLowerCase().contains(query) ||
          serial.toLowerCase().contains(query) ||
          nickname.toLowerCase().contains(query) ||
          email.toLowerCase().contains(query);
    }).toList();
  }

  void _toggleSelectAll(List<DeviceEntity> filtered) {
    if (filtered.isEmpty) return;

    final allSelected = filtered.every(
      (d) => widget.deviceManagerStore.selectedSerials.contains(d.serial),
    );

    mobx.runInAction(() {
      if (allSelected) {
        for (final device in filtered) {
          widget.deviceManagerStore.selectedSerials.remove(device.serial);
        }
      } else {
        for (final device in filtered) {
          widget.deviceManagerStore.selectedSerials.add(device.serial);
        }
      }
    });
  }

  void _handleDeviceTap(
    int index,
    DeviceEntity device,
    List<DeviceEntity> visibleDevices,
  ) {
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    if (isShiftPressed &&
        _lastClickedIndex != null &&
        _lastClickedIndex! < visibleDevices.length) {
      final start = min(_lastClickedIndex!, index);
      final end = max(_lastClickedIndex!, index);

      final firstDevice = visibleDevices[_lastClickedIndex!];
      final isFirstSelected = widget.deviceManagerStore.selectedSerials.contains(
        firstDevice.serial,
      );

      mobx.runInAction(() {
        for (int i = start; i <= end; i++) {
          final currentDevice = visibleDevices[i];
          if (isFirstSelected) {
            widget.deviceManagerStore.selectedSerials.add(currentDevice.serial);
          } else {
            widget.deviceManagerStore.selectedSerials.remove(
              currentDevice.serial,
            );
          }
        }
      });
      setState(() {
        _lastClickedIndex = index;
      });
    } else {
      widget.deviceManagerStore.toggleDeviceSelection(device.serial);
      setState(() {
        _lastClickedIndex = index;
      });
    }
  }

  Map<String, int> _getGroupConnectionCounts(DeviceGroupEntity group) {
    final groupIps = group.deviceSerials.map((s) => s.split(':').first).toSet();
    final connectedInGroup = widget.deviceManagerStore.devices.where((device) {
      final deviceIp = device.serial.split(':').first;
      return groupIps.contains(deviceIp) ||
          group.deviceSerials.contains(device.serial);
    }).toList();

    final selectedCount = connectedInGroup
        .where(
          (d) => widget.deviceManagerStore.selectedSerials.contains(d.serial),
        )
        .length;
    return {
      'selected': selectedCount,
      'total': connectedInGroup.length,
    };
  }

  void _toggleGroupSelection(DeviceGroupEntity group) {
    final groupIps = group.deviceSerials.map((s) => s.split(':').first).toSet();
    final connectedDevicesInGroup = widget.deviceManagerStore.devices
        .where((device) {
          final deviceIp = device.serial.split(':').first;
          return groupIps.contains(deviceIp) ||
              group.deviceSerials.contains(device.serial);
        })
        .toList();

    if (connectedDevicesInGroup.isEmpty) return;

    final selectedConnectedCount = connectedDevicesInGroup
        .where(
          (d) => widget.deviceManagerStore.selectedSerials.contains(d.serial),
        )
        .length;
    final allSelected = selectedConnectedCount == connectedDevicesInGroup.length;

    mobx.runInAction(() {
      if (allSelected) {
        for (final device in connectedDevicesInGroup) {
          widget.deviceManagerStore.selectedSerials.remove(device.serial);
        }
      } else {
        for (final device in connectedDevicesInGroup) {
          widget.deviceManagerStore.selectedSerials.add(device.serial);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Title, Badge, and Compact Toolbar
          Row(
            children: [
              Text(
                'DEVICES',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              Observer(
                builder: (_) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.deviceManagerStore.selectedSerials.length}/${widget.deviceManagerStore.devices.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _buildToolbar(context, theme),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC), // Slate 50
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm thiết bị...',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.cancel_rounded,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
            ),
          ),

          // Group chips scrollable row
          Observer(
            builder: (_) {
              if (_groupStore.groups.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 32,
                    child: ScrollConfiguration(
                      behavior: const MouseDragScrollBehavior(),
                      child: Listener(
                        onPointerSignal: (pointerSignal) {
                          if (pointerSignal is PointerScrollEvent) {
                            final double delta = pointerSignal.scrollDelta.dy;
                            if (delta != 0 && _groupScrollController.hasClients) {
                              final double newOffset =
                                  _groupScrollController.offset + delta;
                              _groupScrollController.jumpTo(
                                newOffset.clamp(
                                  0.0,
                                  _groupScrollController
                                      .position.maxScrollExtent,
                                ),
                              );
                            }
                          }
                        },
                        child: ListView.separated(
                          controller: _groupScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: _groupStore.groups.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final group = _groupStore.groups[index];
                            final groupColor = Color(group.colorValue);

                            return Observer(
                              builder: (_) {
                                final counts = _getGroupConnectionCounts(group);
                                final selectedCount = counts['selected'] ?? 0;
                                final totalCount = counts['total'] ?? 0;
                                final isFullySelected =
                                    totalCount > 0 &&
                                    selectedCount == totalCount;
                                final isPartiallySelected =
                                    totalCount > 0 &&
                                    selectedCount > 0 &&
                                    selectedCount < totalCount;

                                return _buildGroupChip(
                                  group,
                                  groupColor,
                                  selectedCount,
                                  totalCount,
                                  isFullySelected,
                                  isPartiallySelected,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Devices List
          Expanded(
            child: Observer(
              builder: (_) {
                final filtered = _getFilteredDevices();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.devices_other_rounded,
                          color: Colors.grey.shade300,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Không tìm thấy thiết bị phù hợp'
                              : 'Không có thiết bị',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final device = filtered[index];
                    final color = getDeviceColor(device.serial);
                    final deviceGroups = _groupStore.groups.where((g) {
                      final groupIps = g.deviceSerials
                          .map((s) => s.split(':').first)
                          .toSet();
                      final deviceIp = device.serial.split(':').first;
                      return groupIps.contains(deviceIp) ||
                          g.deviceSerials.contains(device.serial);
                    }).toList();

                    return Observer(
                      builder: (context) {
                        final isSelected =
                            widget.deviceManagerStore.selectedSerials.contains(
                              device.serial,
                            );

                        return InkWell(
                          onTap: () => _handleDeviceTap(index, device, filtered),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.05,
                                    )
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.4,
                                      )
                                    : const Color(0xFFF1F5F9), // Slate 100
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Custom Checkbox on the left
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : const Color(0xFFCBD5E1), // Slate 300
                                      width: 1.5,
                                    ),
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),

                                // Colored indicator bar
                                Container(
                                  width: 3,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : color.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Device Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device.modelName,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              fontSize: 11.5,
                                              color: isSelected
                                                  ? theme.colorScheme.primary
                                                  : const Color(0xFF1E293B),
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        device.serial,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontSize: 9.5,
                                              color: isSelected
                                                  ? theme.colorScheme.primary
                                                        .withValues(alpha: 0.7)
                                                  : const Color(0xFF64748B),
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Group indicator dots on the right
                                if (deviceGroups.isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: deviceGroups.map((g) {
                                      return Tooltip(
                                        message: g.name,
                                        child: Container(
                                          margin: const EdgeInsets.only(left: 3),
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: Color(g.colorValue),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
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

  Widget _buildToolbar(BuildContext context, ThemeData theme) {
    return Observer(
      builder: (_) {
        final filtered = _getFilteredDevices();
        final allSelected =
            filtered.isNotEmpty &&
            filtered.every(
              (d) => widget.deviceManagerStore.selectedSerials.contains(
                d.serial,
              ),
            );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Select all / Deselect all
            IconButton(
              icon: Icon(
                allSelected
                    ? Icons.check_box
                    : Icons.check_box_outline_blank_rounded,
                size: 18,
                color: const Color(0xFF64748B),
              ),
              tooltip: allSelected ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              onPressed: () => _toggleSelectAll(filtered),
            ),
            const SizedBox(width: 8),
            // Select Range (Chọn lô)
            IconButton(
              icon: const Icon(
                Icons.tag_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
              tooltip: 'Chọn theo lô IP',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              onPressed: () => _showRangeSelectDialog(context),
            ),
            const SizedBox(width: 8),
            // Refresh
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
              tooltip: 'Tải lại danh sách thiết bị',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              onPressed: () => widget.deviceManagerStore.loadDevices(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupChip(
    DeviceGroupEntity group,
    Color groupColor,
    int selectedCount,
    int totalCount,
    bool isFullySelected,
    bool isPartiallySelected,
  ) {
    // Dynamic styles based on selection state
    Color backgroundColor;
    Border border;
    Color textColor;

    if (isFullySelected) {
      backgroundColor = groupColor.withValues(alpha: 0.15);
      border = Border.all(color: groupColor, width: 1.5);
      textColor = groupColor;
    } else if (isPartiallySelected) {
      backgroundColor = groupColor.withValues(alpha: 0.05);
      border = Border.all(
        color: groupColor.withValues(alpha: 0.5),
        width: 1.5,
      );
      textColor = groupColor;
    } else {
      backgroundColor = const Color(0xFFF1F5F9); // Slate 100
      border = Border.all(color: const Color(0xFFE2E8F0), width: 1); // Slate 200
      textColor = const Color(0xFF475569); // Slate 600
    }

    return InkWell(
      onTap: () => _toggleGroupSelection(group),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: groupColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              group.name,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: (isFullySelected || isPartiallySelected)
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (totalCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '($selectedCount/$totalCount)',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRangeSelectDialog(BuildContext context) {
    final startController = TextEditingController();
    final endController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Chọn thiết bị theo lô IP',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập số thứ tự hoặc số đuôi IP (Ví dụ: 1 đến 50)',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'TỪ',
                      labelStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: endController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'ĐẾN',
                      labelStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'HỦY',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final start = int.tryParse(startController.text);
              final end = int.tryParse(endController.text);
              if (start != null && end != null) {
                widget.terminalStore.selectDevicesByRange(start, end);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'CHỌN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class MouseDragScrollBehavior extends MaterialScrollBehavior {
  const MouseDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
