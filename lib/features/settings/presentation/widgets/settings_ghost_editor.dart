import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

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
  late List<String> _lines;
  final Map<int, FocusNode> _focusNodes = {};
  final Map<int, TextEditingController> _rowControllers = {};

  @override
  void initState() {
    super.initState();
    _parseLines();
    widget.controller.addListener(_onMainControllerChanged);
  }

  void _parseLines() {
    _lines = widget.controller.text.split('\n');
    if (_lines.isEmpty) _lines = [''];
  }

  void _onMainControllerChanged() {
    // Only update if external source changed the text significantly
    final newText = widget.controller.text;
    if (newText != _lines.join('\n')) {
      setState(() {
        _parseLines();
        // Clear caches to force rebuild with new data
        _rowControllers.values.forEach((c) => c.dispose());
        _rowControllers.clear();
      });
    }
  }

  TextEditingController _getRowController(int index) {
    if (!_rowControllers.containsKey(index)) {
      final controller = _GhostRowController(text: _lines[index]);
      controller.addListener(() {
        _lines[index] = controller.text;
        _syncToMain();
      });
      _rowControllers[index] = controller;
    }
    return _rowControllers[index]!;
  }

  FocusNode _getFocusNode(int index) {
    if (!_focusNodes.containsKey(index)) {
      final node = FocusNode(onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _focusLine(index + 1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _focusLine(index + 1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _focusLine(index - 1);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      });
      _focusNodes[index] = node;
    }
    return _focusNodes[index]!;
  }

  void _focusLine(int index) {
    if (index >= 0 && index < _lines.length) {
      _getFocusNode(index).requestFocus();
    } else if (index == _lines.length) {
      // Add new line on Enter at last line
      setState(() {
        _lines.add('');
        _syncToMain();
      });
      Future.delayed(Duration.zero, () => _getFocusNode(index).requestFocus());
    }
  }

  void _syncToMain() {
    final newText = _lines.join('\n');
    if (widget.controller.text != newText) {
      widget.controller.removeListener(_onMainControllerChanged);
      widget.controller.text = newText;
      widget.controller.addListener(_onMainControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onMainControllerChanged);
    _rowControllers.values.forEach((c) => c.dispose());
    _focusNodes.values.forEach((n) => n.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = widget.isLight;
    final borderColor = isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white10;
    final gutterColor = isLight ? const Color(0xFFF8FAFC) : Colors.white.withValues(alpha: 0.02);
    
    const double fontSize = 13.0;
    const double rowHeight = 24.0; // Compact IDE height

    return Container(
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        color: isLight ? Colors.white : const Color(0xFF0F172A),
      ),
      child: TableView.builder(
        pinnedColumnCount: 1,
        columnCount: 2,
        rowCount: _lines.length,
        columnBuilder: (index) => TableSpan(
          extent: index == 0 ? const FixedTableSpanExtent(44) : const FixedTableSpanExtent(4000),
        ),
        rowBuilder: (index) => const TableSpan(
          extent: FixedTableSpanExtent(rowHeight),
        ),
        cellBuilder: (context, vicinity) {
          if (vicinity.column == 0) {
            // Line Number Gutter
            return TableViewCell(
              child: Container(
                color: gutterColor,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${vicinity.row + 1}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: isLight ? const Color(0xFF94A3B8) : Colors.white24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }
          
          // Main Editor Content
          return TableViewCell(
            child: TextField(
              controller: _getRowController(vicinity.row),
              focusNode: _getFocusNode(vicinity.row),
              maxLines: 1,
              cursorColor: const Color(0xFF6366F1),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: fontSize,
                height: 1.0, // Managed by cell height
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GhostRowController extends TextEditingController {
  _GhostRowController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> children = [];
    final List<Color> segmentColors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Emerald 
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFD946EF), // Fuchsia
    ];

    final matches = RegExp(r'([^|]+)|(\|)').allMatches(text);
    int segmentIndex = 0;
    
    for (final match in matches) {
      if (match.group(2) != null) {
        children.add(TextSpan(
          text: '|',
          style: style?.copyWith(
            color: Colors.grey.withValues(alpha: 0.3),
            fontWeight: FontWeight.bold,
          ),
        ));
        segmentIndex++;
      } else {
        final color = segmentColors[segmentIndex % segmentColors.length];
        children.add(TextSpan(
          text: match.group(0),
          style: style?.copyWith(color: color),
        ));
      }
    }
    return TextSpan(style: style, children: children);
  }
}
