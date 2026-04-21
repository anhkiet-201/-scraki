import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/core/mixins/device_manager_store_mixin.dart';
import 'package:scraki/core/widgets/box_card.dart';
import 'package:scraki/features/tiktok_seeding/presentation/stores/tiktok_seeding_store.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';

class TikTokBatchSeedingDialog extends StatefulWidget {
  const TikTokBatchSeedingDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const TikTokBatchSeedingDialog(),
    );
  }

  @override
  State<TikTokBatchSeedingDialog> createState() => _TikTokBatchSeedingDialogState();
}

class _TikTokBatchSeedingDialogState extends State<TikTokBatchSeedingDialog>
    with DeviceManagerStoreMixin, SingleTickerProviderStateMixin {
  late final TikTokSeedingStore _store;
  late final DeviceGroupStore _groupStore;
  late final TextEditingController _inputController;
  late final TabController _tabController;
  final Set<String> _selectedSerials = {};
  
  // Selection Mode: true = Chọn theo Nhóm, false = Chọn lẻ
  bool _isGroupMode = true;

  @override
  void initState() {
    super.initState();
    _store = inject<TikTokSeedingStore>();
    _groupStore = inject<DeviceGroupStore>();
    _inputController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update footer buttons
    });
    
    _initData();
  }

  Future<void> _initData() async {
    await _store.init();
    _inputController.text = _store.bulkInput;
    // Default select all connected devices
    setState(() {
      _selectedSerials.addAll(deviceManagerStore.devices.map((d) => d.serial.trim()));
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
        margin: const EdgeInsets.all(24),
        child: BoxCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme),
              _buildTabBar(theme),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContentTab(theme),
                    _buildSelectionTab(theme),
                  ],
                ),
              ),
              const Divider(height: 1),
              _buildActions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 12, 10),
      child: Row(
        children: [
          Icon(
            Icons.playlist_add_circle_rounded,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Batch Seeding TikTok',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        tabs: const [
          Tab(text: '1. Nội dung', icon: Icon(Icons.edit_note_rounded, size: 20)),
          Tab(text: '2. Thiết bị', icon: Icon(Icons.devices_rounded, size: 20)),
        ],
      ),
    );
  }

  // --- TAB 1: CONTENT ---
  Widget _buildContentTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keywords / Links',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mỗi nội dung trên một dòng. Hệ thống sẽ chọn ngẫu nhiên cho từng thiết bị.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _inputController,
            maxLines: 12,
            onChanged: _store.setBulkInput,
            decoration: InputDecoration(
              hintText: 'VD:\nReview phim hay\nhttps://vt.tiktok.com/...\n@username video 1',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hệ thống tự động lưu lại danh sách này cho các lần seeding sau.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: SELECTION ---
  Widget _buildSelectionTab(ThemeData theme) {
    return Column(
      children: [
        _buildSelectionModeToggle(theme),
        const Divider(height: 1),
        Expanded(
          child: _isGroupMode 
              ? _buildGroupList(theme) 
              : _buildDeviceList(theme),
        ),
      ],
    );
  }

  Widget _buildSelectionModeToggle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        children: [
           Text(
            'Chế độ chọn:',
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildToggleItem(
                  label: 'Theo Nhóm',
                  isActive: _isGroupMode,
                  onTap: () => setState(() => _isGroupMode = true),
                  theme: theme,
                ),
                _buildToggleItem(
                  label: 'Lẻ từng máy',
                  isActive: !_isGroupMode,
                  onTap: () => setState(() => _isGroupMode = false),
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupList(ThemeData theme) {
    return Observer(
      builder: (_) {
        final groups = _groupStore.groups;
        if (groups.isEmpty) {
          return Center(
            child: Text(
              'Không có nhóm thiết bị nào.',
              style: theme.textTheme.bodyMedium,
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final onlineSerials = deviceManagerStore.devices.map((d) => d.serial.trim()).toSet();
            final groupOnlineSerials = group.deviceSerials
                .map((s) => s.trim())
                .where((s) => onlineSerials.contains(s))
                .toSet();
            
            final isFullSelected = groupOnlineSerials.isNotEmpty && 
                              groupOnlineSerials.every((s) => _selectedSerials.contains(s));
            final isPartialSelected = groupOnlineSerials.any((s) => _selectedSerials.contains(s)) && !isFullSelected;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isFullSelected ? theme.colorScheme.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: CheckboxListTile(
                value: isFullSelected,
                tristate: isPartialSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedSerials.addAll(groupOnlineSerials);
                    } else {
                      _selectedSerials.removeAll(groupOnlineSerials);
                    }
                  });
                },
                title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${group.deviceSerials.length} thiết bị'),
                secondary: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(group.colorValue),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDeviceList(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Observer(builder: (_) => Text(
                'Thiết bị lẻ (${_selectedSerials.length}/${deviceManagerStore.devices.length})',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              )),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedSerials.length == deviceManagerStore.devices.length) {
                      _selectedSerials.clear();
                    } else {
                      _selectedSerials.addAll(deviceManagerStore.devices.map((d) => d.serial.trim()));
                    }
                  });
                },
                child: const Text('Chọn tất cả', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Observer(
            builder: (_) {
              final devices = deviceManagerStore.devices;
              if (devices.isEmpty) {
                return const Center(child: Text('Không có thiết bị đang kết nối'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final serial = device.serial.trim();
                  final isSelected = _selectedSerials.contains(serial);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedSerials.add(serial);
                        } else {
                          _selectedSerials.remove(serial);
                        }
                      });
                    },
                    title: Text(device.modelName, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(device.serial, style: const TextStyle(fontSize: 12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- ACTIONS ---
  Widget _buildActions(ThemeData theme) {
    final isContentTab = _tabController.index == 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Observer(
        builder: (_) {
          final isProcessing = _store.isProcessing;
          
          if (isContentTab) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () => _tabController.animateTo(1),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Tiếp tục (Chọn máy)'),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              if (_selectedSerials.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Đã chọn ${_selectedSerials.length} máy',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: isProcessing ? null : () => _tabController.animateTo(0),
                child: const Text('Quay lại'),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: isProcessing || _selectedSerials.isEmpty 
                      ? null 
                      : () async {
                          await _store.runBatchSeeding(_selectedSerials.toList());
                          if (_store.errorMessage == null && mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã đẩy lệnh seeding thành công!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.of(context).pop();
                          }
                        },
                  icon: isProcessing 
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.rocket_launch_rounded),
                  label: Text(isProcessing ? 'Đang gửi...' : 'Bắt đầu Seeding'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
