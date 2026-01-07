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

  static Future<T?> show<T>({
    required BuildContext context,
    required Offset position,
    required List<Widget> items,
    double width = 200,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              left: position.dx,
              top: position.dy,
              child: BoxCardMenu(items: items, width: width),
            ),
          ],
        );
      },
    );
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
        Navigator.pop(context);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Theme(
              data: theme.copyWith(
                iconTheme: theme.iconTheme.copyWith(
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              child: icon,
            ),
            const SizedBox(width: 12),
            DefaultTextStyle(
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              child: label,
            ),
          ],
        ),
      ),
    );
  }
}

class BoxCardMenuHeader extends StatelessWidget {
  final String title;

  const BoxCardMenuHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
