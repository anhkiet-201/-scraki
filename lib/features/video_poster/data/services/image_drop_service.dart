import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

@injectable
class ImageDropService {
  /// Xử lý một DropItem để trích xuất link ảnh hoặc lưu dữ liệu binary.
  /// Trả về một chuỗi là URL hoặc đường dẫn file cục bộ nếu thành công, null nếu thất bại.
  Future<String?> handleDropItem(DropItem item) async {
    final reader = item.dataReader;
    if (reader == null) return null;

    final fileUri = await _tryHandleFileUri(item);
    if (fileUri != null) return fileUri;

    final urlResult = await _tryHandleUrlFormats(item);
    if (urlResult != null && _isDirectImageLink(urlResult)) return urlResult;

    final binaryResult = await _tryHandleBinaryFormats(item);
    if (binaryResult != null) return binaryResult;

    // Last Resort: Nếu chỉ tìm thấy URL không chắc chắn là ảnh thì vẫn thử nạp nốt
    return urlResult;
  }

  /// GIAI ĐOẠN 0: Xử lý File cục bộ
  Future<String?> _tryHandleFileUri(DropItem item) async {
    final reader = item.dataReader;
    if (reader == null || !reader.canProvide(Formats.fileUri)) return null;

    final uri = await _getValueAsync<Uri>(item, Formats.fileUri);
    if (uri != null && uri.isScheme('file')) {
      final path = Uri.decodeComponent(uri.toFilePath());
      if (_isDirectImageLink(path)) return path;
    }
    return null;
  }

  /// GIAI ĐOẠN 1: Xử lý các định dạng URL (HTML, URI, PlainText)
  Future<String?> _tryHandleUrlFormats(DropItem item) async {
    final reader = item.dataReader;
    if (reader == null) return null;
    
    String? rawUrl;

    // 1. Thử lấy từ HTML (Ưu tiên cao nhất)
    if (reader.canProvide(Formats.htmlText)) {
      final html = await _getValueAsync<String>(item, Formats.htmlText);
      if (html != null) rawUrl = _extractUrlFromHtml(html);
    }

    // 2. Thử lấy từ URI
    if (rawUrl == null && reader.canProvide(Formats.uri)) {
      final namedUri = await _getValueAsync<NamedUri>(item, Formats.uri);
      if (namedUri != null) rawUrl = namedUri.uri.toString();
    }

    // 3. Thử lấy từ PlainText
    if (rawUrl == null && reader.canProvide(Formats.plainText)) {
      rawUrl = await _getValueAsync<String>(item, Formats.plainText);
    }

    return rawUrl != null ? _processImageUrl(rawUrl.trim()) : null;
  }

  /// GIAI ĐOẠN 2: Tối ưu hoá Fallback về Binary Data
  /// Chỉ tải và lưu định dạng tốt nhất được tìm thấy.
  Future<String?> _tryHandleBinaryFormats(DropItem item) async {
    final reader = item.dataReader;
    if (reader == null) return null;

    final binaryFormats = {
      Formats.webp: '.webp',
      Formats.png: '.png',
      Formats.jpeg: '.jpg',
      Formats.gif: '.gif',
    };

    var bestFormatEntry = binaryFormats.entries.where((e) => reader.canProvide(e.key)).firstOrNull;

    if (bestFormatEntry == null) return null;

    // 2. Chỉ thực hiện IO cho định dạng tốt nhất
    final data = await _getFileDataAsync(item, bestFormatEntry.key);
    if (data != null && data.isNotEmpty) {
      try {
        final tempDir = await getTemporaryDirectory();
        final fileName = 'drop_${DateTime.now().millisecondsSinceEpoch}${bestFormatEntry.value}';
        final file = File(p.join(tempDir.path, fileName));
        await file.writeAsBytes(data);
        return file.path;
      } catch (e) {
        debugPrint('[ImageDropService] IO Error saving binary data: $e');
      }
    }

    return null;
  }

  String? _extractUrlFromHtml(String html) {
    debugPrint('[ImageDropService] Analyzing Raw HTML...');
    final matchDouble = RegExp(r'src="([^"]+)"', caseSensitive: false).firstMatch(html);
    if (matchDouble != null) return matchDouble.group(1);

    final matchSingle = RegExp(r"src='([^']+)'", caseSensitive: false).firstMatch(html);
    if (matchSingle != null) return matchSingle.group(1);

    return null;
  }

  String _processImageUrl(String url) {
    if (url.contains('google.com/imgres')) {
      try {
        final uri = Uri.tryParse(url);
        final imgUrl = uri?.queryParameters['imgurl'];
        if (imgUrl != null && imgUrl.isNotEmpty) {
          debugPrint('[ImageDropService] Corrected Google Referral URL: $imgUrl');
          return imgUrl;
        }
      } catch (_) {}
    }
    return url;
  }

  bool _isDirectImageLink(String url) {
    final lower = url.toLowerCase();
    if (lower.startsWith('data:image/')) return true;

    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.contains('.png?') ||
        lower.contains('.jpg?') ||
        lower.contains('.jpeg?') ||
        lower.contains('.webp?');
  }

  Future<T?> _getValueAsync<T extends Object>(DropItem item, dynamic format) {
    final reader = item.dataReader;
    if (reader == null) return Future.value(null);
    
    final completer = Completer<T?>();
    // Use dynamic reader to bypass strict type checking for library-internal format types
    final dynamic dReader = reader;
    dReader.getValue(format, (Object? value) {
      if (!completer.isCompleted) {
        completer.complete(value as T?);
      }
    });

    // Add 5 second timeout to prevent hanging UI if library callback is never called
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('[ImageDropService] getValue timed out after 5s for format $format');
        if (!completer.isCompleted) completer.complete(null);
        return null;
      },
    ).catchError((Object e) {
      debugPrint('[ImageDropService] getValue error: $e');
      return null;
    });
  }

  Future<Uint8List?> _getFileDataAsync(DropItem item, dynamic format) {
    final reader = item.dataReader;
    if (reader == null) return Future.value(null);

    final completer = Completer<Uint8List?>();
    // Use dynamic reader to bypass strict type checking for library-internal format types
    final dynamic dReader = reader;
    dReader.getFile(format, (Object? virtualFile) async {
      try {
        final dynamic file = virtualFile;
        if (file == null) {
          if (!completer.isCompleted) completer.complete(null);
          return;
        }
        final data = await file.readAll();
        if (!completer.isCompleted) completer.complete(data as Uint8List?);
      } catch (e) {
        debugPrint('[ImageDropService] Error reading virtual file: $e');
        if (!completer.isCompleted) completer.complete(null);
      }
    });

    // Add 5 second timeout to prevent hanging UI if library callback is never called
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('[ImageDropService] getFile timed out after 5s for format $format');
        if (!completer.isCompleted) completer.complete(null);
        return null;
      },
    ).catchError((Object e) {
      debugPrint('[ImageDropService] getFile error: $e');
      return null;
    });
  }
}
