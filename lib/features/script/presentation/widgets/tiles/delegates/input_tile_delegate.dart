import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import '../script_tile_delegate.dart';
import 'default_tile_ui_mixin.dart';

/// Delegate hỗ trợ nhập nội dung trước khi chạy script (tự động phát hiện ô nhập đơn hoặc nhiều tham số).
class InputTileDelegate with DefaultTileUiMixin implements ScriptTileDelegate {
  @override
  final ScriptTileDelegateCall? onRun;

  @override
  final ScriptTileDelegateCall? onDelete;

  @override
  final ScriptTileDelegateCall? onEdit;

  @override
  final bool isExecuting;

  InputTileDelegate({
    this.onRun,
    this.onDelete,
    this.onEdit,
    this.isExecuting = false,
  });

  @override
  Widget? buildTrailing(BuildContext context, ScriptEntity script) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _showInputDialog(context, script),
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: const Color(0xFF10B981),
          tooltip: 'Chạy script (cần nhập input)',
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => onEdit?.call(script),
          icon: const Icon(Icons.edit_rounded, size: 14),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          tooltip: 'Sửa script',
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => _showDeleteConfirm(context, script),
          icon: const Icon(Icons.delete_outline_rounded, size: 14),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: theme.colorScheme.error.withValues(alpha: 0.6),
          tooltip: 'Xóa script',
        ),
      ],
    );
  }

  @override
  void onTap(BuildContext context, ScriptEntity script) {
    onEdit?.call(script);
  }

  Set<String> _extractInputKeys(List<String> commands) {
    final regex = RegExp(r'\{input:([^}]+)\}');
    final keys = <String>{};
    for (final command in commands) {
      final matches = regex.allMatches(command);
      for (final match in matches) {
        final key = match.group(1);
        if (key != null && key.trim().isNotEmpty) {
          keys.add(key.trim());
        }
      }
    }
    return keys;
  }

  bool _hasSingleInput(List<String> commands) {
    final regex = RegExp(r'\{input(?!:)\}');
    return commands.any((command) => regex.hasMatch(command));
  }

  void _showInputDialog(BuildContext context, ScriptEntity script) {
    final keys = _extractInputKeys(script.commands);
    final hasSingle = _hasSingleInput(script.commands);

    showDialog<Map<String, String>?>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => _UnifiedInputDialog(
        script: script,
        keys: keys,
        hasSingleInput: hasSingle,
      ),
    ).then((args) {
      if (args != null) {
        onRun?.call(script, args);
      }
    });
  }

  void _showDeleteConfirm(BuildContext context, ScriptEntity script) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Script'),
        content: Text('Bạn có chắc chắn muốn xóa script "${script.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call(script);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _UnifiedInputDialog extends StatefulWidget {
  final ScriptEntity script;
  final Set<String> keys;
  final bool hasSingleInput;

  const _UnifiedInputDialog({
    required this.script,
    required this.keys,
    required this.hasSingleInput,
  });

  @override
  State<_UnifiedInputDialog> createState() => _UnifiedInputDialogState();
}

class _UnifiedInputDialogState extends State<_UnifiedInputDialog> {
  final Map<String, TextEditingController> _multiControllers = {};
  late final TextEditingController _singleController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _singleController = TextEditingController();
    for (final key in widget.keys) {
      _multiControllers[key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _singleController.dispose();
    for (final controller in _multiControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleConfirm() {
    if (!widget.hasSingleInput && widget.keys.isEmpty) {
      Navigator.pop(context, <String, String>{});
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final args = <String, String>{};
      if (widget.hasSingleInput) {
        args['input'] = _singleController.text;
      }
      for (final entry in _multiControllers.entries) {
        args[entry.key] = entry.value.text;
      }
      Navigator.pop(context, args);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showWarning = !widget.hasSingleInput && widget.keys.isEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: 420,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.keys.isNotEmpty
                          ? Icons.settings_input_component_rounded
                          : Icons.terminal_rounded,
                      color: const Color(0xFF4F46E5),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tham số thực thi',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Script: ${widget.script.name}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showWarning) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFD97706),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Script này chưa khai báo tham số {input} hoặc {input:tên_biến} trong câu lệnh.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: const Color(0xFF92400E),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // 1. Single Input {input}
                      if (widget.hasSingleInput) ...[
                        Text(
                          'DỮ LIỆU ĐẦU VÀO {input}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _singleController,
                          maxLines: 8,
                          minLines: 4,
                          autofocus: !showWarning && widget.keys.isEmpty,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: const Color(0xFF1E293B),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nhập nội dung cho {input}...',
                            hintStyle: GoogleFonts.outfit(
                              color: const Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF4F46E5),
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập dữ liệu';
                            }
                            return null;
                          },
                        ),
                        if (widget.keys.isNotEmpty) const SizedBox(height: 24),
                      ],

                      // 2. Multi Input {input:khóa}
                      if (widget.keys.isNotEmpty) ...[
                        Text(
                          'CẤU HÌNH THAM SỐ',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...widget.keys.map((key) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  key,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  maxLines: null,
                                  minLines: 3,
                                  controller: _multiControllers[key],
                                  autofocus: !showWarning &&
                                      !widget.hasSingleInput &&
                                      widget.keys.first == key,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Nhập giá trị cho $key...',
                                    hintStyle: GoogleFonts.outfit(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 13,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF4F46E5),
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.redAccent,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorStyle: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Vui lòng nhập giá trị';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 12),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                foregroundColor: const Color(0xFF64748B),
                              ),
                              child: Text(
                                'Hủy',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleConfirm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Chạy ngay',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
