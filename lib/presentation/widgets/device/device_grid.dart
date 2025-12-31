import 'package:flutter/material.dart';
import 'package:scraki/domain/entities/device_entity.dart';
import 'device_card.dart';

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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other,
              size: 64,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'No devices detected',
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect via USB or TCP to start',
              style: TextStyle(
                color: Colors.white.withOpacity(0.1),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ), // Space for AppBar
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              childAspectRatio: 0.65,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
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
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}
