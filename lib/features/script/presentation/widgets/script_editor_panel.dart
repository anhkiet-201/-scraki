import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scraki/core/widgets/box_card.dart';
import '../stores/script_store.dart';

class ScriptEditorPanel extends StatefulWidget {
  final ScriptStore store;

  const ScriptEditorPanel({super.key, required this.store});

  @override
  State<ScriptEditorPanel> createState() => _ScriptEditorPanelState();
}

class _ScriptEditorPanelState extends State<ScriptEditorPanel> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _commandsController;

  @override
  void initState() {
    super.initState();
    final script = widget.store.editingScript;
    _nameController = TextEditingController(text: script?.name ?? '');
    _descController = TextEditingController(text: script?.description ?? '');
    _commandsController = TextEditingController(text: script?.commands.join('\n') ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _commandsController.dispose();
    super.dispose();
  }

  void _onChanged() {
    widget.store.updateEditingScript(
      name: _nameController.text,
      description: _descController.text,
      commands: _commandsController.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BoxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Trình soạn thảo Script',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => widget.store.setEditingScript(null),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Đóng editor',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(theme, 'Tên Script'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Ví dụ: Dọn dẹp cache máy chủ',
                    onChanged: (_) => _onChanged(),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildLabel(theme, 'Mô tả'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _descController,
                    hint: 'Mô tả ngắn gọn công dụng...',
                    maxLines: 2,
                    onChanged: (_) => _onChanged(),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel(theme, 'Các lệnh ADB Shell (Mỗi dòng 1 lệnh)'),
                      Text(
                        'Hỗ trợ: {{input}} cho biến động',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Code Area
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        // Tool bar cho editor
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: Row(
                            children: [
                              _editorTool(theme, Icons.play_arrow_rounded, 'Chạy thử', () {}),
                              const SizedBox(width: 8),
                              _editorTool(theme, Icons.save_rounded, 'Lưu Script', () => widget.store.saveCurrentScript()),
                            ],
                          ),
                        ),
                        TextField(
                          controller: _commandsController,
                          maxLines: null,
                          minLines: 10,
                          onChanged: (_) => _onChanged(),
                          style: GoogleFonts.firaCode(
                            fontSize: 13,
                            color: const Color(0xFF1E293B),
                          ),
                          decoration: const InputDecoration(
                            hintText: '# Nhập các lệnh adb shell tại đây...\npm clear com.example.app\nam start ...',
                            contentPadding: EdgeInsets.all(16),
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
    );
  }

  Widget _editorTool(ThemeData theme, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
