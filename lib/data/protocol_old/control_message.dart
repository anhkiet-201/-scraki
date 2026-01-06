import 'dart:typed_data';

class ControlMessage {
  static const int typeInjectTouchEvent = 2; // 0x02

  static const int actionDown = 0;
  static const int actionUp = 1;
  static const int actionMove = 2;

  static List<int> createTouch({
    required int action,
    required int x,
    required int y,
    required int
    width, // screen width (not used in packet structure based on prompt?)
    required int height, // screen height (not used?)
    // Prompt structure: Type(1), Action(1), PointerId(8), X(4), Y(4), Pressure(2), Buttons(4)
    // Wait, the prompt didn't mention Width/Height in the PACKET. It mentioned them in the Header.
    // The packet is just X, Y.
    int pointerId = 0, // Mouse usually 0, fingers 1+
  }) {
    final buffer = BytesBuilder();

    // Type (1 byte)
    buffer.addByte(typeInjectTouchEvent);

    // Action (1 byte)
    buffer.addByte(action);

    // Pointer ID (8 bytes) - Using 0 for now
    buffer.add([0, 0, 0, 0, 0, 0, 0, 0]); // Int64(0)

    // Position (4 bytes x 2)
    final posData = ByteData(8);
    posData.setInt32(0, x, Endian.big);
    posData.setInt32(4, y, Endian.big);
    buffer.add(posData.buffer.asUint8List());

    // Pressure (2 bytes) - 0xFFFF (max)
    final pressureData = ByteData(2);
    pressureData.setUint16(0, 0xFFFF, Endian.big);
    buffer.add(pressureData.buffer.asUint8List());

    // Buttons (4 bytes) - 1 (Primary/Left) or 0?
    // Usually 1 for "pressed" state, depends on action.
    // Down/Move = 1, Up = 0?
    // Let's assume 1 for active touch.
    final buttonsData = ByteData(4);
    buttonsData.setInt32(0, 1, Endian.big); // Primary button
    buffer.add(buttonsData.buffer.asUint8List());

    return buffer.toBytes();
  }
}
