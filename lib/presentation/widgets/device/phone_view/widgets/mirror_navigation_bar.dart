import 'package:flutter/material.dart';
import '../../../../../core/constants/ui_constants.dart';
import '../../../../../core/utils/android_key_codes.dart';
import '../../../../../core/di/injection.dart';
import '../../../../global_stores/mirroring_store.dart';

/// Android navigation bar component with Back, Home, Recent Apps buttons.
///
/// Provides Android system navigation controls for device mirroring.
class MirrorNavigationBar extends StatelessWidget {
  final String serial;
  final bool isEnabled;

  const MirrorNavigationBar({
    super.key,
    required this.serial,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: UIConstants.navigationBarHeight,
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow),
      child: Column(
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavigationButton(
                  serial: serial,
                  icon: Icons.arrow_back_ios_new_rounded,
                  keyCode: AndroidKeyCodes.kBack,
                  isEnabled: isEnabled,
                ),
                _NavigationButton(
                  serial: serial,
                  icon: Icons.circle_outlined,
                  keyCode: AndroidKeyCodes.kHome,
                  isPrimary: true,
                  isEnabled: isEnabled,
                ),
                _NavigationButton(
                  serial: serial,
                  icon: Icons.crop_square_rounded,
                  keyCode: AndroidKeyCodes.kAppSwitch,
                  isEnabled: isEnabled,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final String serial;
  final IconData icon;
  final int keyCode;
  final bool isPrimary;
  final bool isEnabled;

  const _NavigationButton({
    required this.serial,
    required this.icon,
    required this.keyCode,
    this.isPrimary = false,
    this.isEnabled = true,
  });

  void _onTap() {
    final store = getIt<MirroringStore>();

    // Send keydown
    store.sendKey(serial, keyCode, 0);

    // Send keyup after delay
    Future.delayed(UIConstants.navButtonPressDelay, () {
      store.sendKey(serial, keyCode, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? _onTap : null,
        borderRadius: BorderRadius.circular(UIConstants.buttonBorderRadius),
        child: AnimatedContainer(
          duration: UIConstants.hoverAnimationDuration,
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.navButtonPaddingHorizontal,
            vertical: UIConstants.navButtonPaddingVertical,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UIConstants.buttonBorderRadius),
            color: isPrimary
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            color: isEnabled
                ? (isPrimary
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant)
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            size: isPrimary
                ? UIConstants.navButtonIconSizePrimary
                : UIConstants.navButtonIconSize,
          ),
        ),
      ),
    );
  }
}
