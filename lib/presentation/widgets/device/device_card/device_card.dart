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

class _DeviceCardState extends State<DeviceCard>
    with AutomaticKeepAliveClientMixin {
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
    super.build(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _handleCardTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              if (_isHovered || _hasFocus)
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
            ],
          ),
          child: Card(
            elevation: 0,
            color: _isHovered
                ? colorScheme.surfaceContainerLow
                : colorScheme.surfaceContainerLowest,
            surfaceTintColor: colorScheme.surfaceTint,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: _hasFocus
                    ? colorScheme.primary
                    : (_isHovered
                          ? colorScheme.outline
                          : colorScheme.outlineVariant.withValues(alpha: 0.5)),
                width: _hasFocus ? 2.5 : (_isHovered ? 1.5 : 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(theme, colorScheme),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: _isHovered ? 0.4 : 0.25,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: PhoneView(
                        serial: widget.device.serial,
                        fit: widget.device.status == DeviceStatus.connected
                            ? BoxFit.contain
                            : BoxFit.cover,
                        focusNode: _cardFocusNode,
                      ),
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

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          widget.device.connectionType == ConnectionType.tcp
              ? Icons.wifi_rounded
              : Icons.usb_rounded,
          color: colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        widget.device.modelName,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        widget.device.serial,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: 10,
          fontFamily: 'Monospace',
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusBadge(status: widget.device.status),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: widget.onDisconnect,
            tooltip: 'Disconnect Device',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              hoverColor: colorScheme.errorContainer.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
