import 'package:flutter/material.dart';
import 'package:scraki/domain/entities/device_entity.dart';
import 'package:scraki/presentation/widgets/common/status_badge.dart';
import '../phone_view/phone_view.dart';

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
  bool _hasFocus = false;
  final FocusNode _cardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _cardFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _hasFocus = _cardFocusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _cardFocusNode.removeListener(_onFocusChange);
    _cardFocusNode.dispose();
    super.dispose();
  }

  void _handleCardTap() {
    // Request focus when card is tapped
    FocusScope.of(context).requestFocus(_cardFocusNode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _handleCardTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Card(
            elevation: _isHovered || _isMirroring ? 4 : 0,
            surfaceTintColor: colorScheme.surfaceTint,
            shadowColor: colorScheme.shadow.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: _hasFocus
                    ? colorScheme.primary
                    : (_isHovered || _isMirroring
                          ? colorScheme.primary.withOpacity(0.5)
                          : colorScheme.outlineVariant),
                width: _hasFocus ? 3 : (_isHovered || _isMirroring ? 2 : 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: Container(
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
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: PhoneView(
                      serial: widget.device.serial,
                      fit: BoxFit.contain,
                      focusNode: _cardFocusNode,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
