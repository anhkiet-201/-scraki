import 'package:flutter/material.dart';
import 'phone_view.dart';

class FloatingPhoneView extends StatefulWidget {
  final String serial;
  final VoidCallback onClose;

  const FloatingPhoneView({
    super.key,
    required this.serial,
    required this.onClose,
  });

  @override
  State<FloatingPhoneView> createState() => _FloatingPhoneViewState();
}

class _FloatingPhoneViewState extends State<FloatingPhoneView> {
  Offset _position = const Offset(100, 100);
  double _width = 300;
  double _height = 650;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.white24, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _position += details.delta;
                  });
                },
                child: Container(
                  height: 40,
                  color: Colors.grey[900],
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.drag_handle,
                        size: 20,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mirror: ${widget.serial}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white70,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: PhoneView(
                  serial: widget.serial,
                  fit: BoxFit.contain,
                  isFloating: true,
                ),
              ),
              // Resize handle
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _width = (_width + details.delta.dx).clamp(200.0, 800.0);
                    _height = (_height + details.delta.dy).clamp(400.0, 1200.0);
                  });
                },
                child: Container(
                  height: 12,
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(Icons.height, size: 12, color: Colors.white38),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
