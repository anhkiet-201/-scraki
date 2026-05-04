import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class LutAssetProvider {
  static const List<String> _lutAssets = [
    'assets/luts/Aqua and Orange Dark.cube',
    'assets/luts/Aqua.cube',
    'assets/luts/Arabica 12.CUBE',
    'assets/luts/Ava 614.CUBE',
    'assets/luts/Azrael 93.CUBE',
    'assets/luts/BlueArchitecture.cube',
    'assets/luts/BlueHour.cube',
    'assets/luts/Blues.cube',
    'assets/luts/Bourbon 64.CUBE',
    'assets/luts/Byers 11.CUBE',
    'assets/luts/Chemical 168.CUBE',
    'assets/luts/Clayton 33.CUBE',
    'assets/luts/Clouseau 54.CUBE',
    'assets/luts/Cobi 3.CUBE',
    'assets/luts/ColdChrome.cube',
    'assets/luts/Contrail 35.CUBE',
    'assets/luts/CrispAutumn.cube',
    'assets/luts/Cubicle 99.CUBE',
    'assets/luts/DarkAndSomber.cube',
    'assets/luts/Django 25.CUBE',
    'assets/luts/Domingo 145.CUBE',
    'assets/luts/Earth Tone Boost.cube',
    'assets/luts/Faded 47.CUBE',
    'assets/luts/Folger 50.CUBE',
    'assets/luts/Fusion 88.CUBE',
    'assets/luts/Green_Blues.cube',
    'assets/luts/Green_Yellow.cube',
    'assets/luts/HardBoost.cube',
    'assets/luts/Hyla 68.CUBE',
    'assets/luts/Korben 214.CUBE',
    'assets/luts/Lenox 340.CUBE',
    'assets/luts/LongBeachMorning.cube',
    'assets/luts/Lucky 64.CUBE',
    'assets/luts/LushGreen.cube',
    'assets/luts/MagicHour.cube',
    'assets/luts/McKinnon 75.CUBE',
    'assets/luts/Milo 5.CUBE',
    'assets/luts/NaturalBoost.cube',
    'assets/luts/Neon 770.CUBE',
    'assets/luts/OrangeAndBlue.cube',
    'assets/luts/Oranges.cube',
    'assets/luts/Paladin 1875.CUBE',
    'assets/luts/Pasadena 21.CUBE',
    'assets/luts/Pitaya 15.CUBE',
    'assets/luts/Purple.cube',
    'assets/luts/Reds.cube',
    'assets/luts/Reds_Oranges_Yellows.cube',
    'assets/luts/Reeve 38.CUBE',
    'assets/luts/Remy 24.CUBE',
    'assets/luts/Sprocket 231.CUBE',
    'assets/luts/Teigen 28.CUBE',
    'assets/luts/Trent 18.CUBE',
    'assets/luts/Tweed 71.CUBE',
    'assets/luts/Vireo 37.CUBE',
    'assets/luts/Waves.cube',
    'assets/luts/Zed 32.CUBE',
    'assets/luts/Zeke 39.CUBE',
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
