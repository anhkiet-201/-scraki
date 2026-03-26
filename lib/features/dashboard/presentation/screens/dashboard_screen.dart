import 'dart:ui';
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
import 'package:scraki/features/settings/presentation/screens/settings_screen.dart';
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
                KeepAlivePage(child: SettingsScreen()),
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
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.5),
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: NavigationRail(
                backgroundColor: Colors.transparent,
                selectedIndex: store.selectedIndex,
                onDestinationSelected: (index) {
                  store.setSelectedIndex(index);
                },
                extended: false,
                labelType: NavigationRailLabelType.none,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.bolt_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                unselectedIconTheme: IconThemeData(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  size: 24,
                ),
                selectedIconTheme: IconThemeData(
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
                indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.devices_outlined),
                    selectedIcon: Icon(Icons.devices_rounded),
                    label: Text('Devices'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.post_add_rounded),
                    selectedIcon: Icon(Icons.post_add_rounded),
                    label: Text('Posters'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.video_library_outlined),
                    selectedIcon: Icon(Icons.video_library_rounded),
                    label: Text('Video Posters'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.terminal_outlined),
                    selectedIcon: Icon(Icons.terminal_rounded),
                    label: Text('Scripts'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: Text('Settings'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(ThemeData theme, DashboardStore dashboardStore) {
    final colorScheme = theme.colorScheme;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(child: DeviceSearchBar(dashboardStore: dashboardStore)),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onPressed: () => deviceManagerStore.loadDevices(),
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.add_rounded,
                tooltip: 'Add Device',
                onPressed: () {},
                color: colorScheme.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 16),
              _buildConnectButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectButton(ThemeData theme) {
    return Observer(
      builder: (_) {
        final isLoading = deviceManagerStore.isLoading;
        final count = deviceManagerStore.connectedBoxCount;
        final colorScheme = theme.colorScheme;

        return Container(
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            boxShadow: [
              BoxShadow(
                color: colorScheme.tertiary.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FilledButton.icon(
            icon: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onTertiary,
                    ),
                  )
                : const Icon(Icons.cast_connected_rounded, size: 18),
            label: Text(
              isLoading ? 'Connecting...' : 'Connect Boxes ($count/96)',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                fontSize: 13,
              ),
            ),
            onPressed: isLoading ? null : () => deviceManagerStore.connectToBox(),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.tertiary,
              foregroundColor: colorScheme.onTertiary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(21),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView(String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.report_problem_rounded,
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: deviceManagerStore.loadDevices,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Try to Refresh',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
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
