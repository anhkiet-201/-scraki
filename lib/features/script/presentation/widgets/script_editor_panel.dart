import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobx/mobx.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/styles/vs2015.dart';
import '../utils/scraki_bash_lang.dart';
import '../utils/shell_autocomplete_builder.dart';
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import '../stores/script_management_store.dart';

class ScriptEditorPanel extends StatefulWidget {
  const ScriptEditorPanel({super.key});

  @override
  State<ScriptEditorPanel> createState() => _ScriptEditorPanelState();
}

class _ScriptEditorPanelState extends State<ScriptEditorPanel> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late CodeLineEditingController _commandsController;
  final ScriptManagementStore _store = inject<ScriptManagementStore>();

  String? _loadedScriptId;
  ScriptTileType _selectedTileType = ScriptTileType.normal;
  bool _enableFileDrop = false;

  ReactionDisposer? _disposer;

  @override
  void initState() {
    super.initState();
    _initControllers();

    // Sync state when editingScript changes in store
    _disposer = reaction(
      (_) => _store.editingScript,
      (script) {
        if (!mounted) return;

        setState(() {
          // Only reset controllers if switching to a different script (avoids cursor jump)
          if (_loadedScriptId != script?.id) {
            _nameController.text = script?.name ?? '';
            _descController.text = script?.description ?? '';
            _commandsController.text = script?.commands.join('\n') ?? '';
            _loadedScriptId = script?.id;
          }

          // Always sync UI flags
          _selectedTileType = script?.tileType ?? ScriptTileType.normal;
          _enableFileDrop = script?.enableFileDrop ?? false;
        });
      },
      fireImmediately: true,
    );
  }

  void _initControllers() {
    final script = _store.editingScript;
    _nameController = TextEditingController(text: script?.name ?? '');
    _descController = TextEditingController(text: script?.description ?? '');
    _commandsController = CodeLineEditingController.fromText(
      script?.commands.join('\n') ?? '',
    );
    _loadedScriptId = script?.id;
    _selectedTileType = script?.tileType ?? ScriptTileType.normal;
    _enableFileDrop = script?.enableFileDrop ?? false;

    _commandsController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _commandsController.removeListener(_onCodeChanged);
    _commandsController.dispose();
    _disposer?.call();
    super.dispose();
  }

  void _onCodeChanged() {
    final text = _commandsController.text;
    final commands =
        text.split('\n').where((s) => s.trim().isNotEmpty).toList();

    if (_store.editingScript != null) {
      final currentCommands = _store.editingScript!.commands;
      bool isSame = currentCommands.length == commands.length;
      if (isSame) {
        for (int i = 0; i < commands.length; i++) {
          if (commands[i] != currentCommands[i]) {
            isSame = false;
            break;
          }
        }
      }
      if (!isSame) {
        _onChanged();
      }
    }
  }

  void _onChanged() {
    _store.updateEditingScript(
      name: _nameController.text,
      description: _descController.text,
      commands: _commandsController.text
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .toList(),
      tileType: _selectedTileType,
      enableFileDrop: _enableFileDrop,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cột trái: Vùng soạn thảo chính (Editor)
                Expanded(
                  flex: 7,
                  child: _buildEditorSection(),
                ),
                // Đường phân cách dọc
                const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                // Cột phải: Sidebar cấu hình
                SizedBox(
                  width: 340,
                  child: _buildSidebarSection(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 20, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.terminal_rounded,
              color: Color(0xFF4F46E5),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trình soạn thảo Script',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Tùy chỉnh lệnh và cấu hình cách hiển thị kịch bản',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _store.setEditingScript(null),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              foregroundColor: const Color(0xFF64748B),
              padding: const EdgeInsets.all(10),
            ),
            icon: const Icon(Icons.close_rounded, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditorToolbar(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildCommandEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorToolbar() {
    return Row(
      children: [
        const Icon(
          Icons.code_rounded,
          size: 20,
          color: Color(0xFF818CF8),
        ),
        const SizedBox(width: 10),
        Text(
          'adb_shell.sh',
          style: GoogleFonts.firaCode(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        const Spacer(),
        // Nút Sao chép nhanh
        IconButton(
          onPressed: _copyToClipboard,
          tooltip: 'Sao chép mã',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9),
            foregroundColor: const Color(0xFF475569),
            padding: const EdgeInsets.all(8),
          ),
          icon: const Icon(Icons.copy_all_rounded, size: 18),
        ),
        const SizedBox(width: 8),
        // Nút Xóa sạch code
        IconButton(
          onPressed: _clearCode,
          tooltip: 'Xóa sạch kịch bản',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFFEE2E2),
            foregroundColor: const Color(0xFFEF4444),
            padding: const EdgeInsets.all(8),
          ),
          icon: const Icon(Icons.delete_sweep_rounded, size: 18),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {
            _store.saveCurrentScript();
            _store.setEditingScript(null);
          },
          icon: const Icon(Icons.cloud_upload_rounded, size: 16),
          label: const Text('Lưu Script'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarSection() {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Thông tin cơ bản'),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Tên Script',
              controller: _nameController,
              hint: 'Ví dụ: Dọn dẹp cache hệ thống',
              onChanged: (_) => _onChanged(),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Mô tả',
              controller: _descController,
              hint: 'Mô tả công dụng kịch bản...',
              maxLines: 3,
              onChanged: (_) => _onChanged(),
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('Cấu hình hiển thị (Tile)'),
            const SizedBox(height: 16),
            _buildTileSettings(),
            const SizedBox(height: 28),
            _buildSectionTitle('Trợ giúp nhanh'),
            const SizedBox(height: 12),
            _buildHint(
              'Dùng {input} cho ô nhập đơn lẻ hoặc {input:tên_biến} để tạo nhiều ô nhập dữ liệu.',
            ),
            const SizedBox(height: 8),
            _buildHint(
              'Có thể kéo thả file trực tiếp vào tile nếu chế độ kéo thả được kích hoạt.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
              color: const Color(0xFF94A3B8),
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTileSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.security_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                'Xác nhận',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              const Spacer(),
              _buildTypeChip('Normal', ScriptTileType.normal),
              const SizedBox(width: 4),
              _buildTypeChip('Inline', ScriptTileType.confirm),
              const SizedBox(width: 4),
              _buildTypeChip('Dialog', ScriptTileType.dialog),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFE2E8F0)),
          ),
          Row(
            children: [
              const Icon(
                Icons.file_download_outlined,
                size: 18,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kéo thả file',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    Text(
                      'Kéo file từ PC vào tile',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _enableFileDrop,
                activeTrackColor: const Color(0xFF4F46E5).withValues(alpha: 0.5),
                activeThumbColor: const Color(0xFF4F46E5),
                onChanged: (val) {
                  setState(() => _enableFileDrop = val);
                  _onChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, ScriptTileType type) {
    final isSelected = _selectedTileType == type;
    return InkWell(
      onTap: () {
        setState(() => _selectedTileType = type);
        _onChanged();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildCommandEditor() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Slate 900
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CodeAutocomplete(
          viewBuilder: (context, notifier, onSelected) {
            return PreferredSize(
              preferredSize: const Size(250, 200),
              child: ValueListenableBuilder<CodeAutocompleteEditingValue>(
                valueListenable: notifier,
                builder: (context, value, child) {
                  final prompts = value.prompts;
                  if (prompts.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      color: Colors.transparent,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        shrinkWrap: true,
                        itemCount: prompts.length,
                        itemBuilder: (context, index) {
                          final prompt = prompts[index];
                          return InkWell(
                            onTap: () {
                              onSelected(
                                CodeAutocompleteResult.fromWord(
                                  prompt.word,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.code_rounded,
                                    size: 14,
                                    color: Color(0xFF818CF8),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      prompt.word,
                                      style: GoogleFonts.firaCode(
                                        fontSize: 12,
                                        color: const Color(0xFFF1F5F9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          },
          promptsBuilder: ShellAutocompletePromptsBuilder([
            const CodeKeywordPrompt(word: 'adb'),
            const CodeKeywordPrompt(word: 'shell'),
            const CodeKeywordPrompt(word: 'am'),
            const CodeKeywordPrompt(word: 'pm'),
            const CodeKeywordPrompt(word: 'monkey'),
            const CodeKeywordPrompt(word: 'screencap'),
            const CodeKeywordPrompt(word: 'screenrecord'),
            const CodeKeywordPrompt(word: 'input'),
            const CodeKeywordPrompt(word: 'tap'),
            const CodeKeywordPrompt(word: 'swipe'),
            const CodeKeywordPrompt(word: 'keyevent'),
            const CodeKeywordPrompt(word: 'text'),
            const CodeKeywordPrompt(word: 'install'),
            const CodeKeywordPrompt(word: 'uninstall'),
            const CodeKeywordPrompt(word: 'clear'),
            const CodeKeywordPrompt(word: 'force-stop'),
            const CodeKeywordPrompt(word: 'start'),
            const CodeKeywordPrompt(word: 'sleep'),
            const CodeKeywordPrompt(word: 'echo'),
            const CodeKeywordPrompt(word: 'grep'),
            const CodeKeywordPrompt(word: 'logcat'),
            const CodeKeywordPrompt(word: 'bugreport'),
            const CodeKeywordPrompt(word: 'reboot'),

            // Scraki Directives
            const CodeKeywordPrompt(word: '#bash'),
            const CodeKeywordPrompt(word: '#bash server'),
            const CodeKeywordPrompt(word: '#run-script'),
            const CodeKeywordPrompt(word: '#end'),

            // Placeholder variables
            const PlaceholderPrompt(
              word: '{input}',
              displayName: '{input}',
              insertText: '{input}',
              baseSelectOffset: 7,
              extentSelectOffset: 7,
            ),
            const PlaceholderPrompt(
              word: '{input:tên_biến}',
              displayName: '{input:tên_biến}',
              insertText: '{input:tên_biến}',
              baseSelectOffset: 7,
              extentSelectOffset: 15,
            ),
            const PlaceholderPrompt(
              word: '{SERIAL}',
              displayName: '{SERIAL}',
              insertText: '{SERIAL}',
              baseSelectOffset: 8,
              extentSelectOffset: 8,
            ),
            const PlaceholderPrompt(
              word: '{I}',
              displayName: '{I} (IP octet 4)',
              insertText: '{I}',
              baseSelectOffset: 3,
              extentSelectOffset: 3,
            ),
            const PlaceholderPrompt(
              word: '{index}',
              displayName: '{index}',
              insertText: '{index}',
              baseSelectOffset: 7,
              extentSelectOffset: 7,
            ),
            const PlaceholderPrompt(
              word: '{file}',
              displayName: '{file}',
              insertText: '{file}',
              baseSelectOffset: 6,
              extentSelectOffset: 6,
            ),
            const PlaceholderPrompt(
              word: '{random(max)}',
              displayName: '{random(max)}',
              insertText: '{random(max)}',
              baseSelectOffset: 8,
              extentSelectOffset: 11,
            ),
          ]),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CodeEditor(
              controller: _commandsController,
              wordWrap: true,
              indicatorBuilder: (
                context,
                editingController,
                chunkController,
                notifier,
              ) {
                return Row(
                  children: [
                    DefaultCodeLineNumber(
                      controller: editingController,
                      notifier: notifier,
                    ),
                    const SizedBox(width: 8),
                  ],
                );
              },
              style: CodeEditorStyle(
                fontSize: 13,
                textColor: const Color(0xFFE2E8F0),
                fontFamily: GoogleFonts.firaCode().fontFamily,
                backgroundColor: const Color(0xFF0F172A),
                codeTheme: CodeHighlightTheme(
                  languages: {
                    'bash': CodeHighlightThemeMode(mode: scrakiBashLang),
                  },
                  theme: vs2015Theme,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard() {
    final text = _commandsController.text;
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép mã nguồn kịch bản vào bộ nhớ tạm!'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void _clearCode() {
    final text = _commandsController.text;
    if (text.trim().isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Xóa sạch kịch bản',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa toàn bộ nội dung kịch bản hiện tại không?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Hủy', style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              _commandsController.text = '';
              Navigator.of(ctx).pop();
              _onChanged();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text('Xóa sạch', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  Widget _buildHint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.lightbulb_outline_rounded,
            size: 15,
            color: Color(0xFF818CF8),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}
