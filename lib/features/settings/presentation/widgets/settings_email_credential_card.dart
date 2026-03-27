import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/features/settings/presentation/stores/settings_email_store.dart';
import 'package:scraki/features/settings/presentation/widgets/email_data_text_controller.dart';
import 'package:scraki/features/settings/presentation/widgets/settings_ghost_editor.dart';

class SettingsEmailCredentialCard extends StatefulWidget {
  const SettingsEmailCredentialCard({super.key});

  @override
  State<SettingsEmailCredentialCard> createState() =>
      _SettingsEmailCredentialCardState();
}

class _SettingsEmailCredentialCardState
    extends State<SettingsEmailCredentialCard> {
  late final SettingsEmailStore _store;
  late final EmailDataTextController _controller;

  @override
  void initState() {
    super.initState();
    _store = getIt<SettingsEmailStore>();
    _controller = EmailDataTextController();
    _store.loadCredentials().then((_) {
      _controller.text = _store.rawCredentials;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: null,
        boxShadow: isLight 
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))] 
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 20,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMAIL ACCOUNTS DATA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: isLight ? const Color(0xFF1E293B) : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cấu hình danh sách tài khoản Email (mỗi dòng một tài khoản)',
                      style: TextStyle(
                        fontSize: 11,
                        color: isLight ? const Color(0xFF64748B) : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              Observer(
                builder: (_) {
                  return ElevatedButton.icon(
                    onPressed: _store.isLoading
                        ? null
                        : () async {
                            _store.updateCredentialsLocally(_controller.text);
                            await _store.saveCredentials();
                            if (_store.errorMessage == null &&
                                context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Email Credentials saved!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _store.errorMessage ?? 'Lỗi xảy ra',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    icon: _store.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: const Text(
                      'LƯU FIREBASE',
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          SettingsGhostEditor(
            controller: _controller,
            isLight: isLight,
            height: 450, // Optimized height
          ),
        ],
      ),
    );
  }
}
