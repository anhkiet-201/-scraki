import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/di/injection.dart';
import '../../core/utils/android_key_codes.dart';
import '../stores/device_store.dart';
import 'native_video_decoder.dart';

class PhoneView extends StatefulWidget {
  final String serial;
  final BoxFit fit;

  const PhoneView({
    super.key,
    required this.serial,
    this.fit = BoxFit.contain,
  });

  @override
  State<PhoneView> createState() => _PhoneViewState();
}

class _PhoneViewState extends State<PhoneView> {
  String? _streamUrl;
  int _nativeWidth = 1080;
  int _nativeHeight = 2336;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startMirroring();
  }

  @override
  void dispose() {
    // Stop mirroring session (close sockets, cleanup proxy)
    getIt<DeviceStore>().stopMirroring(widget.serial);
    super.dispose();
  }

  Future<void> _startMirroring() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('[PhoneView] Starting mirroring for ${widget.serial}...');
      final store = getIt<DeviceStore>();
      final session = await store.startMirroring(widget.serial);
      print('[PhoneView] Received session URL: ${session.videoUrl} (${session.width}x${session.height})');

      if (!mounted) return;

      setState(() {
        _streamUrl = session.videoUrl;
        _nativeWidth = session.width;
        _nativeHeight = session.height;
        _isLoading = false;
      });
    } catch (e) {
      print('[PhoneView] ERROR starting mirroring: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _onDecoderError(String error) {
    print('[PhoneView] Decoder error: $error');
    if (!mounted) return;
    setState(() {
      _errorMessage = 'Decoder error: $error';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 32, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              'Mirroring Failed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startMirroring,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to device...'),
          ],
        ),
      );
    }

    if (_streamUrl == null) {
      return const Center(child: Text('No stream URL'));
    }

    return NativeVideoDecoder(
      key: Key('decoder_${widget.serial}'),
      streamUrl: _streamUrl!,
      nativeWidth: _nativeWidth,
      nativeHeight: _nativeHeight,
      fit: widget.fit,
      onError: _onDecoderError,
      onInput: (action, x, y, width, height) {
        getIt<DeviceStore>().sendTouch(
          widget.serial,
          x,
          y,
          action,
          width,
          height,
        );
      },
      onKey: (keyId, action) {
        final key = LogicalKeyboardKey.findKeyByKeyId(keyId);
        if (key != null) {
          final androidCode = AndroidKeyCodes.getKeyCode(key);
          if (androidCode != AndroidKeyCodes.kUnknown) {
            getIt<DeviceStore>().sendKey(widget.serial, androidCode, action);
          }
        }
      },
    );
  }
}