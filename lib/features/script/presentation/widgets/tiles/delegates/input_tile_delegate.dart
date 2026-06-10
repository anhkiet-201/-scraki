import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_selector/file_selector.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/features/script/presentation/stores/script_management_store.dart';
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
          onPressed: () => _handleRunClick(context, script),
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: const Color(0xFF10B981),
          tooltip: 'Chạy script',
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

  bool _hasFileInput(List<String> commands) {
    final regex = RegExp(r'\{file\}');
    return commands.any((command) => regex.hasMatch(command));
  }

  bool _onlyRequiresFile(List<String> commands) {
    final hasFile = _hasFileInput(commands);
    final hasSingle = _hasSingleInput(commands);
    final hasKeys = _extractInputKeys(commands).isNotEmpty;
    return hasFile && !hasSingle && !hasKeys;
  }

  void _handleRunClick(BuildContext context, ScriptEntity script) {
    final staged = getIt<ScriptManagementStore>().stagedFiles[script.id];
    final onlyFile = _onlyRequiresFile(script.commands);

    if (onlyFile && staged != null && staged.trim().isNotEmpty) {
      onRun?.call(script, {'file': staged});
    } else {
      _showInputDialog(context, script);
    }
  }

  void _showInputDialog(BuildContext context, ScriptEntity script) {
    final keys = _extractInputKeys(script.commands);
    final hasSingle = _hasSingleInput(script.commands);
    final hasFile = _hasFileInput(script.commands);

    showDialog<Map<String, String>?>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => _UnifiedInputDialog(
        script: script,
        keys: keys,
        hasSingleInput: hasSingle,
        hasFileInput: hasFile,
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
  final bool hasFileInput;

  const _UnifiedInputDialog({
    required this.script,
    required this.keys,
    required this.hasSingleInput,
    required this.hasFileInput,
  });

  @override
  State<_UnifiedInputDialog> createState() => _UnifiedInputDialogState();
}

class _UnifiedInputDialogState extends State<_UnifiedInputDialog> {
  final Map<String, TextEditingController> _multiControllers = {};
  late final TextEditingController _singleController;
  late final TextEditingController _fileController;
  final _formKey = GlobalKey<FormState>();

  bool _isFileDragOver = false;

  @override
  void initState() {
    super.initState();
    _singleController = TextEditingController();
    _fileController = TextEditingController();
    for (final key in widget.keys) {
      _multiControllers[key] = TextEditingController();
    }

    // Prefill file paths if staged in store
    final staged = getIt<ScriptManagementStore>().stagedFiles[widget.script.id];
    if (staged != null) {
      _fileController.text = staged;
    }
  }

  @override
  void dispose() {
    _singleController.dispose();
    _fileController.dispose();
    for (final controller in _multiControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final files = await openFiles();
      if (files.isNotEmpty) {
        final paths = files.map((f) => f.path).join('\n');
        setState(() {
          _fileController.text = paths;
        });
      }
    } catch (e) {
      debugPrint('[UnifiedInputDialog] Failed to pick files: $e');
    }
  }

  void _handleConfirm() {
    if (!widget.hasSingleInput && widget.keys.isEmpty && !widget.hasFileInput) {
      Navigator.pop(context, <String, String>{});
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final args = <String, String>{};
      if (widget.hasSingleInput) {
        args['input'] = _singleController.text;
      }
      if (widget.hasFileInput) {
        args['file'] = _fileController.text;
        // Sync user input file paths back to the store
        getIt<ScriptManagementStore>().stageFile(widget.script.id, _fileController.text);
      }
      for (final entry in _multiControllers.entries) {
        args[entry.key] = entry.value.text;
      }
      Navigator.pop(context, args);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showWarning = !widget.hasSingleInput && widget.keys.isEmpty && !widget.hasFileInput;

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
                      (widget.keys.isNotEmpty || widget.hasFileInput)
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
                                  'Script này chưa khai báo tham số {input}, {input:tên_biến} hoặc {file} trong câu lệnh.',
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

                      // 1. File Input {file}
                      if (widget.hasFileInput) ...[
                        Text(
                          'ĐƯỜNG DẪN FILE {file}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropRegion(
                          formats: const [Formats.fileUri],
                          onDropEnter: (_) => setState(() => _isFileDragOver = true),
                          onDropLeave: (_) => setState(() => _isFileDragOver = false),
                          onDropOver: (event) {
                            final canAccept = event.session.items.any(
                              (item) => item.dataReader?.canProvide(Formats.fileUri) == true,
                            );
                            return canAccept ? DropOperation.copy : DropOperation.none;
                          },
                          onPerformDrop: (event) async {
                            setState(() => _isFileDragOver = false);
                            final paths = <String>[];
                            for (final item in event.session.items) {
                              final reader = item.dataReader;
                              if (reader != null && reader.canProvide(Formats.fileUri)) {
                                final completer = Completer<Uri?>();
                                final dynamic dReader = reader;
                                void callback(Object? value) {
                                  if (!completer.isCompleted) {
                                    completer.complete(value as Uri?);
                                  }
                                }
                                dReader.getValue(Formats.fileUri, callback);
                                final uri = await completer.future;
                                if (uri != null && uri.isScheme('file')) {
                                  final path = Uri.decodeComponent(uri.toFilePath());
                                  paths.add(path);
                                }
                              }
                            }
                            if (paths.isNotEmpty) {
                              setState(() {
                                _fileController.text = paths.join('\n');
                              });
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: _isFileDragOver
                                  ? const Color(0xFF4F46E5).withValues(alpha: 0.04)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isFileDragOver
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFE2E8F0),
                                width: _isFileDragOver ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _fileController,
                                  maxLines: 5,
                                  minLines: 3,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Nhập hoặc kéo thả đường dẫn file...\nMỗi file một dòng.',
                                    hintStyle: GoogleFonts.outfit(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                    errorStyle: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Vui lòng nhập hoặc chọn file';
                                    }
                                    return null;
                                  },
                                ),
                                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _isFileDragOver ? 'Thả để nạp file!' : 'Kéo thả file vào ô nhập này',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: _isFileDragOver ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                            fontWeight: _isFileDragOver ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: _pickFiles,
                                        icon: const Icon(Icons.file_open_rounded, size: 14),
                                        label: const Text('Chọn file'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFF4F46E5),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
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
                        if (widget.keys.isNotEmpty || widget.hasSingleInput) const SizedBox(height: 24),
                      ],

                      // 2. Single Input {input}
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
                          autofocus: !showWarning && widget.keys.isEmpty && !widget.hasFileInput,
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

                      // 3. Multi Input {input:khóa}
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
                                      !widget.hasFileInput &&
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
