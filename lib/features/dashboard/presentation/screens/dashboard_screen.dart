import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/mixins/device_manager_store_mixin.dart';
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/core/mixins/session_manager_store_mixin.dart';
import 'package:scraki/features/dashboard/presentation/screens/widgets/device_search_bar.dart';
import 'package:scraki/features/dashboard/presentation/screens/widgets/group_horizontal_selector.dart';
import 'package:scraki/features/dashboard/presentation/stores/dashboard_store.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
import 'package:scraki/features/device/presentation/widgets/device_grid/device_grid.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/floating_phone_view.dart';
import 'package:scraki/features/poster/presentation/screens/poster_creator_screen.dart';
import 'package:scraki/features/video_poster/presentation/pages/video_poster_playground_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with DeviceManagerStoreMixin, SessionManagerStoreMixin {
  late final PageController _pageController;
  late final DashboardStore _dashboardStore;
  ReactionDisposer? _selectionDisposer;

  @override
  void initState() {
    super.initState();
    _dashboardStore = inject<DashboardStore>();
    _pageController = PageController(
      initialPage: _dashboardStore.selectedIndex,
    );

    // Sync store index with page controller
    _selectionDisposer = reaction((_) => _dashboardStore.selectedIndex, (
      index,
    ) {
      _pageController.jumpToPage(index);
    });

    // Ensure devices are loaded when screen is built
    if (deviceManagerStore.devices.isEmpty &&
        deviceManagerStore.loadDevicesFuture == null) {
      deviceManagerStore.loadDevices();
    }
  }

  @override
  void dispose() {
    _selectionDisposer?.call();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          _buildNavigationRail(theme, _dashboardStore),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: PageView(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                KeepAlivePage(
                  child: _buildDevicesContent(context, _dashboardStore),
                ),
                const KeepAlivePage(child: PosterCreatorScreen()),
                KeepAlivePage(child: VideoPosterPlaygroundPage()),
                KeepAlivePage(child: _buildComingSoon(context, 'Scripts')),
                KeepAlivePage(child: _buildComingSoon(context, 'Settings')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesContent(
    BuildContext context,
    DashboardStore dashboardStore,
  ) {
    final deviceGroupStore = inject<DeviceGroupStore>();
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildTopBar(theme, dashboardStore),
        const GroupHorizontalSelector(),
        Expanded(
          child: Observer(
            builder: (_) {
              final futureStatus = deviceManagerStore.loadDevicesFuture?.status;
              final errorMessage = deviceManagerStore.errorMessage;

              if (futureStatus == FutureStatus.pending &&
                  deviceManagerStore.devices.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (errorMessage != null && deviceManagerStore.devices.isEmpty) {
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
                        child: Observer(
                          builder: (_) {
                            return DeviceGrid(
                              devices: deviceManagerStore.devices
                                  .toList(), // Pass full list
                              visibleSerials: deviceGroupStore.visibleSerials,
                              onDisconnect: (device) {
                                deviceManagerStore.disconnect(device.serial);
                              },
                            );
                          },
                        ),
                      ),
                      Observer(
                        builder: (_) {
                          final isVisible =
                              sessionManagerStore.isFloatingVisible;
                          final serial = sessionManagerStore.floatingSerial;

                          if (!isVisible) {
                            return const SizedBox.shrink();
                          }

                          return FloatingPhoneView(
                            key: ValueKey('floating_$serial'),
                            serial: serial!,
                            parentSize: constraints.biggest,
                            onClose: () =>
                                sessionManagerStore.toggleFloating(null),
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
  }

  Widget _buildComingSoon(BuildContext context, String featureName) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            featureName,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
          onDestinationSelected: (index) {
            store.setSelectedIndex(index);
            // PageController jump is handled by reaction
          },
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
              icon: Icon(Icons.video_library_outlined),
              selectedIcon: Icon(Icons.video_library),
              label: Text('Video Posters'),
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

  Widget _buildTopBar(ThemeData theme, DashboardStore dashboardStore) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Expanded(child: DeviceSearchBar(dashboardStore: dashboardStore)),
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
              final isLoading = deviceManagerStore.isLoading;
              final count = deviceManagerStore.connectedBoxCount;

              return Container(
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  icon: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onTertiary,
                          ),
                        )
                      : const Icon(Icons.cast_connected, size: 20),
                  label: Text(
                    isLoading ? 'Connecting...' : 'Connect Boxes ($count/96)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: isLoading
                      ? null
                      : () => deviceManagerStore.connectToBox(),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.tertiary,
                    foregroundColor: theme.colorScheme.onTertiary,
                    disabledBackgroundColor: theme.colorScheme.tertiary
                        .withValues(alpha: 0.8),
                    disabledForegroundColor: theme.colorScheme.onTertiary
                        .withValues(alpha: 0.8),
                    elevation: 0, // Handled by Container shadow
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
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

class KeepAlivePage extends StatefulWidget {
  final Widget child;

  const KeepAlivePage({super.key, required this.child});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
