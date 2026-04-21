import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/email/domain/entities/email_account.dart';
import 'package:scraki/features/settings/presentation/stores/settings_email_store.dart';
import 'dart:ui';

class BulkAddDialog extends StatefulWidget {
  final Future<void> Function(String) onImport;
  final SettingsEmailStore store;

  const BulkAddDialog({
    super.key,
    required this.onImport,
    required this.store,
  });

  @override
  State<BulkAddDialog> createState() => _BulkAddDialogState();
}

class _BulkAddDialogState extends State<BulkAddDialog> {
  final TextEditingController _controller = TextEditingController();
  List<EmailAccount> _previewAccounts = [];
  bool _showPreview = false;

  void _onVerify() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập dữ liệu')),
      );
      return;
    }

    final List<EmailAccount> results = [];
    final lines = text.split(RegExp(r'\r?\n'));
    
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.trim().split('|');
      if (parts.length >= 5) {
        try {
          if (parts.length == 5) {
            results.add(EmailAccount(
              username: parts[0].trim(),
              password: parts[1].trim(),
              email: parts[2].trim(),
              refreshToken: parts[3].trim(),
              clientId: parts[4].trim(),
            ));
          } else {
            results.add(EmailAccount(
              username: parts[0].trim(),
              password: parts[1].trim(),
              email: parts[2].trim(),
              refreshToken: parts[4].trim(),
              clientId: parts[5].trim(),
            ));
          }
        } catch (_) {}
      }
    }

    setState(() {
      _previewAccounts = results;
      _showPreview = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final indigo = const Color(0xFF6366F1);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Observer(
        builder: (_) {
          final isLoading = widget.store.isLoading;
          
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isLight ? Colors.white : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isLight ? Colors.black12 : Colors.white10,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                )
              ],
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.file_upload_outlined, color: indigo),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'IMPORT HÀNG LOẠT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Dán nội dung file account.txt vào đây',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!_showPreview) ...[
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  maxLines: null,
                                  expands: true,
                                  readOnly: isLoading,
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: InputDecoration(
                                    hintText: 'user|pass|email|token|client...',
                                    filled: true,
                                    fillColor: isLight ? Colors.grey[50] : Colors.black26,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.all(20),
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Đã phân tích thấy ${_previewAccounts.length} tài khoản hợp lệ.',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _previewAccounts.length,
                                  itemBuilder: (context, index) {
                                    final acc = _previewAccounts[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isLight ? Colors.grey[100] : Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: indigo.withValues(alpha: 0.2),
                                            child: Text(
                                              '${index + 1}',
                                              style: TextStyle(fontSize: 10, color: indigo, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              acc.email,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Text(
                                            acc.username,
                                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    // Footer
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_showPreview)
                            TextButton(
                              onPressed: isLoading ? null : () => setState(() => _showPreview = false),
                              child: const Text('Back to Edit'),
                            ),
                          const Spacer(),
                          if (!_showPreview)
                            ElevatedButton(
                              onPressed: isLoading ? null : _onVerify,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('VERIFY FORMAT', style: TextStyle(fontWeight: FontWeight.bold)),
                            )
                          else
                            ElevatedButton(
                              onPressed: isLoading 
                                ? null 
                                : () async {
                                    await widget.onImport(_controller.text);
                                    if (mounted) Navigator.of(context).pop();
                                  },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('IMPORT ALL', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Beautiful Loading Overlay
                if (isLoading)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          color: (isLight ? Colors.white : const Color(0xFF1E293B)).withValues(alpha: 0.5),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: indigo,
                                        backgroundColor: indigo.withValues(alpha: 0.1),
                                      ),
                                    ),
                                    Icon(Icons.cloud_upload_rounded, color: indigo, size: 32),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'ĐANG LƯU DỮ LIỆU...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    color: isLight ? indigo : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Vui lòng không đóng cửa sổ này',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isLight ? Colors.grey[600] : Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
