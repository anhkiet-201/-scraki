import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/config/settings_config_provider.dart';
import 'package:scraki/core/mixins/device_manager_store_mixin.dart';
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/core/mixins/session_manager_store_mixin.dart';
import 'package:scraki/core/mixins/app_auth_store_mixin.dart';
import 'package:scraki/core/widgets/mesh_background.dart';
import 'package:scraki/core/widgets/no_permission_overlay.dart';
import 'package:scraki/features/dashboard/presentation/screens/widgets/device_search_bar.dart';
import 'package:scraki/features/dashboard/presentation/screens/widgets/group_horizontal_selector.dart';
import 'package:scraki/features/dashboard/presentation/stores/dashboard_store.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
import 'package:scraki/features/device/presentation/widgets/device_grid/device_grid.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/floating_phone_view.dart';
import 'package:scraki/features/poster/presentation/screens/poster_creator_screen.dart';
import 'package:scraki/features/script/presentation/screens/script_screen.dart';
import 'package:scraki/features/settings/presentation/screens/settings_screen.dart';
import 'package:scraki/features/tiktok_seeding/presentation/widgets/tiktok_batch_seeding_dialog.dart';
import 'package:scraki/features/video_poster/presentation/pages/video_poster_playground_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with DeviceManagerStoreMixin, SessionManagerStoreMixin, AppAuthStoreMixin {
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

    // Show error snackbar when error happens but list is not empty
    _errorDisposer = reaction((_) => deviceManagerStore.errorMessage, (error) {
      if (error != null && deviceManagerStore.devices.isNotEmpty) {
        if (!mounted) return;
        final localTheme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: localTheme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  ReactionDisposer? _errorDisposer;

  @override
  void dispose() {
    _selectionDisposer?.call();
    _errorDisposer?.call();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? Colors.white : theme.scaffoldBackgroundColor,
      body: MeshBackground(
        child: Row(
          children: [
            _buildCustomSidebar(theme, _dashboardStore),
            Expanded(
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: isLight ? 0.9 : 0.4),
                      borderRadius: BorderRadius.circular(24),
                      border: null,
                    ),
                    child: Observer(
                      builder: (_) {
                        final hasPermission = appAuthStore.isAuthenticated;
                        return PageView(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            KeepAlivePage(
                              child: _buildDevicesContent(context, _dashboardStore),
                            ),
                            KeepAlivePage(
                              child: NoPermissionOverlay(
                                hasPermission: hasPermission,
                                child: const PosterCreatorScreen(),
                              ),
                            ),
                            KeepAlivePage(
                              child: NoPermissionOverlay(
                                hasPermission: hasPermission,
                                child: const VideoPosterPlaygroundPage(),
                              ),
                            ),
                            KeepAlivePage(
                              child: NoPermissionOverlay(
                                hasPermission: hasPermission,
                                child: const ScriptScreen(),
                              ),
                            ),
                            SettingsScreen(),
                          ],
                        );
                      }
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildCustomSidebar(ThemeData theme, DashboardStore store) {
    final isLight = theme.brightness == Brightness.light;
    return Observer(
      builder: (_) {
        return Container(
          width: 80, // Fixed compact width
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              // Compact Header
              Hero(
                tag: 'app_logo',
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: isLight ? 0.2 : 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // Compact Menu Items
              _buildSidebarItem(
                index: 0,
                icon: Icons.devices_rounded,
                label: 'Devices',
                store: store,
                theme: theme,
              ),
              _buildSidebarItem(
                index: 1,
                icon: Icons.post_add_rounded,
                label: 'Posters',
                store: store,
                theme: theme,
              ),
              _buildSidebarItem(
                index: 2,
                icon: Icons.video_library_rounded,
                label: 'Video Library',
                store: store,
                theme: theme,
              ),
              _buildSidebarItem(
                index: 3,
                icon: Icons.terminal_rounded,
                label: 'Scripts',
                store: store,
                theme: theme,
              ),
              const Spacer(),
              _buildSidebarItem(
                index: 4,
                icon: Icons.settings_rounded,
                label: 'Settings',
                store: store,
                theme: theme,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required String label,
    required DashboardStore store,
    required ThemeData theme,
  }) {
    final isSelected = store.selectedIndex == index;
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => store.setSelectedIndex(index),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.8),
                          colorScheme.primary.withValues(alpha: 0.4),
                        ],
                      )
                    : null,
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : (isLight ? const Color(0xFF64748B) : colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, DashboardStore dashboardStore) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      decoration: BoxDecoration(
        border: null,
      ),
      child: Row(
        children: [
          Expanded(child: DeviceSearchBar(dashboardStore: dashboardStore)),
          const SizedBox(width: 16),
          _buildActionButton(
            icon: Icons.playlist_add_circle_rounded,
            tooltip: 'Batch Seeding',
            onPressed: () => TikTokBatchSeedingDialog.show(context),
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onPressed: () => deviceManagerStore.loadDevices(),
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.add_rounded,
            tooltip: 'Add Device',
            onPressed: () {},
            color: colorScheme.primary,
          ),
          const SizedBox(width: 16),
          _buildConnectButton(theme),
        ],
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
        final maxDevices = inject<SettingsConfigProvider>().maxDevices;
        final colorScheme = theme.colorScheme;
        final isLight = theme.brightness == Brightness.light;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isLoading
                  ? [
                      colorScheme.surfaceContainerHighest,
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                    ]
                  : [
                      colorScheme.primary,
                      colorScheme.tertiary,
                    ],
            ),
            boxShadow: [
              if (!isLoading) ...[
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: isLight ? 0.25 : 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: colorScheme.tertiary.withValues(alpha: isLight ? 0.2 : 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : () => deviceManagerStore.connectToBox(),
              borderRadius: BorderRadius.circular(22),
              splashColor: Colors.white.withValues(alpha: 0.1),
              highlightColor: Colors.white.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: isLoading
                      ? Row(
                          key: const ValueKey('loading'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Connecting...',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('idle'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cast_connected_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Connect Boxes ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '($count/$maxDevices)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
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
