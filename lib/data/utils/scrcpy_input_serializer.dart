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
  final int pointerId;
  final int buttons; // Add buttons support

  TouchControlMessage({
    required this.action,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.pointerId = 0,
    this.buttons = 0, // 0 for touch, or encoded mouse buttons
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
    // For Mouse: which button triggered the event (Primary=1, Secondary=2, Middle=4, etc.)
    // For Touch: 0 or 1?
    // Let's use buttons value for simplicity or pass separately if needed.
    // Scrcpy logic: action_button is the button that CHANGED state.
    // buttons is the state of ALL buttons.
    // For simplicity, we assume single button press logic for now.
    final actionButtonData = ByteData(4);
    // If it's a move event, actionButton is usually 0 unless dragging?
    // Let's use 'buttons' as the action button for Down/Up events.
    actionButtonData.setInt32(0, buttons, Endian.big);
    buffer.add(actionButtonData.buffer.asUint8List());

    // 7. Buttons (4 bytes) - State of all buttons
    final buttonsData = ByteData(4);
    // If Up, button is released so state might be 0? 
    // Or Scrcpy expects the state BEFORE release? 
    // Usually Up event means button is no longer pressed.
    // But protocol field is 'buttons state'.
    // Let's keep it simple: Pass what we get.
    buttonsData.setInt32(0, buttons, Endian.big);
    buffer.add(buttonsData.buffer.asUint8List());

    return buffer.toBytes();
  }
}

class ScrollControlMessage extends ControlMessage {
  static const int typeInjectScrollEvent = 3; // 0x03

  final int x;
  final int y;
  final int width;
  final int height;
  final int hScroll; // horizontal
  final int vScroll; // vertical
  final int buttons;

  ScrollControlMessage({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.hScroll,
    required this.vScroll,
    this.buttons = 0,
  });

  @override
  Uint8List serialize() {
    final buffer = BytesBuilder();
    buffer.addByte(typeInjectScrollEvent);

    // Position (12 bytes: X, Y, W, H)
    final posData = ByteData(12);
    posData.setInt32(0, x, Endian.big);
    posData.setInt32(4, y, Endian.big);
    posData.setUint16(8, width, Endian.big);
    posData.setUint16(10, height, Endian.big);
    buffer.add(posData.buffer.asUint8List());

    // Scroll (4 bytes: H, V - signed 16)
    final scrollData = ByteData(4);
    scrollData.setInt16(0, hScroll, Endian.big);
    scrollData.setInt16(2, vScroll, Endian.big);
    buffer.add(scrollData.buffer.asUint8List());
    
    // Buttons (4 bytes)
    final buttonsData = ByteData(4);
    buttonsData.setInt32(0, buttons, Endian.big);
    buffer.add(buttonsData.buffer.asUint8List());

    return buffer.toBytes();
  }
}

class KeyControlMessage extends ControlMessage {
  static const int typeInjectKeyEvent = 0; // 0x00

  final int action; // 0=Down, 1=Up
  final int keyCode;
  final int repeat;
  final int metaState;

  KeyControlMessage({
    required this.action,
    required this.keyCode,
    this.repeat = 0,
    this.metaState = 0,
  });

  @override
  Uint8List serialize() {
    final buffer = BytesBuilder();
    
    // 1. Type (1 byte)
    buffer.addByte(typeInjectKeyEvent);
    
    // 2. Action (1 byte)
    buffer.addByte(action);
    
    // 3. KeyCode (4 bytes)
    final keyData = ByteData(4);
    keyData.setInt32(0, keyCode, Endian.big);
    buffer.add(keyData.buffer.asUint8List());
    
    // 4. Repeat (4 bytes)
    final repeatData = ByteData(4);
    repeatData.setInt32(0, repeat, Endian.big);
    buffer.add(repeatData.buffer.asUint8List());
    
    // 5. MetaState (4 bytes)
    final metaData = ByteData(4);
    metaData.setInt32(0, metaState, Endian.big);
    buffer.add(metaData.buffer.asUint8List());
    
    return buffer.toBytes();
  }
}