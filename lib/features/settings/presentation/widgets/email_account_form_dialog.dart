import 'package:flutter/material.dart';
import 'package:scraki/features/email/domain/entities/email_account.dart';

class EmailAccountFormDialog extends StatefulWidget {
  final EmailAccount? account;
  final Future<void> Function(EmailAccount) onSave;

  const EmailAccountFormDialog({
    super.key,
    this.account,
    required this.onSave,
  });

  @override
  State<EmailAccountFormDialog> createState() => _EmailAccountFormDialogState();
}

class _EmailAccountFormDialogState extends State<EmailAccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _emailController;
  late final TextEditingController _refreshTokenController;
  late final TextEditingController _clientIdController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.account?.username);
    _passwordController = TextEditingController(text: widget.account?.password);
    _emailController = TextEditingController(text: widget.account?.email);
    _refreshTokenController =
        TextEditingController(text: widget.account?.refreshToken);
    _clientIdController =
        TextEditingController(text: widget.account?.clientId);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _refreshTokenController.dispose();
    _clientIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final indigo = const Color(0xFF6366F1);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: 550,
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [indigo, indigo.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.account == null
                            ? Icons.add_link_rounded
                            : Icons.edit_note_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.account == null ? 'THÊM TÀI KHOẢN' : 'CẬP NHẬT TÀI KHOẢN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          widget.account == null
                              ? 'Điền thông tin tài khoản email mới'
                              : 'Chỉnh sửa thông tin tài khoản hiện tại',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildField(
                        'Email Address (Bắt buộc)',
                        _emailController,
                        Icons.alternate_email_rounded,
                        isLight,
                        readOnly: widget.account != null,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Vui lòng nhập Email'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              'Username/ID',
                              _usernameController,
                              Icons.person_pin_rounded,
                              isLight,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildField(
                              'Password',
                              _passwordController,
                              Icons.lock_person_rounded,
                              isLight,
                              isPassword: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        'Refresh Token',
                        _refreshTokenController,
                        Icons.vpn_key_rounded,
                        isLight,
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        'Client ID',
                        _clientIdController,
                        Icons.apps_rounded,
                        isLight,
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                color: isLight ? Colors.grey[50] : Colors.black.withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'HỦY BỎ',
                        style: TextStyle(
                          color: isLight ? Colors.grey[600] : Colors.white24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          final acc = EmailAccount(
                            username: _usernameController.text,
                            password: _passwordController.text,
                            email: _emailController.text,
                            refreshToken: _refreshTokenController.text,
                            clientId: _clientIdController.text,
                          );
                          await widget.onSave(acc);
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: indigo,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'LƯU CẤU HÌNH',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          fontSize: 12,
                        ),
                      ),
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

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isLight, {
    bool isPassword = false,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isLight ? Colors.grey[400] : Colors.white24,
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          readOnly: readOnly,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18),
            filled: true,
            fillColor: isLight ? Colors.grey[100] : Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ],
    );
  }
}
