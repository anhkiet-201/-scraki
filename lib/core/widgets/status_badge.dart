import 'package:flutter/material.dart';
import '../../features/device/domain/entities/device_entity.dart';

class StatusBadge extends StatelessWidget {
  final DeviceStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case DeviceStatus.connected:
        color = Colors.green;
        text = 'Online';
        break;
      case DeviceStatus.offline:
        color = Colors.grey;
        text = 'Offline';
        break;
      case DeviceStatus.unauthorized:
        color = Colors.red;
        text = 'Unauthorized';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2), // Updated for Flutter 3.27+
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
