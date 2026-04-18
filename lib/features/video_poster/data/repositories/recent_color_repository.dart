import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class RecentColorRepository {
  static const String _boxName = 'recent_colors';
  static const String _textColorsKey = 'text_colors';
  static const String _bgColorsKey = 'bg_colors';
  static const String _strokeColorsKey = 'stroke_colors';
  static const String _borderColorsKey = 'border_colors';

  Future<Box<dynamic>> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return Hive.openBox(_boxName);
  }

  Future<List<Color>> getRecentTextColors() async {
    final box = await _getBox();
    final raw = box.get(_textColorsKey, defaultValue: <int>[]);
    return _toColors(raw);
  }

  Future<List<Color>> getRecentBgColors() async {
    final box = await _getBox();
    final raw = box.get(_bgColorsKey, defaultValue: <int>[]);
    return _toColors(raw);
  }

  Future<List<Color>> getRecentStrokeColors() async {
    final box = await _getBox();
    final raw = box.get(_strokeColorsKey, defaultValue: <int>[]);
    return _toColors(raw);
  }

  Future<List<Color>> getRecentBorderColors() async {
    final box = await _getBox();
    final raw = box.get(_borderColorsKey, defaultValue: <int>[]);
    return _toColors(raw);
  }

  Future<void> saveRecentTextColors(List<Color> colors) async {
    final box = await _getBox();
    await box.put(_textColorsKey, _toInts(colors));
  }

  Future<void> saveRecentBgColors(List<Color> colors) async {
    final box = await _getBox();
    await box.put(_bgColorsKey, _toInts(colors));
  }

  Future<void> saveRecentStrokeColors(List<Color> colors) async {
    final box = await _getBox();
    await box.put(_strokeColorsKey, _toInts(colors));
  }

  Future<void> saveRecentBorderColors(List<Color> colors) async {
    final box = await _getBox();
    await box.put(_borderColorsKey, _toInts(colors));
  }

  List<Color> _toColors(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) => Color(e as int)).toList();
  }

  List<int> _toInts(List<Color> colors) {
    return colors.map((c) => c.toARGB32()).toList();
  }
}
