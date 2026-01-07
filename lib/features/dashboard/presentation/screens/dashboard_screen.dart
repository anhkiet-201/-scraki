import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/mixins/device_manager_store_mixin.dart';
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/core/mixins/session_manager_store_mixin.dart';
import 'package:scraki/features/dashboard/presentation/stores/dashboard_store.dart';
import 'package:scraki/features/device/presentation/widgets/device_grid/device_grid.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/floating_phone_view.dart';

class DashboardScreen extends StatelessWidget
    with DeviceManagerStoreMixin, SessionManagerStoreMixin {
  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardStore = inject<DashboardStore>();

    // Ensure devices are loaded when screen is built
    if (deviceManagerStore.devices.isEmpty &&
        deviceManagerStore.loadDevicesFuture == null) {
      deviceManagerStore.loadDevices();
    }

    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          _buildNavigationRail(theme, dashboardStore),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Observer(
              builder: (_) {
                return Column(
                  children: [
                    _buildTopBar(theme),
                    Expanded(
                      child: Observer(
                        builder: (_) {
                          final futureStatus =
                              deviceManagerStore.loadDevicesFuture?.status;
                          final errorMessage = deviceManagerStore.errorMessage;

                          if (futureStatus == FutureStatus.pending &&
                              deviceManagerStore.devices.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (errorMessage != null &&
                              deviceManagerStore.devices.isEmpty) {
                            return _buildErrorView(errorMessage);
                          }
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                fit: StackFit.expand,
                                clipBehavior: Clip.none,
                                children: [
                                  RefreshIndicator(
                                    onRefresh: deviceManagerStore.loadDevices,
                                    child: DeviceGrid(
                                      devices: deviceManagerStore.devices
                                          .toList(),
                                      onDisconnect: (device) {
                                        deviceManagerStore.disconnect(
                                          device.serial,
                                        );
                                      },
                                    ),
                                  ),
                                  Observer(
                                    builder: (_) {
                                      final isVisible =
                                          sessionManagerStore.isFloatingVisible;
                                      final serial =
                                          sessionManagerStore.floatingSerial;

                                      if (!isVisible) {
                                        return const SizedBox.shrink();
                                      }

                                      return FloatingPhoneView(
                                        key: ValueKey('floating_$serial'),
                                        serial: serial!,
                                        parentSize: constraints.biggest,
                                        onClose: () => sessionManagerStore
                                            .toggleFloating(null),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(ThemeData theme, DashboardStore store) {
    return Observer(
      builder: (_) {
        return NavigationRail(
          selectedIndex: store.selectedIndex,
          onDestinationSelected: store.setSelectedIndex,
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
              icon: Icon(Icons.post_add),
              selectedIcon: Icon(Icons.post_add_outlined),
              label: Text('Posters'),
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
      },
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
                theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
              ),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton.filledTonal(
            icon: const Icon(Icons.refresh),
            onPressed: () => deviceManagerStore.loadDevices(),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.add),
            onPressed: () {},
            tooltip: 'Add Device',
          ),
          const SizedBox(width: 8),
          Observer(
            builder: (_) {
              if (deviceManagerStore.isLoading) {
                return const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return IconButton.filled(
                icon: const Icon(Icons.cast_connected),
                onPressed: () => deviceManagerStore.connectToBox(),
                tooltip: 'Connect Box (192.168.x.20)',
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiary,
                  foregroundColor: theme.colorScheme.onTertiary,
                ),
              );
            },
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
            onPressed: deviceManagerStore.loadDevices,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
