import 'dart:async';
import 'package:flutter/services.dart';
import '../../../../core/utils/logger.dart';

class _DecoderSession {
  final int textureId;
  int refCount;
  Timer? stopTimer;
  _DecoderSession(this.textureId, {required this.refCount});
}

class NativeVideoDecoderService {
  static const _channel = MethodChannel('scraki/video_decoder');

  // Map of URL -> Session info
  final Map<String, _DecoderSession> _sessions = {};

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

    session.refCount--;
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
}
