import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/features/auth/domain/entities/auth_token.dart';
import 'package:scraki/features/auth/presentation/stores/auth_store.dart';
import 'package:scraki/features/settings/presentation/stores/settings_store.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/floating_tool_box_card.dart';

class AuthPanel extends StatefulWidget {
  final String serial;

  const AuthPanel({super.key, required this.serial});

  @override
  State<AuthPanel> createState() => _AuthPanelState();
}

class _AuthPanelState extends State<AuthPanel> {
  late final AuthStore _store;
  late final SettingsStore _settingsStore;

  @override
  void initState() {
    super.initState();
    _store = getIt<AuthStore>();
    _settingsStore = getIt<SettingsStore>();
    
    _store.init();
    _store.loadTokens(_settingsStore.deviceGroupCollection, widget.serial);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FloatingToolBoxCard(
      width: 320,
      height: 400,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Authenticator',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Observer(
                builder: (_) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_store.secondsRemaining}s',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Observer(
              builder: (_) {
                if (_store.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_store.tokens.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.vpn_key_outlined, size: 48, color: colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'No accounts found',
                          style: TextStyle(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: _store.tokens.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final token = _store.tokens[index];
                    return _buildAuthItem(context, token);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Observer(
            builder: (_) {
              if (_store.errorMessage != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _store.errorMessage!,
                    style: TextStyle(color: colorScheme.error, fontSize: 12),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
          Row(
            children: [
              Expanded(
                child: Observer(
                  builder: (_) => FilledButton.icon(
                    onPressed: _store.isLoading 
                      ? null 
                      : () => _store.captureFromScreen(
                          _settingsStore.deviceGroupCollection, 
                          widget.serial
                        ),
                    icon: _store.isLoading 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.screenshot_monitor_rounded),
                    label: Text(_store.isLoading ? 'Capturing...' : 'Capture'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showManualAddDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Manual'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthItem(BuildContext context, AuthToken token) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Observer(
      builder: (_) {
        final code = _store.currentCodes[token.id] ?? '------';
        return InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Copied $code to clipboard'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                width: 200,
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        token.issuer,
                        style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                      ),
                      Text(
                        token.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: token.secret));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Secret key copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Text(
                          token.secret,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline.withValues(alpha: 0.7),
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      code,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _store.deleteToken(
                        _settingsStore.deviceGroupCollection,
                        widget.serial,
                        token.id,
                      ),
                      icon: Icon(Icons.delete_outline_rounded, size: 18, color: colorScheme.error),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showManualAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final secretController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Add'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                hintText: 'e.g. TikTok, Google',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: secretController,
              decoration: const InputDecoration(
                labelText: 'Secret Key',
                hintText: '32 characters Base32',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final secret = secretController.text.trim().replaceAll(' ', '').toUpperCase();
              if (secret.isEmpty || secret.length < 16) {
                return;
              }
              _store.addToken(
                _settingsStore.deviceGroupCollection,
                widget.serial,
                nameController.text.trim().isEmpty ? 'Manual Account' : nameController.text.trim(),
                'Manual',
                secret,
              );
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}


