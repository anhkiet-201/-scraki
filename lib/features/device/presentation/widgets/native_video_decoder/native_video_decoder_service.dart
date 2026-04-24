import 'dart:async';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/widgets.dart';
import 'package:scraki/core/utils/logger.dart';

class _DecoderSession {
  final int textureId;
  int refCount;
  int visibleRefCount = 0;
  Timer? stopTimer;
  _DecoderSession(this.textureId, {required this.refCount});
}

@lazySingleton
class NativeVideoDecoderService with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.scraki.video_decoder');

  // Map of URL -> Session info
  final Map<String, _DecoderSession> _sessions = {};
  bool _isAppVisible = true;

  NativeVideoDecoderService() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bool wasVisible = _isAppVisible;
    _isAppVisible = state == AppLifecycleState.resumed;

    if (wasVisible != _isAppVisible) {
      logger.i('[NativeVideoDecoderService] App Visibility changed to $_isAppVisible. Syncing all sessions.');
      _syncAllSessionsVisibility();
    }
  }

  Future<void> _syncAllSessionsVisibility() async {
    for (final session in _sessions.values) {
      final bool shouldBeVisible = _isAppVisible && session.visibleRefCount > 0;
      try {
        await _channel.invokeMethod('setVisibility', {
          'textureId': session.textureId,
          'visible': shouldBeVisible,
        });
        if (shouldBeVisible) {
          // Khi hiện lại, ép Flush và Request I-Frame để có hình ngay
          await _channel.invokeMethod('flush', {'textureId': session.textureId});
        }
      } catch (e) {
        logger.e('[NativeVideoDecoderService] Error syncing global visibility', error: e);
      }
    }
  }

  Future<int?> start(String url) async {
    try {
      // 1. If session exists for this URL, just increment refCount and return textureId
      if (_sessions.containsKey(url)) {
        final session = _sessions[url]!;
        session.stopTimer?.cancel();
        session.stopTimer = null;
        session.refCount++;
        logger.i(
          '[NativeVideoDecoderService] Reusing texture ${session.textureId} for $url (RefCount: ${session.refCount})',
        );
        return session.textureId;
      }

      // 2. Otherwise, start new native decoding session
      logger.i('[NativeVideoDecoderService] Requesting startDecoding for $url');
      final result = await _channel.invokeMethod('startDecoding', {'url': url});
      if (result is int) {
        _sessions[url] = _DecoderSession(result, refCount: 1);
        return result;
      }
      return null;
    } catch (e) {
      logger.e('[NativeVideoDecoderService] Error starting decoder', error: e);
      return null;
    }
  }

  Future<void> stop(String url) async {
    final session = _sessions[url];
    if (session == null) return;

    session.visibleRefCount = 0; // Reset để tránh phantom reference khi khởi động lại cùng URL
    session.refCount--;
    if (session.refCount < 0) session.refCount = 0;
    
    logger.i(
      '[NativeVideoDecoderService] Decremented RefCount for $url (Remaining: ${session.refCount})',
    );

    if (session.refCount <= 0) {
      // Graceful Release: Delay stopping the native decoder by 500ms
      // This allows switches between Grid and Floating view to happen without restart.
      session.stopTimer?.cancel();
      session.stopTimer = Timer(const Duration(milliseconds: 500), () async {
        try {
          logger.i(
            '[NativeVideoDecoderService] Delayed release: stopping native decoder for texture ${session.textureId}',
          );
          await _channel.invokeMethod('stopDecoding', {
            'textureId': session.textureId,
          });
          _sessions.remove(url);
        } catch (e) {
          logger.e(
            '[NativeVideoDecoderService] Error stopping decoder',
            error: e,
          );
        }
      });
      logger.i(
        '[NativeVideoDecoderService] Scheduled release for $url in 500ms',
      );
    }
  }

  Future<void> flush(String url) async {
    final session = _sessions[url];
    if (session == null) return;
    try {
      logger.i('[NativeVideoDecoderService] Flushing decoder for texture ${session.textureId}');
      await _channel.invokeMethod('flushDecoding', {'textureId': session.textureId});
    } catch (e) {
      logger.e('[NativeVideoDecoderService] Error flushing decoder', error: e);
    }
  }

  Future<void> setVisibility(String url, bool visible) async {
    final session = _sessions[url];
    if (session == null) return;

    final int oldVisibleCount = session.visibleRefCount;
    if (visible) {
      session.visibleRefCount++;
    } else {
      session.visibleRefCount--;
    }

    if (session.visibleRefCount < 0) session.visibleRefCount = 0;

    // Chỉ gọi Native khi trạng thái thực tế thay đổi
    // Lưu ý: Phải tính đến cả trạng thái hiển thị của App
    final bool shouldCallNative = _isAppVisible && (
      (visible && oldVisibleCount == 0) || 
      (!visible && oldVisibleCount > 0 && session.visibleRefCount == 0)
    );

    if (shouldCallNative) {
      try {
        final bool finalVisible = visible && _isAppVisible;
        logger.i('[NativeVideoDecoderService] Actual native visibility change to $finalVisible for texture ${session.textureId}');
        await _channel.invokeMethod('setVisibility', {
          'textureId': session.textureId,
          'visible': finalVisible,
        });
      } catch (e) {
        logger.e('[NativeVideoDecoderService] Error setting visibility', error: e);
      }
    } else {
      logger.d('[NativeVideoDecoderService] Visibility refCount updated to ${session.visibleRefCount} for $url (No native call needed)');
    }
  }
}
