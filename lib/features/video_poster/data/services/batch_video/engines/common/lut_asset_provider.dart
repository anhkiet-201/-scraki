import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class LutAssetProvider {
  static const List<String> _lutAssets = [
    'assets/luts/Aqua and Orange Dark.cube',
    'assets/luts/Aqua.cube',
    'assets/luts/BlueArchitecture.cube',
    'assets/luts/BlueHour.cube',
    'assets/luts/Blues.cube',
    'assets/luts/ColdChrome.cube',
    'assets/luts/CrispAutumn.cube',
    'assets/luts/DarkAndSomber.cube',
    'assets/luts/Earth Tone Boost.cube',
    'assets/luts/Green_Blues.cube',
    'assets/luts/Green_Yellow.cube',
    'assets/luts/HardBoost.cube',
    'assets/luts/LongBeachMorning.cube',
    'assets/luts/LushGreen.cube',
    'assets/luts/MagicHour.cube',
    'assets/luts/NaturalBoost.cube',
    'assets/luts/OrangeAndBlue.cube',
    'assets/luts/Oranges.cube',
    'assets/luts/Purple.cube',
    'assets/luts/Reds.cube',
    'assets/luts/Reds_Oranges_Yellows.cube',
    'assets/luts/SoftBlackAndWhite.cube',
    'assets/luts/Waves.cube',
  ];

  /// Chọn ngẫu nhiên một file LUT từ assets, copy ra thư mục tạm (tempDir),
  /// và trả về đường dẫn tuyệt đối của file tạm đó.
  /// Lý do: FFmpeg cần đường dẫn file thực tế trên disk, không thể đọc trực tiếp từ rootBundle.
  static Future<String> extractRandom(Random random, String tempDir) async {
    final assetPath = _lutAssets[random.nextInt(_lutAssets.length)];
    final filename = p.basename(assetPath);
    final outFile = File(p.join(tempDir, filename));

    if (!await outFile.exists()) {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await outFile.writeAsBytes(bytes);
    }

    return outFile.absolute.path;
  }
}
