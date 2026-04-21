import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsGhostEditor extends StatefulWidget {
  final TextEditingController controller;
  final double height;
  final bool isLight;

  const SettingsGhostEditor({
    super.key,
    required this.controller,
    this.height = 450,
    required this.isLight,
  });

  @override
  State<SettingsGhostEditor> createState() => _SettingsGhostEditorState();
}

class _SettingsGhostEditorState extends State<SettingsGhostEditor> {
  late final ScrollController _scrollController;
  late final ScrollController _lineNumbersController;
  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _lineNumbersController = ScrollController();
    
    // Sync scroll
    _scrollController.addListener(() {
      if (_lineNumbersController.hasClients) {
        _lineNumbersController.jumpTo(_scrollController.offset);
      }
    });

    _updateLineCount();
    widget.controller.addListener(_updateLineCount);
  }

  void _updateLineCount() {
    final text = widget.controller.text;
    if (text.isEmpty) {
      if (_lineCount != 1) setState(() => _lineCount = 1);
      return;
    }
    
    int count = 1;
    for (int i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 10) count++; // 10 is '\n'
    }

    if (count != _lineCount) {
      if (mounted) {
        setState(() {
          _lineCount = count;
        });
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateLineCount);
    _scrollController.dispose();
    _lineNumbersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = widget.isLight;
    final borderColor = isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white10;
    final gutterColor = isLight ? const Color(0xFFF8FAFC) : Colors.white.withValues(alpha: 0.02);
    
    const double fontSize = 13.0;
    const double lineHeight = 1.5;

    return Container(
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        color: isLight ? Colors.white : const Color(0xFF0F172A),
        boxShadow: isLight 
          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))] 
          : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gutter (Line Numbers)
          Container(
            width: 48,
            color: gutterColor,
            child: ListView.builder(
              controller: _lineNumbersController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _lineCount,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemBuilder: (context, index) {
                return Container(
                  height: fontSize * lineHeight,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: isLight ? const Color(0xFF94A3B8) : Colors.white24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
          ),

          // Main Editor
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: const Color(0xFF6366F1),
                  selectionColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  selectionHandleColor: const Color(0xFF6366F1),
                ),
              ),
              child: Scrollbar(
                controller: _scrollController,
                child: TextField(
                  controller: widget.controller,
                  scrollController: _scrollController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  cursorWidth: 2,
                  style: GoogleFonts.firaCode(
                    fontSize: fontSize,
                    height: lineHeight,
                    color: isLight ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
