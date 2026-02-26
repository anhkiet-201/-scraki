import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/features/device/presentation/widgets/floating_phone_view/widgets/floating_tool_box/widgets/floating_tool_box_card.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
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

    return FloatingToolBoxCard(
      width: 480,
      height: widget.height,
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Email OTP Reader',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                  tooltip: 'Close panel',
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Observer(
                builder: (context) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email Input & Connect Button
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              onChanged: _store.setTargetEmail,
                              decoration: InputDecoration(
                                hintText:
                                    'Nhập email hoặc để trống để tự lấy qua ADB...',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
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
                                        .assignEmailToDeviceAndStartStream(
                                          deviceSerial: widget.deviceSerial,
                                          requireDump: requireDump,
                                        )
                                        .then((_) {
                                          if (_store.targetEmail.isNotEmpty) {
                                            if (_emailController.text !=
                                                _store.targetEmail) {
                                              _emailController.text =
                                                  _store.targetEmail;
                                            }
                                            // Save the email to the device's group in Firebase
                                            getIt<DeviceGroupStore>()
                                                .saveEmailForDevice(
                                                  widget.deviceSerial,
                                                  _store.targetEmail,
                                                );
                                          }
                                        });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
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
                                : const Icon(Icons.sync, size: 18),
                            label: const Text('Connect'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Error message
                      if (_store.errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colorScheme.onErrorContainer,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _store.errorMessage!,
                                  style: TextStyle(
                                    color: colorScheme.onErrorContainer,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Email List
                      Expanded(
                        child: _store.messages.isEmpty && !_store.isLoading
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 48,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Chưa có email nào.',
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: _store.messages.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final msg = _store.messages[index];
                                  final isOtp = msg.otp != null;

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: isOtp
                                          ? colorScheme.primaryContainer
                                          : colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        isOtp
                                            ? Icons.vpn_key
                                            : Icons.mail_outline,
                                        color: isOtp
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    title: Text(
                                      msg.subject,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat(
                                            'HH:mm:ss',
                                          ).format(msg.receivedAt),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                    trailing: isOtp
                                        ? InkWell(
                                            onTap: () async {
                                              await _store.sendOtpToDevice(
                                                widget.deviceSerial,
                                                msg.otp!,
                                              );
                                              if (context.mounted &&
                                                  _store.errorMessage == null) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Đã gửi OTP ${msg.otp!} qua ADB',
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                msg.otp!,
                                                style: TextStyle(
                                                  color: colorScheme.onPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ),
                                          )
                                        : null,
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
}
