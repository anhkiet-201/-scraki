import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/device_entity.dart';
import '../atoms/protocol_icon.dart';
import '../atoms/status_badge.dart';
import '../../stores/device_store.dart';
import '../../widgets/native_video_decoder.dart';

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
  bool _isMirroring = false;
  bool _isLoading = false;
  String? _streamUrl;

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

      setState(() {
        _streamUrl = url;
        _isMirroring = true;
        _isLoading = false;
      });

      print('[DeviceCard] Mirroring state active with native decoder');
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

  void _stopMirroring() {
    if (mounted) {
      setState(() {
        _isMirroring = false;
        _streamUrl = null;
      });
    }
    widget.onDisconnect();
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
                    if (_isMirroring && _streamUrl != null)
                      NativeVideoDecoder(
                        key: Key('decoder_${widget.device.serial}'),
                        streamUrl: _streamUrl!,
                        fit: BoxFit.contain,
                        onError: (error) {
                          print('[DeviceCard] Decoder error: $error');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Decoder error: $error')),
                          );
                          _stopMirroring();
                        },
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
                    onPressed: _stopMirroring,
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
