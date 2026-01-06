import 'package:flutter/material.dart';
import 'package:scraki/core/constants/ui_constants.dart';
import 'package:scraki/core/utils/android_key_codes.dart';
import 'package:scraki/features/device/presentation/widgets/phone_view/store/phone_view_store.dart';

/// Android navigation bar component with Back, Home, Recent Apps buttons.
///
/// Provides Android system navigation controls for device mirroring.
class MirrorNavigationBar extends StatelessWidget {
  final PhoneViewStore store;
  final bool isEnabled;
  final bool isFloating;

  const MirrorNavigationBar({
    super.key,
    required this.store,
    this.isEnabled = true,
    this.isFloating = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: isFloating ? UIConstants.floatingNavigationBarHeight : UIConstants.gridNavigationBarHeight,
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
                  store: store,
                  icon: Icons.arrow_back_ios_new_rounded,
                  keyCode: AndroidKeyCodes.kBack,
                  isEnabled: isEnabled,
                  isFloating: isFloating,
                ),
                _NavigationButton(
                  store: store,
                  icon: Icons.circle_outlined,
                  keyCode: AndroidKeyCodes.kHome,
                  isPrimary: true,
                  isEnabled: isEnabled,
                  isFloating: isFloating,
                ),
                _NavigationButton(
                  store: store,
                  icon: Icons.crop_square_rounded,
                  keyCode: AndroidKeyCodes.kAppSwitch,
                  isEnabled: isEnabled,
                  isFloating: isFloating,
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
  final PhoneViewStore store;
  final IconData icon;
  final int keyCode;
  final bool isPrimary;
  final bool isFloating;
  final bool isEnabled;

  const _NavigationButton({
    required this.store,
    required this.icon,
    required this.keyCode,
    this.isPrimary = false,
    this.isEnabled = true,
    this.isFloating = false,
  });

  void _onTap() {
    // Send keydown
    store.sendKey(store.serial, keyCode, 0);

    // Send keyup after delay
    Future.delayed(UIConstants.navButtonPressDelay, () {
      store.sendKey(store.serial, keyCode, 1);
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
          padding: EdgeInsets.symmetric(
            horizontal: isFloating ? UIConstants.floatingNavButtonPaddingHorizontal : UIConstants.gridNavButtonPaddingHorizontal,
            vertical: isFloating ? UIConstants.floatingNavButtonPaddingVertical : UIConstants.gridNavButtonPaddingVertical,
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
                ? (isFloating ? UIConstants.floatingNavButtonIconSizePrimary : UIConstants.gridNavButtonIconSizePrimary)
                : (isFloating ? UIConstants.floatingNavButtonIconSize : UIConstants.gridNavButtonIconSize),
          ),
        ),
      ),
    );
  }
}
