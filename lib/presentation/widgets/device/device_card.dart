import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scraki/domain/entities/device_entity.dart';
import 'package:scraki/presentation/widgets/common/protocol_icon.dart';
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
    if (!_isMirroring) {
      // Optional: Notify parent if needed when stopped
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(_isHovered ? 0.3 : 0.1),
              width: 1,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(_isHovered ? 0.08 : 0.04),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [_buildHeader(), _buildPreview(), _buildFooter()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: ProtocolIcon(
              isTcp: widget.device.connectionType == ConnectionType.tcp,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.modelName,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.device.serial,
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(status: widget.device.status),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        clipBehavior: Clip.antiAlias,
        child: _isMirroring
            ? PhoneView(serial: widget.device.serial, fit: BoxFit.contain)
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.phonelink_setup,
                      size: 48,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to sync',
                      style: GoogleFonts.outfit(
                        color: Colors.white24,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_isMirroring)
            _ActionButton(
              icon: Icons.link_off,
              label: 'Stop',
              onPressed: _toggleMirroring,
              color: Colors.redAccent,
            )
          else
            _ActionButton(
              icon: Icons.screen_share,
              label: 'Mirror',
              onPressed: _toggleMirroring,
              color: Colors.blueAccent,
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
    );
  }
}
