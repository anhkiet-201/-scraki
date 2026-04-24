import 'dart:async';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/widgets.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/device/data/datasources/video_worker_manager.dart';
import 'package:scraki/features/device/domain/services/i_video_decoder_service.dart';

class _DecoderSession {
  final int textureId;
  final String sessionId;
  int refCount;
  int visibleRefCount = 0;
  Timer? stopTimer;
  _DecoderSession(this.textureId, this.sessionId, {required this.refCount});
}

@LazySingleton(as: IVideoDecoderService)
class NativeVideoDecoderServiceImpl with WidgetsBindingObserver implements IVideoDecoderService {
  static const _channel = MethodChannel('com.scraki.video_decoder');

  // Map of URL -> Session info
  final Map<String, _DecoderSession> _sessions = {};
  bool _isAppVisible = true;

  NativeVideoDecoderServiceImpl() {
    initialize();
  }

  @override
  void initialize() {
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
    final workerManager = getIt<VideoWorkerManager>();
    final sessions = List<_DecoderSession>.from(_sessions.values);
    for (final session in sessions) {
      final bool shouldBeVisible = _isAppVisible && session.visibleRefCount > 0;
      try {
        await _channel.invokeMethod('setVisibility', {
          'textureId': session.textureId,
          'visible': shouldBeVisible,
        });
        if (shouldBeVisible) {
          // Khi hiện lại, ép Flush và Request I-Frame để có hình ngay mà không bị chớp đen
          await _channel.invokeMethod('flush', {'textureId': session.textureId});
          workerManager.requestKeyFrame(session.sessionId);
        }
      } catch (e) {
        logger.e('[NativeVideoDecoderService] Error syncing global visibility', error: e);
      }
    }
  }

  @override
  Future<int?> start(String url, String sessionId) async {
    try {
      // 1. If session exists for this URL, just increment refCount and return textureId
      if (_sessions.containsKey(url)) {
        final session = _sessions[url]!;
        session.stopTimer?.cancel();
        session.stopTimer = null;
        session.refCount++;
        logger.d(
          '[NativeVideoDecoderService] Reusing texture ${session.textureId} for $url (RefCount: ${session.refCount})',
        );
        return session.textureId;
      }

      // 2. Otherwise, start new native decoding session
      logger.d('[NativeVideoDecoderService] Requesting startDecoding for $url');
      final result = await _channel.invokeMethod('startDecoding', {'url': url});
      if (result is int) {
        _sessions[url] = _DecoderSession(result, sessionId, refCount: 1);
        return result;
      }
      return null;
    } catch (e) {
      logger.e('[NativeVideoDecoderService] Error starting decoder', error: e);
      return null;
    }
  }

  @override
  Future<void> stop(String url) async {
    final session = _sessions[url];
    if (session == null) return;

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

  @override
  Future<void> flush(String url) async {
    final session = _sessions[url];
    if (session == null) return;
    try {
      logger.i('[NativeVideoDecoderService] Flushing decoder for texture ${session.textureId}');
      await _channel.invokeMethod('flush', {'textureId': session.textureId});
    } catch (e) {
      logger.e('[NativeVideoDecoderService] Error flushing decoder', error: e);
    }
  }

  @override
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

    // Luôn tính toán trạng thái hiển thị thực tế (Kết hợp cả Widget Visibility và App Visibility)
    final bool oldActualVisible = _isAppVisible && oldVisibleCount > 0;
    final bool newActualVisible = _isAppVisible && session.visibleRefCount > 0;

    // Chỉ gọi Native nếu trạng thái thực tế CÓ SỰ THAY ĐỔI
    if (oldActualVisible != newActualVisible) {
      try {
        logger.i('[NativeVideoDecoderService] Actual native visibility change to $newActualVisible for texture ${session.textureId}');
        await _channel.invokeMethod('setVisibility', {
          'textureId': session.textureId,
          'visible': newActualVisible,
        });
        
        // Nếu vừa mới hiển thị trở lại, yêu cầu I-Frame ngay để có hình mượt
        if (newActualVisible) {
           await _channel.invokeMethod('flush', {'textureId': session.textureId});
           getIt<VideoWorkerManager>().requestKeyFrame(session.sessionId);
        }
      } catch (e) {
        logger.e('[NativeVideoDecoderService] Error setting visibility', error: e);
      }
    } else {
      logger.d('[NativeVideoDecoderService] Visibility refCount updated to ${session.visibleRefCount} (Actual visibility remains $newActualVisible)');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final session in _sessions.values) {
      session.stopTimer?.cancel();
    }
    _sessions.clear();
  }
}
