import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimeInputField extends StatefulWidget {
  final String label;
  final double? initialValue;
  final void Function(double?) onChanged;
  final String? hint;

  const TimeInputField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.hint,
  });

  @override
  State<TimeInputField> createState() => _TimeInputFieldState();
}

class _TimeInputFieldState extends State<TimeInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue != null ? _formatValue(widget.initialValue!) : '',
    );
  }

  String _formatValue(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  void didUpdateWidget(TimeInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      final text = widget.initialValue != null ? _formatValue(widget.initialValue!) : '';
      if (_controller.text != text) {
        _controller.text = text;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _adjustValue(double delta) {
    final current = double.tryParse(_controller.text) ?? 0.0;
    final newValue = (current + delta).clamp(0.0, 9999.0);
    final text = _formatValue(newValue);
    _controller.text = text;
    widget.onChanged(newValue);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Colors.white38,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              _buildAdjustButton(
                icon: Icons.remove_rounded,
                onPressed: () => _adjustValue(-0.1),
              ),
              const VerticalDivider(width: 1, color: Colors.white10),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TextField(
                      controller: _controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                        contentPadding: const EdgeInsets.only(left: 4, right: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (v) {
                        final d = double.tryParse(v);
                        widget.onChanged(d);
                      },
                    ),
                    Positioned(
                      right: 6,
                      child: IgnorePointer(
                        child: Text(
                          's',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.15),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1, color: Colors.white10),
              _buildAdjustButton(
                icon: Icons.add_rounded,
                onPressed: () => _adjustValue(0.1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdjustButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        onLongPress: () {
          // TODO: Tự động tăng/giảm khi nhấn giữ nếu cần
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: double.infinity,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: Colors.white54),
        ),
      ),
    );
  }
}
