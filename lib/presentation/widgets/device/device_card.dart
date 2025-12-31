import 'package:flutter/material.dart';
import 'package:scraki/domain/entities/device_entity.dart';
import 'package:scraki/presentation/widgets/common/status_badge.dart';
import 'phone_view.dart';

/// A card widget that displays information about a device and provides a mirror action.
class DeviceCard extends StatefulWidget {
  final DeviceEntity device;
  final VoidCallback onDisconnect;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onDisconnect,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool _isMirroring = false;

  void _toggleMirroring() {
    setState(() {
      _isMirroring = !_isMirroring;
    });
    if (!_isMirroring) {
      // Optional: Notify parent if needed when stopped
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: Icon(
              widget.device.connectionType == ConnectionType.tcp
                  ? Icons.wifi
                  : Icons.usb,
              color: colorScheme.primary,
            ),
            title: Text(
              widget.device.modelName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              widget.device.serial,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            trailing: StatusBadge(status: widget.device.status),
          ),
          Expanded(
            child: Container(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              child: _isMirroring
                  ? PhoneView(serial: widget.device.serial, fit: BoxFit.contain)
                  : Center(
                      child: Icon(
                        Icons.phonelink_setup,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isMirroring)
                  TextButton.icon(
                    onPressed: _toggleMirroring,
                    icon: const Icon(Icons.link_off),
                    label: const Text('Stop'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: _toggleMirroring,
                    icon: const Icon(Icons.screen_share),
                    label: const Text('Mirror'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
