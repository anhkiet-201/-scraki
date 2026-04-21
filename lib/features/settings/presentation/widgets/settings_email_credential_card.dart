import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/features/email/domain/entities/email_account.dart';
import 'package:scraki/features/settings/presentation/stores/settings_email_store.dart';
import 'package:scraki/features/settings/presentation/widgets/bulk_add_dialog.dart';
import 'package:scraki/features/settings/presentation/widgets/email_account_form_dialog.dart';

class SettingsEmailCredentialCard extends StatefulWidget {
  const SettingsEmailCredentialCard({super.key});

  @override
  State<SettingsEmailCredentialCard> createState() =>
      _SettingsEmailCredentialCardState();
}

class _SettingsEmailCredentialCardState
    extends State<SettingsEmailCredentialCard> {
  late final SettingsEmailStore _store;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _store = getIt<SettingsEmailStore>();
    _store.loadInitialAccounts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        _store.loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final indigo = const Color(0xFF6366F1);

    return Container(
      width: double.infinity,
      height: 650,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isLight, indigo),
          const SizedBox(height: 24),
          _buildToolBar(isLight, indigo),
          const SizedBox(height: 24),
          Expanded(
            child: Observer(
              builder: (_) {
                if (_store.isLoading && _store.accounts.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (_store.accounts.isEmpty) {
                  return _buildEmptyState(isLight);
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _store.accounts.length + (_store.hasMore ? 1 : 0),
                        padding: const EdgeInsets.only(bottom: 20),
                        itemBuilder: (context, index) {
                          if (index == _store.accounts.length) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          }

                          final account = _store.accounts[index];
                          return _buildAccountItem(account, isLight, indigo);
                        },
                      ),
                    ),
                    if (_store.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _store.errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildFormatGuide(isLight),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isLight, Color indigo) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [indigo, indigo.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.mark_email_read_rounded, size: 24, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMAIL ACCOUNTS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: isLight ? const Color(0xFF1E293B) : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quản lý danh sách tài khoản',
                  style: TextStyle(
                    fontSize: 12,
                    color: isLight ? const Color(0xFF64748B) : Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              label: 'MIGRATION',
              icon: Icons.sync_alt_rounded,
              color: Colors.orange,
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => BulkAddDialog(
                    store: _store,
                    onImport: (text) async => _store.bulkImport(text),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              label: 'THÊM MỚI',
              icon: Icons.add_rounded,
              color: indigo,
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => EmailAccountFormDialog(
                    onSave: (acc) async => _store.addAccount(acc),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolBar(bool isLight, Color indigo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isLight ? Colors.grey[100] : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: isLight ? Colors.grey : Colors.white38, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _store.setSearchQuery(val),
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm theo email...',
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () {
                _searchController.clear();
                _store.setSearchQuery('');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAccountItem(EmailAccount account, bool isLight, Color indigo) {
    const slate = Color(0xFF1E293B);
    const slateLight = Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Trạng thái / Avatar
              Container(
                width: 6,
                color: indigo,
              ),
              const SizedBox(width: 20),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: indigo.withValues(alpha: 0.1),
                  child: Icon(Icons.alternate_email_rounded, color: indigo, size: 20),
                ),
              ),
              const SizedBox(width: 20),
              // Thông tin chính
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              account.email,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: isLight ? slate : Colors.white,
                              ),
                            ),
                          ),
                          _buildCopyButton(context, account.email, 'Email', isLight),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.password_rounded, size: 12, color: slateLight.withValues(alpha: 0.6)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pass: ${account.password}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isLight ? slateLight : Colors.white38,
                              ),
                            ),
                          ),
                          _buildCopyButton(context, account.password, 'Password', isLight),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Thông tin phụ (Username/ID)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'USERNAME / ID',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: isLight ? slateLight.withValues(alpha: 0.5) : Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.username.isEmpty ? '—' : account.username,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isLight ? slate : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Group Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: isLight ? Colors.grey[50] : Colors.black.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_note_rounded, color: indigo, size: 22),
                      tooltip: 'Chỉnh sửa',
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (context) => EmailAccountFormDialog(
                            account: account,
                            onSave: (acc) => _store.updateAccount(acc),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22),
                      tooltip: 'Xóa tài khoản',
                      onPressed: () => _confirmDelete(account.email),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context, String text, String label, bool isLight) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Text('Đã sao chép $label'),
              ],
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            width: 250,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFF6366F1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Icon(
          Icons.copy_rounded,
          size: 14,
          color: isLight ? const Color(0xFF6366F1).withValues(alpha: 0.5) : Colors.white24,
        ),
      ),
    );
  }

  void _confirmDelete(String email) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa tài khoản $email?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              _store.deleteAccount(email);
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isLight) {
    final indigo = const Color(0xFF6366F1);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isLight ? Colors.grey[100] : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.email_outlined, size: 64, color: Colors.grey[isLight ? 300 : 700]),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có tài khoản email nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isLight ? Colors.grey[800] : Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bắt đầu bằng cách thêm tài khoản đầu tiên của bạn',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => EmailAccountFormDialog(
                  onSave: (acc) async => _store.addAccount(acc),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('THÊM TÀI KHOẢN MỚI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildFormatGuide(bool isLight) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLight ? Colors.amber.shade50 : Colors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight ? Colors.amber.shade100 : Colors.amber.withValues(alpha: 0.1),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mẹo: Dùng ô tìm kiếm để lọc tài khoản theo email nhanh chóng.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
