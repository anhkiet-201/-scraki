import 'dart:convert';
import 'dart:typed_data';
import 'scrcpy_header.dart';
import '../../../../core/utils/logger.dart';

class ScrcpyProtocolParser {
  static const int headerSize = 76; // 64 (Name) + 12 (Codec Meta)
  static const int _deviceNameLength = 64;

  /// Parses the header from the initial bytes of the stream.
  /// Throws FormatException if data is insufficient or invalid.
  static ScrcpyHeader parseHeader(Uint8List data) {
    if (data.length < headerSize) {
      throw const FormatException('Insufficient data for Scrcpy Header');
    }

    final deviceNameBytes = data.sublist(0, _deviceNameLength);
    // Remove null bytes (padding)
    final deviceName = utf8.decode(
      deviceNameBytes.where((b) => b != 0).toList(),
      allowMalformed: true,
    );

    // Scrcpy v3.3.4 header format with send_codec_meta=true:
    // [64 bytes device name] [4 bytes codec ID] [4 bytes width] [4 bytes height]
    final view = ByteData.sublistView(data, _deviceNameLength, headerSize);
    final codecId = view.getUint32(0); // Offset 0 in view = offset 64 in data
    final width = view.getUint32(4); // Offset 4 in view = offset 68 in data
    final height = view.getUint32(8); // Offset 8 in view = offset 72 in data

    logger.d(
      '[ScrcpyProtocolParser] Codec ID: $codecId, Resolution: ${width}x$height',
    );

    return ScrcpyHeader(deviceName: deviceName, width: width, height: height);
  }
}
