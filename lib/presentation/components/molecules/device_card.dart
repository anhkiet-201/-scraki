import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/device_entity.dart';
import '../atoms/protocol_icon.dart';
import '../atoms/status_badge.dart';
import '../../stores/device_store.dart';

class DeviceCard extends StatefulWidget {
  final DeviceEntity device;
  final VoidCallback onDisconnect;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onDisconnect,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  Player? _player;
  VideoController? _videoController;
  bool _isMirroring = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _startMirroring() async {
    if (_isMirroring) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('[DeviceCard] Starting mirroring via store...');
      final store = getIt<DeviceStore>();
      final url = await store.startMirroring(widget.device.serial);
      print('[DeviceCard] Received stream URL: $url');

      if (!mounted) return;

      print('[DeviceCard] Initializing media_kit player for H.265 mirror...');
      _player = Player();

      _player!.stream.log.listen((event) {
        print('[MPV] ${event.prefix}: ${event.text}');
      });

      _videoController = VideoController(_player!);

      // Low latency settings for mpv
      if (_player!.platform is NativePlayer) {
        final native = _player!.platform as NativePlayer;
        await native.setProperty('cache', 'no');
        await native.setProperty('demuxer-max-bytes', '128000');
        await native.setProperty('demuxer-max-back-bytes', '0');
        await native.setProperty('profile', 'low-latency');
        await native.setProperty('hwdec', 'auto');
        await native.setProperty('load-unsafe-playlists', 'yes');
        // Hint for HEVC format
        await native.setProperty('demuxer-lavf-format', 'hevc');
        await native.setProperty('demuxer-lavf-probesize', '4096');

        // Ultra-low latency tuning
        await native.setProperty('vd-lavc-threads', '1');
        await native.setProperty('videotoolbox-max-out-frames', '1');
        await native.setProperty('video-sync', 'audio');
        await native.setProperty('framedrop', 'vo');
      }

      // Reduced delay for faster start
      await Future.delayed(const Duration(milliseconds: 200));

      final ffmpegUrl = 'ffmpeg://$url';
      print('[DeviceCard] Opening media: $ffmpegUrl');
      await _player!.open(Media(ffmpegUrl));
      print('[DeviceCard] Media opened successfully');

      print('[DeviceCard] Mirroring state active');

      setState(() {
        _isMirroring = true;
        _isLoading = false;
      });
    } catch (e) {
      print('[DeviceCard] ERROR starting mirroring: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mirror failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ProtocolIcon(
                  isTcp: widget.device.connectionType == ConnectionType.tcp,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.device.modelName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(status: widget.device.status),
              ],
            ),
          ),

          // Video Area
          Expanded(
            child: Container(
              color: Colors.black,
              child: ClipRect(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isMirroring && _videoController != null)
                      Video(
                        key: Key('video_${widget.device.serial}'),
                        controller: _videoController!,
                        fit: BoxFit.contain,
                        controls: (state) =>
                            const SizedBox.shrink(), // Remove controls to fix overflow and because it's a mirror
                      )
                    else if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      const Icon(
                        Icons.phonelink_setup,
                        size: 64,
                        color: Colors.white24,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Footer Actions
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isMirroring)
                  IconButton(
                    icon: const Icon(Icons.link_off),
                    onPressed: () async {
                      await _player?.dispose();
                      _player = null;
                      _videoController = null;
                      if (mounted) {
                        setState(() => _isMirroring = false);
                      }
                      widget.onDisconnect();
                    },
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startMirroring,
                  icon: Icon(_isMirroring ? Icons.refresh : Icons.screen_share),
                  label: Text(_isMirroring ? 'Restart' : 'Mirror'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
