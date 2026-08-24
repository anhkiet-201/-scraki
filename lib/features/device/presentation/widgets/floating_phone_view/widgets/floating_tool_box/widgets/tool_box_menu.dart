import 'package:flutter/material.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/floating_tool_box_card.dart';

class ToolBoxMenu extends StatelessWidget {
  final bool isCollapsed;
  final double height;
  final VoidCallback onPowerTap;
  final VoidCallback onPosterTap;
  final VoidCallback onEmailTap;
  final VoidCallback onInboxTap;
  final VoidCallback onProfileTap;
  final VoidCallback onAuthTap;
  final VoidCallback onSeedingTap;

  const ToolBoxMenu({
    super.key,
    required this.isCollapsed,
    required this.height,
    required this.onPowerTap,
    required this.onPosterTap,
    required this.onEmailTap,
    required this.onInboxTap,
    required this.onProfileTap,
    required this.onAuthTap,
    required this.onSeedingTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return FloatingToolBoxCard(
      width: isCollapsed ? 56 : 100,
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
     
            _buildExpandedButton(
                  colorScheme: colorScheme,
                  icon: Icons.power_settings_new_rounded,
                  label: 'Power',
                  onTap: onPowerTap,
                  isError: true,
                ),
          const SizedBox(height: 12),
           _buildExpandedButton(
                  colorScheme: colorScheme,
                  icon: Icons.art_track_rounded,
                  label: 'Poster',
                  onTap: onPosterTap,
                  isError: false,
                ),
          const SizedBox(height: 12),
           _buildExpandedButton(
                  colorScheme: colorScheme,
                  icon: Icons.mark_email_read_outlined,
                  label: 'Email',
                  onTap: onEmailTap,
                  isError: false,
                ),
          const SizedBox(height: 12),
          _buildExpandedButton(
                  colorScheme: colorScheme,
                  icon: Icons.inbox_rounded,
                  label: 'Inbox',
                  onTap: onInboxTap,
                  isError: false,
                ),
          const SizedBox(height: 12),
          _buildExpandedButton(
                  colorScheme: colorScheme,
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  onTap: onProfileTap,
                  isError: false,
                ),

                //Auth
          const SizedBox(height: 12),
          _buildExpandedButton(
            colorScheme: colorScheme,
            icon: Icons.shield_rounded,
            label: 'Auth',
            onTap: onAuthTap,
            isError: false,
          ),
          const SizedBox(height: 12),
          _buildExpandedButton(
            colorScheme: colorScheme,
            icon: Icons.rocket_launch_rounded,
            label: 'Seeding',
            onTap: onSeedingTap,
            isError: false,
          ),
        ],
      ),
      ),
    );
  }


  /// Full button cho expanded mode
  Widget _buildExpandedButton({
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isError = false,
  }) {
    final color = isError ? colorScheme.error : colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 65,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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
