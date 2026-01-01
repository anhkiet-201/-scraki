import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import '../../core/di/injection.dart';
import '../widgets/device/device_grid/device_grid.dart';
import '../widgets/device/floating_phone_view/floating_phone_view.dart';
import '../global_stores/device_store.dart';
import '../global_stores/mirroring_store.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DeviceStore _deviceStore;
  late final MirroringStore _mirroringStore;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _deviceStore = getIt<DeviceStore>();
    _mirroringStore = getIt<MirroringStore>();
    _deviceStore.loadDevices();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          _buildNavigationRail(theme),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(theme),
                Expanded(
                  child: Observer(
                    builder: (_) {
                      final futureStatus =
                          _deviceStore.loadDevicesFuture?.status;
                      final errorMessage = _deviceStore.errorMessage;

                      if (futureStatus == FutureStatus.pending &&
                          _deviceStore.devices.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (errorMessage != null &&
                          _deviceStore.devices.isEmpty) {
                        return _buildErrorView(errorMessage);
                      }
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            fit: StackFit.expand,
                            clipBehavior: Clip.none,
                            children: [
                              RefreshIndicator(
                                onRefresh: _deviceStore.loadDevices,
                                child: DeviceGrid(
                                  devices: _deviceStore.devices.toList(),
                                  onDisconnect: (device) {
                                    _deviceStore.disconnect(device.serial);
                                  },
                                ),
                              ),
                              Observer(
                                builder: (_) {
                                  final isVisible =
                                      _mirroringStore.isFloatingVisible;
                                  final serial = _mirroringStore.floatingSerial;

                                  if (!isVisible)
                                    return const SizedBox.shrink();

                                  return FloatingPhoneView(
                                    key: ValueKey('floating_$serial'),
                                    serial: serial!,
                                    parentSize: constraints.biggest,
                                    onClose: () =>
                                        _mirroringStore.toggleFloating(null),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(ThemeData theme) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      extended: false,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Icon(Icons.bolt, color: theme.colorScheme.primary, size: 32),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.devices),
          selectedIcon: Icon(Icons.devices_rounded),
          label: Text('Devices'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.terminal_outlined),
          selectedIcon: Icon(Icons.terminal),
          label: Text('Scripts'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              hintText: 'Search devices...',
              leading: const Icon(Icons.search),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton.filledTonal(
            icon: const Icon(Icons.refresh),
            onPressed: () => _deviceStore.loadDevices(),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.add),
            onPressed: () {},
            tooltip: 'Add Device',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Error: $message',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _deviceStore.loadDevices,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
