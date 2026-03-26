import 'package:flutter/material.dart';
import 'package:scraki/core/widgets/box_card.dart';

class BoxCardMenu extends StatelessWidget {
  final List<Widget> items;
  final double width;

  const BoxCardMenu({super.key, required this.items, this.width = 200});

  @override
  Widget build(BuildContext context) {
    return BoxCard(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: items),
    );
  }

  static OverlayEntry? _activeEntry;

  static void hide() {
    _activeEntry?.remove();
    _activeEntry = null;
  }

  static Future<void> show<T>({
    required BuildContext context,
    required Offset position,
    required List<Widget> items,
    double width = 200,
  }) async {
    // 1. Close existing menu if any
    hide();

    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    
    // Estimate height (approx 44px per item + headers/dividers)
    // This is an estimate to prevent bottom cut-off
    final estimatedHeight = items.length * 48.0 + 20.0;

    double left = position.dx;
    double top = position.dy;

    // Smart Positioning - Horizontal
    if (left + width > screenSize.width - 16) {
      left = screenSize.width - width - 16;
    }
    if (left < 16) left = 16;

    // Smart Positioning - Vertical
    if (top + estimatedHeight > screenSize.height - 16) {
      top = screenSize.height - estimatedHeight - 16;
    }
    if (top < 16) top = 16;

    final entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Barrier to close on tap outside
            // We use a GestureDetector with hitTestBehavior.translucent 
            // but wait, if we want "click elsewhere to open new menu", 
            // we should probably NOT consume the tap if it's a right click or a specific target.
            // However, the standard behavior is to close on any tap.
            GestureDetector(
              onTap: hide,
              onSecondaryTap: hide,
              onTertiaryTapDown: (_) => hide(),
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              left: left,
              top: top,
              child: BoxCardMenu(items: items, width: width),
            ),
          ],
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }
}

class BoxCardMenuItem extends StatelessWidget {
  final Widget icon;
  final Widget label;
  final VoidCallback onTap;

  const BoxCardMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        BoxCardMenu.hide();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Theme(
              data: theme.copyWith(
                iconTheme: theme.iconTheme.copyWith(
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              child: icon,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DefaultTextStyle(
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                child: label,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoxCardMenuHeader extends StatelessWidget {
  final String title;
  final IconData? icon;

  const BoxCardMenuHeader({super.key, required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
