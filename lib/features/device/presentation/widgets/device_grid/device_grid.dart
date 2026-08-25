import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/constants/ui_constants.dart';
import 'package:scraki/core/mixins/session_manager_store_mixin.dart';
import 'package:scraki/core/widgets/box_card.dart';
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import 'package:scraki/features/device/presentation/widgets/device_card/device_card.dart';

/// A grid layout that displays a list of [DeviceCard]s.
class DeviceGrid extends StatelessWidget with SessionManagerStoreMixin {
  final List<DeviceEntity> devices;
  final Set<String>? visibleSerials;
  final void Function(DeviceEntity) onDisconnect;

  const DeviceGrid({
    super.key,
    required this.devices,
    this.visibleSerials,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      final theme = Theme.of(context);
      return Center(
        child: BoxCard(
          width: 420,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Layered Icon with soft glow
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.15),
                          colorScheme.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.devices_other_rounded,
                      size: 56,
                      color: colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'NO DEVICES DETECTED',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: colorScheme.onSurface.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Connect your devices via USB or TCP to get started. Ensure ADB debugging is enabled in the developer options.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  height: 1.6,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Observer(
      builder: (_) {
        final deviceRatio = sessionManagerStore.deviceAspectRatio;
        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            const maxItemWidth = 300.0;
            const spacing = 20.0;

            final contentWidth = availableWidth - 48; // Sidebar + Margins

            final crossAxisCount =
                ((contentWidth + spacing) / (maxItemWidth + spacing))
                    .ceil()
                    .clamp(1, 10);

            final itemWidth =
                (contentWidth - ((crossAxisCount - 1) * spacing)) /
                crossAxisCount;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: devices.map((device) {
                  final isVisible =
                      visibleSerials == null ||
                      visibleSerials!.contains(device.serial);

                  final session = sessionManagerStore
                          .activeSessions['${device.serial}_grid'] ??
                      sessionManagerStore.activeSessions[device.serial];

                  final ratio = (session != null &&
                          session.width > 0 &&
                          session.height > 0)
                      ? (session.width / session.height)
                      : deviceRatio;

                  final cardHeight = (itemWidth / ratio) +
                      52 +
                      UIConstants.gridNavigationBarHeight;

                  return Offstage(
                    key: ValueKey('grid_item_${device.serial}'),
                    offstage: !isVisible,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: isVisible ? itemWidth : 0.01,
                      height: isVisible ? cardHeight : 0.01,
                      child: DeviceCard(
                        key: ValueKey('card_${device.serial}'),
                        device: device,
                        onDisconnect: () => onDisconnect(device),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}
