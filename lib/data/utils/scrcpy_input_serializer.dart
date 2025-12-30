import 'dart:typed_data';

abstract class ControlMessage {
  Uint8List serialize();
}

class TouchControlMessage extends ControlMessage {
  static const int typeInjectTouchEvent = 2; // 0x02

  static const int actionDown = 0;
  static const int actionUp = 1;
  static const int actionMove = 2;

  final int action;
  final int x;
  final int y;
  final int width;
  final int height;
  final int pointerId; // Default 0 for mouse/finger 1

  TouchControlMessage({
    required this.action,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.pointerId = 0, // Default to 0 (Mouse or first finger)
  });

  @override
  Uint8List serialize() {
    final buffer = BytesBuilder();

    // 1. Type (1 byte)
    buffer.addByte(typeInjectTouchEvent);

    // 2. Action (1 byte)
    // 00: Down, 01: Up, 02: Move
    buffer.addByte(action);

    // 3. Pointer ID (8 bytes)
    final pointerData = ByteData(8);
    pointerData.setInt64(0, pointerId, Endian.big);
    buffer.add(pointerData.buffer.asUint8List());

    // 4. Position (12 bytes total)
    // X (4), Y (4), Width (2), Height (2)
    final posData = ByteData(12);
    posData.setInt32(0, x, Endian.big);
    posData.setInt32(4, y, Endian.big);
    posData.setUint16(8, width, Endian.big);
    posData.setUint16(10, height, Endian.big);
    buffer.add(posData.buffer.asUint8List());

    // 5. Pressure (2 bytes)
    final pressureData = ByteData(2);
    int pressure = (action == actionUp) ? 0 : 0xFFFF;
    pressureData.setUint16(0, pressure, Endian.big);
    buffer.add(pressureData.buffer.asUint8List());

    // 6. Action Button (4 bytes)
    // For touch, usually 0 or same as buttons?
    // Scrcpy v2+ adds this. Default to 0 or 1?
    // Usually 0 for pure touch, but 1 for "primary" like mouse?
    // Let's use 1 if pressed, 0 if up, same as buttons.
    final actionButtonData = ByteData(4);
    int actionButton = (action == actionUp) ? 0 : 1;
    actionButtonData.setInt32(0, actionButton, Endian.big);
    buffer.add(actionButtonData.buffer.asUint8List());

    // 7. Buttons (4 bytes)
    final buttonsData = ByteData(4);
    int buttons = (action == actionUp) ? 0 : 1;
    buttonsData.setInt32(0, buttons, Endian.big);
    buffer.add(buttonsData.buffer.asUint8List());

    return buffer.toBytes();
  }
}
