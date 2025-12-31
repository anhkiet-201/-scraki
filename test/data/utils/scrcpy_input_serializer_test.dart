import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:scraki/data/utils/scrcpy_input_serializer.dart';

void main() {
  group('ScrcpyInputSerializer', () {
    test('TouchControlMessage serialize structure', () {
      final msg = TouchControlMessage(
        action: TouchControlMessage.actionDown,
        x: 100,
        y: 200,
        width: 1080,
        height: 2400,
        buttons: 1,
      );

      final bytes = msg.serialize();

      // Expected size:
      // Type (1) + Action (1) + PointerId(8) + Pos(12) + Pressure(2) + ActionButton(4) + Buttons(4) = 32 bytes
      expect(bytes.length, 32);

      final buffer = ByteData.sublistView(bytes);

      expect(buffer.getUint8(0), 2); // Type
      expect(buffer.getUint8(1), TouchControlMessage.actionDown); // Action
      expect(buffer.getInt64(2, Endian.big), 0); // PointerId
      expect(buffer.getInt32(10, Endian.big), 100); // X
      expect(buffer.getInt32(14, Endian.big), 200); // Y
      expect(buffer.getUint16(18, Endian.big), 1080); // Width
      expect(buffer.getUint16(20, Endian.big), 2400); // Height
      expect(buffer.getUint16(22, Endian.big), 0xFFFF); // Pressure (Down)
      expect(buffer.getInt32(24, Endian.big), 1); // ActionButton
      expect(buffer.getInt32(28, Endian.big), 1); // Buttons (Down)
    });

    test('TouchControlMessage Up action defaults', () {
      final msg = TouchControlMessage(
        action: TouchControlMessage.actionUp,
        x: 100,
        y: 200,
        width: 1080,
        height: 2400,
      );
      final bytes = msg.serialize();
      final buffer = ByteData.sublistView(bytes);

      expect(buffer.getUint8(1), TouchControlMessage.actionUp); // Action
      expect(buffer.getUint16(22, Endian.big), 0); // Pressure (Up = 0)
      expect(buffer.getInt32(28, Endian.big), 0); // Buttons (Up = 0)
    });
  });
}
