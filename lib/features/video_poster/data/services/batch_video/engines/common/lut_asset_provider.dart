import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Provides utility methods for managing and extracting Look-Up Table (LUT) assets.
class LutAssetProvider {
  static List<String>? _cachedLuts;

  /// Dynamically scans the asset manifest for available LUT files in 'assets/luts/'.
  static Future<List<String>> _loadLutAssets() async {
    if (_cachedLuts != null) return _cachedLuts!;

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    _cachedLuts = manifest
        .listAssets()
        .where((path) =>
            path.startsWith('assets/luts/') &&
            path.toLowerCase().endsWith('.cube'))
        .toList();

    return _cachedLuts!;
  }

  /// Selects a random LUT file from assets, extracts it to the [tempDir],
  /// and returns its absolute path on the physical disk.
  ///
  /// This is necessary because FFmpeg requires a physical file path
  /// and cannot read directly from the Flutter rootBundle.
  static Future<String> extractRandom(Random random, String tempDir) async {
    final luts = await _loadLutAssets();
    if (luts.isEmpty) {
      throw Exception('No LUT assets found in assets/luts/');
    }

    final assetPath = luts[random.nextInt(luts.length)];
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
