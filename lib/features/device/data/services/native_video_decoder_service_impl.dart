import 'dart:async';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/device/data/datasources/video_worker_manager.dart';
import 'package:scraki/features/device/domain/services/i_video_decoder_service.dart';

/// Represents an active video decoding session on the Native side.
///
/// Stores necessary information to manage the lifecycle of a [Texture]
/// and coordinates visibility across different Widgets.
class _DecoderSession {
  /// The ID of the texture created by the Native side (Android/iOS).
  final int textureId;

  /// Unique identifier for the current video session.
  final String sessionId;

  /// Current reference count for this URL.
  /// Used to decide when to release Native resources.
  int refCount;

  /// Number of Widgets currently displaying this URL on screen.
  /// Used to toggle the Native decoding stream to save resources.
  int visibleRefCount = 0;

  /// Timer used for the "Graceful Release" mechanism.
  /// Prevents immediate destruction of the decoder when switching between Views (Grid/Floating).
  Timer? stopTimer;

  _DecoderSession(this.textureId, this.sessionId, {required this.refCount});
}

/// Implementation of [IVideoDecoderService] using Native Platform Channels.
///
/// This service manages video decoding at the Native level and maps the results
/// onto a Flutter [Texture] for high performance.
///
/// Core Mechanisms:
/// 1. **Texture Reuse**: If multiple Widgets view the same URL, they share the same textureId.
/// 2. **Reference Counting**: Tracks how many Widgets are using the texture to release it at the right time.
/// 3. **Graceful Release**: Delays decoder release to optimize UX during UI transitions.
@LazySingleton(as: IVideoDecoderService)
class NativeVideoDecoderServiceImpl implements IVideoDecoderService {
  /// Channel for communicating with Native code (Java/Kotlin/Swift/ObjC).
  static const _channel = MethodChannel('com.scraki.video_decoder');

  /// Active decoding sessions, mapping from URL to [_DecoderSession].
  final Map<String, _DecoderSession> _sessions = {};

  /// Starts a decoding session for a [url].
  ///
  /// If [url] is already being decoded by another session, it increments the `refCount`
  /// and returns the existing `textureId` instead of creating a new one.
  ///
  /// Returns the `textureId` if successful, or `null` if an error occurs.
  @override
  Future<int?> start(String url, String sessionId) async {
    try {
      // 1. If session exists for this URL, reuse texture and increment refCount
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

      // 2. Otherwise, request Native to start a new decoding session
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

  /// Stops the session for a [url].
  ///
  /// Instead of closing the decoder immediately, this method uses a "Graceful Release" mechanism:
  /// - Decrements `refCount`.
  /// - If `refCount` reaches 0, starts a 500ms [Timer].
  /// - If no new `start` request for this URL arrives within 500ms, the Native decoder is finally closed.
  /// This ensures smooth transitions between UI modes without restart overhead.
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

  /// Flushes pending frames in the decoder buffer.
  /// Useful when seeking or needing an immediate visual refresh.
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

  /// Updates the visibility state for a [url].
  ///
  /// Uses `visibleRefCount` to track how many Widgets are actually displaying this video.
  /// Only when the "Actual Visibility" state changes (from 0 to >0 or vice versa)
  /// is the Native side called to toggle decoding, optimizing CPU/GPU usage.
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

    final bool oldActualVisible = oldVisibleCount > 0;
    final bool newActualVisible = session.visibleRefCount > 0;

    if (oldActualVisible != newActualVisible) {
      try {
        logger.i('[NativeVideoDecoderService] Actual native visibility change to $newActualVisible for texture ${session.textureId}');
        await _channel.invokeMethod('setVisibility', {
          'textureId': session.textureId,
          'visible': newActualVisible,
        });
        
        // If just became visible, request an I-Frame immediately for smooth visuals
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

  /// Disposes all sessions and releases resources.
  @override
  void dispose() {
    for (final session in _sessions.values) {
      session.stopTimer?.cancel();
    }
    _sessions.clear();
  }
  
  @override
  void initialize() {}
}
