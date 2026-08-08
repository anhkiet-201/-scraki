import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/floating_tool_box_card.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
import 'package:scraki/features/email/domain/entities/email_message.dart';
import 'package:scraki/features/email/presentation/stores/email_store.dart';

class EmailPanel extends StatefulWidget {
  final double height;
  final String deviceSerial;
  final VoidCallback onCancel;

  const EmailPanel({
    super.key,
    required this.height,
    required this.deviceSerial,
    required this.onCancel,
  });

  @override
  State<EmailPanel> createState() => _EmailPanelState();
}

class _EmailPanelState extends State<EmailPanel> {
  late final EmailStore _store;
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _store = getIt<EmailStore>();

    // First query firestore/settings implicitly?
    // We assume the caller or another store provides the currently linked email if any.
    final savedEmail = getIt<DeviceGroupStore>().getEmailForDevice(
      widget.deviceSerial,
    );
    if (savedEmail != null && savedEmail.isNotEmpty) {
      _emailController.text = savedEmail;
      _store.setTargetEmail(savedEmail);
    }
  }

  @override
  void dispose() {
    _store.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return FloatingToolBoxCard(
      width: 480,
      height: widget.height,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Modern Header
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EMAIL OTP READER',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tự động đọc mã OTP từ hòm thư',
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close_rounded),
                  color: onSurface.withValues(alpha: 0.4),
                  iconSize: 22,
                  hoverColor: colorScheme.error.withValues(alpha: 0.1),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Observer(
                builder: (context) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email Input & Connect Button
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: TextField(
                                controller: _emailController,
                                onChanged: _store.setTargetEmail,
                                decoration: InputDecoration(
                                  hintText: 'Nhập email (để trống nếu lấy qua ADB)...',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: onSurface.withValues(alpha: 0.4),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  filled: true,
                                  fillColor: onSurface.withValues(alpha: 0.04),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: onSurface.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: onSurface.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colorScheme.primary.withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _store.isLoading
                                ? null
                                : () async {
                                    final email = _emailController.text.trim();
                                    await _store.autoFillPasswordToDevice(
                                      deviceSerial: widget.deviceSerial,
                                      targetEmail: email,
                                    );
                                    if (context.mounted &&
                                        _store.errorMessage == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Đã tự động điền mật khẩu qua ADB'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              side: BorderSide(
                                color: colorScheme.primary.withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.password_rounded, size: 16),
                            label: const Text(
                              'FILL PASS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _store.isLoading
                                ? null
                                : () {
                                    final requireDump = _emailController.text
                                        .trim()
                                        .isEmpty;

                                    _store
                                        .assignEmailToDevice(
                                          deviceSerial: widget.deviceSerial,
                                          requireDump: requireDump,
                                        )
                                        .then((resolvedEmail) {
                                          if (resolvedEmail != null &&
                                              resolvedEmail.isNotEmpty) {
                                            _emailController.text =
                                                resolvedEmail;

                                            // Save the email to the device's group in Firebase
                                            getIt<DeviceGroupStore>()
                                                .saveEmailForDevice(
                                                  widget.deviceSerial,
                                                  resolvedEmail,
                                                );

                                            // Now start the IMAP stream
                                            _store.startImapStream(
                                              resolvedEmail,
                                            );
                                          }
                                        });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _store.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.sync_rounded, size: 18),
                            label: const Text(
                              'CONNECT',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Error message
                      if (_store.errorMessage != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.error.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: colorScheme.error,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _store.errorMessage!,
                                  style: TextStyle(
                                    color: colorScheme.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Email List
                      Expanded(
                        child: _store.messages.isEmpty
                            ? Center(
                                child: _store.isLoading || _store.isListening
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(strokeWidth: 3),
                                          const SizedBox(height: 20),
                                          Text(
                                            'ĐANG ĐỢI EMAIL MỚI...',
                                            style: TextStyle(
                                              color: onSurface.withValues(alpha: 0.4),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.inbox_rounded,
                                            size: 64,
                                            color: onSurface.withValues(alpha: 0.05),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'CHƯA CÓ EMAIL NÀO',
                                            style: TextStyle(
                                              color: onSurface.withValues(alpha: 0.3),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.only(top: 8),
                                itemCount: _store.messages.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final msg = _store.messages[index];
                                  final isOtp = msg.otp != null;

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _showEmailDetailsDialog(context, msg),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: onSurface.withValues(alpha: 0.03),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: onSurface.withValues(alpha: 0.05),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: (isOtp ? colorScheme.primary : colorScheme.onSurface).withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: (isOtp ? colorScheme.primary : colorScheme.onSurface).withValues(alpha: 0.15),
                                                ),
                                              ),
                                              child: Icon(
                                                isOtp ? Icons.vpn_key_rounded : Icons.mail_rounded,
                                                color: isOtp ? colorScheme.primary : onSurface.withValues(alpha: 0.5),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    msg.subject,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 13,
                                                      color: onSurface,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    DateFormat('HH:mm:ss').format(msg.receivedAt),
                                                    style: TextStyle(
                                                      color: onSurface.withValues(alpha: 0.5),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isOtp) ...[
                                              const SizedBox(width: 12),
                                              InkWell(
                                                onTap: () async {
                                                  await _store.sendOtpToDevice(
                                                    widget.deviceSerial,
                                                    msg.otp!,
                                                  );
                                                  if (context.mounted &&
                                                      _store.errorMessage == null) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Đã gửi OTP ${msg.otp!} qua ADB'),
                                                        behavior: SnackBarBehavior.floating,
                                                      ),
                                                    );
                                                  }
                                                },
                                                borderRadius: BorderRadius.circular(10),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(
                                                      color: colorScheme.primary.withValues(alpha: 0.3),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    msg.otp!,
                                                    style: TextStyle(
                                                      color: colorScheme.primary,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 13,
                                                      letterSpacing: 1.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmailDetailsDialog(BuildContext context, EmailMessage msg) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        msg.otp != null ? Icons.vpn_key : Icons.mail_outline,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.subject,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm:ss').format(msg.receivedAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Body Content
              Flexible(
                child: SelectionArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: HtmlWidget(
                      msg.body,
                      textStyle: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              // Footer Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (msg.otp != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          _store.sendOtpToDevice(widget.deviceSerial, msg.otp!);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã gửi OTP ${msg.otp!} qua ADB'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text('Gửi OTP ${msg.otp!}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đóng'),
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
}
