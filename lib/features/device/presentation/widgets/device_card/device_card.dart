import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import 'package:scraki/core/widgets/status_badge.dart';
import '../phone_view/phone_view.dart';

/// A card widget that displays information about a device and provides a mirror action.
class DeviceCard extends StatefulWidget {
  final DeviceEntity device;
  final VoidCallback onDisconnect;

  const DeviceCard({super.key, required this.device, required this.onDisconnect});

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> with AutomaticKeepAliveClientMixin {

  // Local UI state using MobX observables
  final Observable<bool> _isHovered = Observable(false);
  final Observable<bool> _hasFocus = Observable(false);
  final FocusNode _cardFocusNode = FocusNode();

  void _setupFocusListener() {
    _cardFocusNode.addListener(() {
      runInAction(() => _hasFocus.value = _cardFocusNode.hasFocus);
    });
  }

  void _handleCardTap(BuildContext context) {
    FocusScope.of(context).requestFocus(_cardFocusNode);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _setupFocusListener();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Observer(
      builder: (_) {
        return MouseRegion(
          onEnter: (_) => runInAction(() => _isHovered.value = true),
          onExit: (_) => runInAction(() => _isHovered.value = false),
          child: GestureDetector(
            onTap: () => _handleCardTap(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.fastOutSlowIn,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (_isHovered.value || _hasFocus.value)
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Card(
                elevation: 0,
                color: _isHovered.value
                    ? colorScheme.surfaceContainerLow
                    : colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _hasFocus.value
                        ? colorScheme.primary
                        : (_isHovered.value
                              ? colorScheme.outline
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.3,
                                )),
                    width: _hasFocus.value ? 2.0 : 1.0,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 56,
                      child: _buildHeader(theme, colorScheme),
                    ),
                    Expanded(
                      child: PhoneView(
                        serial: widget.device.serial,
                        fit: BoxFit.fill,
                        focusNode: _cardFocusNode,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.device.connectionType == ConnectionType.tcp
                  ? Icons.wifi_rounded
                  : Icons.usb_rounded,
              color: colorScheme.onSecondaryContainer,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.modelName,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.device.serial,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          StatusBadge(status: widget.device.status),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: widget.onDisconnect,
            style: IconButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}
