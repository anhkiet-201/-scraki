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
  bool _isHovered = false;

  void _toggleMirroring() {
    setState(() {
      _isMirroring = !_isMirroring;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Card(
          elevation: _isHovered || _isMirroring ? 4 : 0,
          surfaceTintColor: colorScheme.surfaceTint,
          shadowColor: colorScheme.shadow.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: _isHovered || _isMirroring
                  ? colorScheme.primary.withOpacity(0.5)
                  : colorScheme.outlineVariant,
              width: _isHovered || _isMirroring ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.device.connectionType == ConnectionType.tcp
                        ? Icons.wifi
                        : Icons.usb,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  widget.device.modelName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  widget.device.serial,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: StatusBadge(status: widget.device.status),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isMirroring
                      ? PhoneView(
                          serial: widget.device.serial,
                          fit: BoxFit.contain,
                        )
                      : Center(
                          child: Icon(
                            Icons.phonelink_setup,
                            size: 40,
                            color: colorScheme.primary.withOpacity(0.15),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_isMirroring)
                      TextButton.icon(
                        onPressed: _toggleMirroring,
                        icon: const Icon(Icons.link_off, size: 18),
                        label: const Text('Stop'),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      )
                    else
                      FilledButton.tonalIcon(
                        onPressed: _toggleMirroring,
                        icon: const Icon(Icons.screen_share, size: 18),
                        label: const Text('Mirror'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
