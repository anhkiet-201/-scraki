import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/domain/entities/device_entity.dart';
import '../../../../core/di/injection.dart';
import '../../../stores/phone_view_store.dart';
import '../device_card/device_card.dart';

/// A grid layout that displays a list of [DeviceCard]s.
class DeviceGrid extends StatelessWidget {
  final List<DeviceEntity> devices;
  final void Function(DeviceEntity) onDisconnect;

  const DeviceGrid({
    super.key,
    required this.devices,
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

    final store = getIt<PhoneViewStore>();

    return Observer(
      builder: (_) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            const maxItemWidth = 320.0;
            const spacing = 16.0;

            // Calculate dynamic cross-axis count
            final crossAxisCount = (availableWidth / (maxItemWidth + spacing))
                .ceil()
                .clamp(1, 10);
            final itemWidth =
                (availableWidth - (spacing * (crossAxisCount + 1))) /
                crossAxisCount;

            // Use real aspect ratio from mirroring sessions or default to 9:16
            final deviceRatio = store.deviceAspectRatio;

            // Fixed height: Header (~72px) + Footer (~52px) = ~124px
            // itemWidth / contentHeight = deviceRatio  => contentHeight = itemWidth / deviceRatio
            final totalHeight = (itemWidth / deviceRatio) + 124;
            final responsiveRatio = itemWidth / totalHeight;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: true,
                          onSelected: (_) {},
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Online'),
                          selected: false,
                          onSelected: (_) {},
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('USB'),
                          selected: false,
                          onSelected: (_) {},
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('TCP'),
                          selected: false,
                          onSelected: (_) {},
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: spacing),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: responsiveRatio,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final device = devices[index];
                      return DeviceCard(
                        key: ValueKey('card_${device.serial}'),
                        device: device,
                        onDisconnect: () => onDisconnect(device),
                      );
                    }, childCount: devices.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        );
      },
    );
  }
}
