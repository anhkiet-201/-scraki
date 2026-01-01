import 'package:flutter/material.dart';
import '../phone_view/phone_view.dart';

class FloatingPhoneView extends StatefulWidget {
  final String serial;
  final VoidCallback onClose;
  final Size parentSize;

  const FloatingPhoneView({
    super.key,
    required this.serial,
    required this.onClose,
    required this.parentSize,
  });

  @override
  State<FloatingPhoneView> createState() => _FloatingPhoneViewState();
}

class _FloatingPhoneViewState extends State<FloatingPhoneView> {
  Offset _position = const Offset(100, 100);
  double _width = 480;
  double _height = 1000;

  @override
  void initState() {
    super.initState();
    // Don't clamp initially - constraints only apply during drag
  }

  @override
  void didUpdateWidget(FloatingPhoneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Parent size changes are handled automatically by constraints during drag
  }

  Offset _getClampedPosition(Offset target) {
    if (widget.parentSize.isEmpty) {
      return target;
    }

    final maxX = widget.parentSize.width - _width;
    final maxY = widget.parentSize.height - _height;

    return Offset(
      target.dx.clamp(0.0, maxX > 0 ? maxX : 0.0),
      target.dy.clamp(0.0, maxY > 0 ? maxY : 0.0),
    );
  }

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
              Container(
                height: 40,
                color: Colors.grey[900],
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _position = _getClampedPosition(
                        _position + details.delta,
                      );
                    });
                  },
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
                    final newWidth = (_width + details.delta.dx).clamp(
                      200.0,
                      1200.0,
                    );
                    final newHeight = (_height + details.delta.dy).clamp(
                      400.0,
                      1600.0,
                    );

                    // Update size
                    _width = newWidth;
                    _height = newHeight;

                    // Constraint: Ensure window doesn't extend beyond parent bounds
                    // But maintain minimum size
                    if (!widget.parentSize.isEmpty) {
                      final maxAllowedWidth =
                          widget.parentSize.width - _position.dx;
                      final maxAllowedHeight =
                          widget.parentSize.height - _position.dy;

                      if (maxAllowedWidth > 200) {
                        _width = _width.clamp(200.0, maxAllowedWidth);
                      }

                      if (maxAllowedHeight > 400) {
                        _height = _height.clamp(400.0, maxAllowedHeight);
                      }
                    }
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
