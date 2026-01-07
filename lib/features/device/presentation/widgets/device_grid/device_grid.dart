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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No devices detected',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect via USB or TCP to start',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
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
                availableWidth - 48; // Padding horizontal 24 * 2

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: devices.map((device) {
                  final isVisible =
                      visibleSerials == null ||
                      visibleSerials!.contains(device.serial);

                  return Offstage(
                    offstage: !isVisible,
                    child: SizedBox(
                      width: isVisible ? itemWidth : 0.01,
                      height: isVisible ? totalHeight : 0.01,
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
