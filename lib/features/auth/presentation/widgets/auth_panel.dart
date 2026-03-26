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
    final onSurface = colorScheme.onSurface;

    return FloatingToolBoxCard(
      width: 340,
      height: widget.serial.isEmpty ? 200 : 420,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Premium Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: onSurface.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(Icons.shield_rounded, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AUTHENTICATOR',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Active Session',
                            style: TextStyle(
                              fontSize: 11,
                              color: onSurface.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Observer(
                  builder: (_) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      '${_store.secondsRemaining}s',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Observer(
              builder: (_) {
                if (_store.isLoading && _store.tokens.isEmpty) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 3));
                }
                if (_store.tokens.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.vpn_key_rounded, 
                          size: 64, 
                          color: onSurface.withValues(alpha: 0.05),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'CHƯA CÓ TÀI KHOẢN',
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.3),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
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

          // Footer Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: onSurface.withValues(alpha: 0.02),
              border: Border(
                top: BorderSide(
                  color: onSurface.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Observer(
                  builder: (_) {
                    if (_store.errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _store.errorMessage!.toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.error, 
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
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
                        builder: (_) => ElevatedButton.icon(
                          onPressed: _store.isLoading 
                            ? null 
                            : () => _store.captureFromScreen(
                                _settingsStore.deviceGroupCollection, 
                                widget.serial
                              ),
                          icon: _store.isLoading 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.screenshot_monitor_rounded, size: 18),
                          label: Text(
                            _store.isLoading ? 'CAPTURING...' : 'CAPTURE SCREEN',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: () => _showManualAddDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      tooltip: 'Manual Add',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthItem(BuildContext context, AuthToken token) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Observer(
      builder: (_) {
        final code = _store.currentCodes[token.id] ?? '------';
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied $code to clipboard'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: onSurface.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          token.issuer.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          token.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          token.secret.substring(0, code.length.clamp(0, token.secret.length)) + '...',
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.3),
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        code,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _store.deleteToken(
                          _settingsStore.deviceGroupCollection,
                          widget.serial,
                          token.id,
                        ),
                        icon: Icon(Icons.delete_outline_rounded, size: 16, color: colorScheme.error.withValues(alpha: 0.6)),
                        hoverColor: colorScheme.error.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                ],
              ),
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


