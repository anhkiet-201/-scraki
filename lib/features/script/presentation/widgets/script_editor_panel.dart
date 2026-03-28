import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF), // Indigo 50
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFF4F46E5), // Indigo 600
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A), // Slate 900
                        ),
                      ),
                      Text(
                        'Chỉnh sửa và lưu script lên Cloud',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF64748B), // Slate 500
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => widget.store.setEditingScript(null),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9), // Slate 100
                    foregroundColor: const Color(0xFF64748B), // Slate 500
                  ),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Đóng editor',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Tên Script'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Ví dụ: Dọn dẹp cache hệ thống',
                    onChanged: (_) => _onChanged(),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildLabel('Mô tả ngắn'),
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
                      _buildLabel('Danh sách lệnh ADB Shell'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC), // Slate 50
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          'Mỗi dòng 1 lệnh',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Code Area
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC), // Slate 50
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        // Tool bar cho editor
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              _editorTool(Icons.play_arrow_rounded, 'Chạy thử', () {}),
                              const SizedBox(width: 8),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: () => widget.store.saveCurrentScript(),
                                icon: const Icon(Icons.save_rounded, size: 16),
                                label: const Text('Lưu vào Cloud'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                  textStyle: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        TextField(
                          controller: _commandsController,
                          maxLines: null,
                          minLines: 15,
                          onChanged: (_) => _onChanged(),
                          style: GoogleFonts.firaCode(
                            fontSize: 13,
                            color: const Color(0xFF334155), // Slate 700
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: '# Nhập lệnh adb shell...\npm list packages\nam start -n ...',
                            hintStyle: GoogleFonts.firaCode(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8), // Slate 400
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Text(
                        'Dùng {{input}} để yêu cầu nhập dữ liệu khi chạy',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: const Color(0xFF64748B), // Slate 500
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
      style: GoogleFonts.outfit(
        fontSize: 14,
        color: const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
          fontSize: 14,
          color: const Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
        ),
      ),
    );
  }

  Widget _editorTool(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
