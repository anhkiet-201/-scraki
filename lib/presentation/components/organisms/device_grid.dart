import 'package:flutter/material.dart';
import '../../../domain/entities/device_entity.dart';
import '../molecules/device_card.dart';

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
      return const Center(
        child: Text('No devices connected. Connect via USB or TCP.'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            childAspectRatio: 0.6, // Taller cards as requested
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            return DeviceCard(
              device: device,
              onDisconnect: () => onDisconnect(device),
            );
          },
        );
      },
    );
  }
}
