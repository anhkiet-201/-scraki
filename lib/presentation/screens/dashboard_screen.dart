import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import '../../core/di/injection.dart';
import '../widgets/device/device_grid.dart';
import '../widgets/device/floating_phone_view.dart';
import '../stores/phone_view_store.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final PhoneViewStore _store;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _store = getIt<PhoneViewStore>();
    _store.loadDevices();
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
                      final futureStatus = _store.loadDevicesFuture?.status;
                      final errorMessage = _store.errorMessage;

                      if (futureStatus == FutureStatus.pending &&
                          _store.devices.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (errorMessage != null && _store.devices.isEmpty) {
                        return _buildErrorView(errorMessage);
                      }

                      return Stack(
                        children: [
                          RefreshIndicator(
                            onRefresh: _store.loadDevices,
                            child: DeviceGrid(
                              devices: _store.devices.toList(),
                              onDisconnect: (device) {
                                _store.disconnect(device.serial);
                              },
                            ),
                          ),
                          if (_store.isFloatingVisible)
                            FloatingPhoneView(
                              key: ValueKey(
                                'floating_${_store.floatingSerial}',
                              ),
                              serial: _store.floatingSerial!,
                              onClose: () => _store.toggleFloating(null),
                            ),
                        ],
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
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              ),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton.filledTonal(
            icon: const Icon(Icons.refresh),
            onPressed: () => _store.loadDevices(),
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
            onPressed: _store.loadDevices,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
