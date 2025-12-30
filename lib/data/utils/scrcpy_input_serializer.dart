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
    // We send an 8-byte long. Converting pointerId to bytes.
    // Assuming pointerId fits in standard int, we pad to 64-bit.
    final pointerData = ByteData(8);
    pointerData.setInt64(0, pointerId, Endian.big);
    buffer.add(pointerData.buffer.asUint8List());

    // 4. Position (4 bytes x 2)
    // X and Y are int32
    final posData = ByteData(8);
    posData.setInt32(0, x, Endian.big);
    posData.setInt32(4, y, Endian.big);
    buffer.add(posData.buffer.asUint8List());

    // 5. Pressure (2 bytes)
    // int16. 0xFFFF for max (most touches), 0 for up?
    // Protocol usually sends pressure. Normalized 0..1 in float? No, usually int16.
    // 0xFFFF is safe default for "pressed".
    final pressureData = ByteData(2);
    int pressure = (action == actionUp) ? 0 : 0xFFFF;
    pressureData.setUint16(0, pressure, Endian.big);
    buffer.add(pressureData.buffer.asUint8List());

    // 6. Buttons (4 bytes)
    // int32. Secondary click etc.
    // 1: Primary (Left)
    // 0: None
    final buttonsData = ByteData(4);
    int buttons = (action == actionUp) ? 0 : 1;
    buttonsData.setInt32(0, buttons, Endian.big);
    buffer.add(buttonsData.buffer.asUint8List());

    return buffer.toBytes();
  }
}
