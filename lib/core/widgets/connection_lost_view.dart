import 'package:flutter/material.dart';

/// Displays connection lost state with reconnect button.
///
/// Shown when device connection is interrupted during mirroring.
class ConnectionLostView extends StatelessWidget {
  final VoidCallback? onReconnect;
  final bool isConnecting;

  const ConnectionLostView({
    super.key,
    this.onReconnect,
    this.isConnecting = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.signal_wifi_off_rounded,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Connection Lost',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The device connection was interrupted.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
          if (onReconnect != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: isConnecting ? null : onReconnect,
              icon: isConnecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(isConnecting ? 'Reconnecting...' : 'Reconnect Now'),
            ),
          ],
        ],
      ),
    );
  }
}
