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

    // ─── GIAI ĐOẠN 0: File cục bộ ───
    if (reader.canProvide(Formats.fileUri)) {
      final uri = await _getValueAsync<Uri>(reader, Formats.fileUri);
      if (uri != null && uri.isScheme('file')) {
        final path = Uri.decodeComponent(uri.toFilePath());
        if (_isDirectImageLink(path)) {
          return path;
        }
      }
    }

    // ─── GIAI ĐOẠN 1: URL First ───
    String? foundUrl;
    
    // Thử lấy từ HTML
    if (reader.canProvide(Formats.htmlText)) {
      final html = await _getValueAsync<String>(reader, Formats.htmlText);
      if (html != null) {
        foundUrl = _extractUrlFromHtml(html);
      }
    }
    
    // Thử lấy từ URI
    if (foundUrl == null && reader.canProvide(Formats.uri)) {
      final namedUri = await _getValueAsync<NamedUri>(reader, Formats.uri);
      if (namedUri != null) {
        foundUrl = namedUri.uri.toString();
      }
    }
    
    // Thử lấy từ PlainText
    if (foundUrl == null && reader.canProvide(Formats.plainText)) {
      foundUrl = await _getValueAsync<String>(reader, Formats.plainText);
    }

    if (foundUrl != null) {
      final processedUrl = _processImageUrl(foundUrl.trim());
      if (_isDirectImageLink(processedUrl)) {
        return processedUrl;
      }
      debugPrint('[ImageDropService] Found URL but not direct image: $processedUrl');
    }

    // ─── GIAI ĐOẠN 2: Binary Fallback ───
    final binaryFormats = {
      Formats.png: '.png',
      Formats.jpeg: '.jpg',
      Formats.webp: '.webp',
      Formats.gif: '.gif',
    };

    for (final entry in binaryFormats.entries) {
      final format = entry.key;
      final ext = entry.value;

      if (reader.canProvide(format)) {
        final data = await _getFileDataAsync(reader, format);
        if (data != null && data.isNotEmpty) {
          final tempDir = await getTemporaryDirectory();
          final fileName = 'drop_${DateTime.now().millisecondsSinceEpoch}$ext';
          final file = File(p.join(tempDir.path, fileName));
          await file.writeAsBytes(data);
          return file.path;
        }
      }
    }

    // ─── GIAI ĐOẠN 3: Last Resort ───
    if (foundUrl != null) {
      return _processImageUrl(foundUrl.trim());
    }

    return null;
  }

  String? _extractUrlFromHtml(String html) {
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

  Future<T?> _getValueAsync<T extends Object>(dynamic reader, dynamic format) {
    final completer = Completer<T?>();
    reader.getValue(format, (Object? value) {
      if (!completer.isCompleted) {
        completer.complete(value as T?);
      }
    });
    return completer.future;
  }

  Future<Uint8List?> _getFileDataAsync(dynamic reader, dynamic format) {
    final completer = Completer<Uint8List?>();
    reader.getFile(format, (Object? virtualFile) async {
      if (virtualFile == null) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      try {
        final data = await (virtualFile as dynamic).readAll();
        if (!completer.isCompleted) completer.complete(data as Uint8List?);
      } catch (e) {
        debugPrint('[ImageDropService] Error reading virtual file: $e');
        if (!completer.isCompleted) completer.complete(null);
      }
    });
    return completer.future;
  }
}
