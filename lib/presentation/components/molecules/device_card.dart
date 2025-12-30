import 'package:flutter/material.dart';
import '../../../domain/entities/device_entity.dart';
import '../atoms/protocol_icon.dart';
import '../atoms/status_badge.dart';
import '../../widgets/phone_view.dart';

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
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ProtocolIcon(
                  isTcp: widget.device.connectionType == ConnectionType.tcp,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.device.modelName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(status: widget.device.status),
              ],
            ),
          ),

          // Video Area (PhoneView)
          Expanded(
            child: Container(
              color: Colors.black,
              child: ClipRect(
                child: _isMirroring
                    ? PhoneView(
                        serial: widget.device.serial,
                        fit: BoxFit.contain,
                      )
                    : const Center(
                        child: Icon(
                          Icons.phonelink_setup,
                          size: 64,
                          color: Colors.white24,
                        ),
                      ),
              ),
            ),
          ),

          // Footer Actions
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isMirroring)
                  IconButton(
                    icon: const Icon(Icons.link_off),
                    onPressed: _toggleMirroring,
                    tooltip: 'Stop Mirroring',
                  ),
                const SizedBox(width: 8),
                if (!_isMirroring)
                ElevatedButton.icon(
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


