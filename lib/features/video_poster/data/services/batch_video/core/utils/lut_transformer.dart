import 'dart:io';

/// Helper class để biến đổi file LUT 3D (.cube).
class LutTransformer {
  /// Biến đổi file LUT .cube để giảm độ đậm nhạt (intensity).
  ///
  /// [intensity] nhận giá trị từ 0.0 (giữ nguyên màu gốc) đến 1.0 (áp dụng hoàn toàn LUT).
  static Future<void> transform(File inputFile, File outputFile, double intensity) async {
    final lines = await inputFile.readAsLines();
    final ios = outputFile.openWrite();

    int lutSize = 33; // Kích thước mặc định
    int dataLineIndex = 0;

    for (var line in lines) {
      final trimmed = line.trim();
      
      // Giữ nguyên dòng trống
      if (trimmed.isEmpty) {
        ios.writeln();
        continue;
      }

      // Giữ nguyên comment
      if (trimmed.startsWith('#')) {
        ios.writeln(line);
        continue;
      }

      // Đọc kích thước LUT
      if (trimmed.startsWith('LUT_3D_SIZE')) {
        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          lutSize = int.tryParse(parts[1]) ?? 33;
        }
        ios.writeln(line);
        continue;
      }

      // Giữ nguyên các metadata khác
      if (trimmed.startsWith('TITLE') ||
          trimmed.startsWith('DOMAIN_MIN') ||
          trimmed.startsWith('DOMAIN_MAX')) {
        ios.writeln(line);
        continue;
      }

      // Xử lý dòng dữ liệu màu (3 giá trị số cách nhau bởi khoảng trắng)
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        final rLut = double.tryParse(parts[0]);
        final gLut = double.tryParse(parts[1]);
        final bLut = double.tryParse(parts[2]);

        if (rLut != null && gLut != null && bLut != null) {
          final double rIn = (dataLineIndex % lutSize) / (lutSize - 1);
          final double gIn = ((dataLineIndex ~/ lutSize) % lutSize) / (lutSize - 1);
          final double bIn = (dataLineIndex ~/ (lutSize * lutSize)) / (lutSize - 1);

          final double rNew = rIn + (rLut - rIn) * intensity;
          final double gNew = gIn + (gLut - gIn) * intensity;
          final double bNew = bIn + (bLut - bIn) * intensity;

          ios.writeln('${rNew.toStringAsFixed(6)} ${gNew.toStringAsFixed(6)} ${bNew.toStringAsFixed(6)}');
          dataLineIndex++;
          continue;
        }
      }

      // Nếu không phải dòng dữ liệu hoặc không phân tích được, giữ nguyên
      ios.writeln(line);
    }

    await ios.close();
  }
}
