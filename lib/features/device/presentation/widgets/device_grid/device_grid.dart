import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/mixins/session_manager_store_mixin.dart';
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
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.devices_rounded,
                  size: 64,
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No devices detected',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Connect your devices via USB or TCP to get started. Make sure ADB is enabled.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  height: 1.5,
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
            const maxItemWidth = 320.0;
            const spacing = 16.0;

            final contentWidth =
                availableWidth - 32; // Balanced padding for fixed 80dp sidebar

            final crossAxisCount =
                ((contentWidth + spacing) / (maxItemWidth + spacing))
                    .ceil()
                    .clamp(1, 10);

            // Wrap only puts spacing BETWEEN items (count - 1)
            final itemWidth =
                (contentWidth - ((crossAxisCount - 1) * spacing)) /
                crossAxisCount;

            final totalHeight = (itemWidth / deviceRatio) + 56;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: devices.map((device) {
                  final isVisible =
                      visibleSerials == null ||
                      visibleSerials!.contains(device.serial);

                  return Offstage(
                    offstage: !isVisible,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 400),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: SizedBox(
                              width: isVisible ? itemWidth : 0.01,
                              height: isVisible ? totalHeight : 0.01,
                              child: DeviceCard(
                                key: ValueKey('card_${device.serial}'),
                                device: device,
                                onDisconnect: () => onDisconnect(device),
                              ),
                            ),
                          ),
                        );
                      },
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
