import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import '../../core/protocol/scrcpy_protocol_parser.dart';

@lazySingleton
class VideoProxyService {
  ServerSocket? _serverSocket;
  final Map<int, Socket> _activeProxies =
      {}; // Map local proxy port to device socket
  StreamSubscription<List<int>>? _scrcpySubscription;

  /// Starts a proxy server that accepts a Scrcpy video stream,
  /// strips packet headers, and serves raw H.264 to a local player.
  /// Returns the port of the local proxy server.
  Future<int> startProxyFromStream(Stream<List<int>> scrcpyStream) async {
    // Cleanup any previous proxy session
    await _scrcpySubscription?.cancel();
    _scrcpySubscription = null;
    _serverSocket?.close();
    _serverSocket = null;
    print('VideoProxy: Cleaned up previous session');

    final server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    final proxyPort = server.port;

    print(
      'VideoProxy: Listening on 127.0.0.1:$proxyPort (anyIPv4), serving from Scrcpy stream',
    );

    _serverSocket = server;

    // CRITICAL: Start buffering data IMMEDIATELY before player connects
    // This prevents losing SPS/PPS config packets
    final preconnectBuffer = <List<int>>[];

    // Handler function that will be switched when player connects
    void Function(List<int>)? liveHandler;

    _scrcpySubscription = scrcpyStream.listen(
      (data) {
        if (liveHandler != null) {
          // Player connected - forward to live handler
          liveHandler!(data);
        } else {
          // Buffer data until player connects
          preconnectBuffer.add(data);
          print(
            'VideoProxy: Buffering ${data.length} bytes (total chunks: ${preconnectBuffer.length})',
          );
        }
      },
      onDone: () {
        print('VideoProxy: Scrcpy source stream closed');
      },
      onError: (Object e) {
        print('VideoProxy: Scrcpy source stream error: $e');
      },
    );
    print('VideoProxy: Subscribed to scrcpy stream successfully');

    server
        .listen((playerSocket) {
          print(
            'VideoProxy: Player connected to proxy from ${playerSocket.remoteAddress.address}:${playerSocket.remotePort}.',
          );

          // Setup live handler and process buffered data
          _setupLiveHandler(
            playerSocket,
            preconnectBuffer,
            (handler) => liveHandler = handler,
          );
        })
        .onError((Object e) {
          print('VideoProxy: Error: $e');
        });

    _serverSocket = server;
    return proxyPort;
  }

  /// Original method - connects to device port directly
  /// Starts a proxy server that connects to [devicePort] (ADB forwarded port),
  /// strips Scrcpy headers/metadata, and serves raw H.264 to a local player.
  /// Returns the port of the local proxy server.
  Future<int> startProxy(int devicePort) async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    final proxyPort = server.port;

    print(
      'VideoProxy: Listening on 127.0.0.1:$proxyPort (bound to 0.0.0.0), forwarding to device port $devicePort',
    );

    server
        .listen((playerSocket) {
          print('VideoProxy: Player connected to proxy.');
          _handlePlayerConnection(playerSocket, devicePort);
        })
        .onError((Object e) {
          print('VideoProxy: Error: $e');
        });

    _serverSocket = server;
    return proxyPort;
  }

  /// Sets up the live handler for incoming video data.
  /// First processes all buffered data, then registers handler for live data.
  void _setupLiveHandler(
    Socket playerSocket,
    List<List<int>> preconnectBuffer,
    void Function(void Function(List<int>) handler) registerHandler,
  ) {
    print(
      'VideoProxy: Setting up live handler. Processing ${preconnectBuffer.length} buffered chunks...',
    );

    int totalBytesReceived = 0;
    int packetsProcessed = 0;

    // Processing buffer - contains raw bytes waiting to be parsed
    final buffer = <int>[];

    // Merge State - hold SPS/PPS config to merge with next keyframe
    Uint8List? pendingConfig;

    bool isProxying = true;

    // Parsing State Machine
    bool readingPacketHeader = true; // True = reading 12 bytes metadata
    int neededBytes = 12;
    int currentPayloadSize = 0;
    bool isConfigPacket = false;

    // Process incoming data (both buffered and live)
    void processData(List<int> data) {
      if (!isProxying) return;
      try {
        totalBytesReceived += data.length;
        buffer.addAll(data);

        // Parse multiple packets from buffer
        while (buffer.length >= neededBytes) {
          if (readingPacketHeader) {
            // Parse 12-byte packet header (8 bytes PTS + 4 bytes size)
            final packetHeader = Uint8List.fromList(buffer.sublist(0, 12));
            final ptsData = ByteData.sublistView(packetHeader);
            final pts = ptsData.getInt64(0);

            // Config flag is bit 63 (MSB) - negative value in signed int64
            isConfigPacket = pts < 0;
            final payloadSize = ptsData.getUint32(8);

            packetsProcessed++;
            if (packetsProcessed <= 5 || isConfigPacket) {
              print(
                'VideoProxy: Packet #$packetsProcessed - Size: $payloadSize - Config: $isConfigPacket',
              );
            }

            // Remove header from buffer
            buffer.removeRange(0, 12);
            currentPayloadSize = payloadSize;
            neededBytes = currentPayloadSize;
            readingPacketHeader = false;
          } else {
            // Extract payload
            final payload = Uint8List.fromList(
              buffer.sublist(0, currentPayloadSize),
            );

            if (isConfigPacket) {
              // Buffer config (SPS/PPS) to merge with next frame
              pendingConfig = payload;
              print(
                'VideoProxy: Config packet buffered (SPS/PPS). Length: ${payload.length}',
              );
            } else {
              // Normal frame - send to player
              if (pendingConfig != null) {
                final merged = BytesBuilder();
                merged.add(pendingConfig!);
                merged.add(payload);
                final mergedData = merged.toBytes();

                try {
                  playerSocket.add(mergedData);
                } catch (e) {
                  print(
                    'VideoProxy: Error writing merged data to player socket: $e',
                  );
                  isProxying = false;
                  playerSocket.close();
                  _scrcpySubscription?.cancel();
                  return; // Stop further processing for this connection
                }
                pendingConfig = null;
              } else {
                try {
                  playerSocket.add(payload);
                } catch (e) {
                  print(
                    'VideoProxy: Error writing payload to player socket: $e',
                  );
                  isProxying = false;
                  playerSocket.close();
                  _scrcpySubscription?.cancel();
                  return; // Stop further processing for this connection
                }
              }
            }

            // Remove payload from buffer
            buffer.removeRange(0, currentPayloadSize);
            neededBytes = 12;
            readingPacketHeader = true;
            isConfigPacket = false;
          }
        }
      } catch (e) {
        print('VideoProxy: Error processing data: $e');
        isProxying = false;
        playerSocket.close();
        _scrcpySubscription?.cancel();
      }
    }

    // Process all buffered data first (contains SPS/PPS)
    for (final chunk in preconnectBuffer) {
      if (!isProxying) break;
      processData(chunk);
    }
    print(
      'VideoProxy: Processed $totalBytesReceived bytes from buffer, $packetsProcessed packets',
    );

    // Register handler for live data
    if (isProxying) {
      registerHandler(processData);
    }

    // Cleanup when player disconnects
    playerSocket.done
        .then((_) {
          print(
            'VideoProxy: Player disconnected from ${playerSocket.remoteAddress.address}:${playerSocket.remotePort}',
          );
          isProxying = false;
          _scrcpySubscription?.cancel();
        })
        .catchError((e) {
          print('VideoProxy: Socket error on done: $e');
          isProxying = false;
          _scrcpySubscription?.cancel();
        });
  }

  Future<void> _handlePlayerConnection(
    Socket playerSocket,
    int devicePort,
  ) async {
    Socket? deviceSocket;
    try {
      deviceSocket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        devicePort,
      );
      deviceSocket.setOption(SocketOption.tcpNoDelay, true);
      print('VideoProxy: Connected to device Scrcpy server.');

      // We keep track to close cleanup
      _activeProxies[playerSocket.remotePort] = deviceSocket;

      // Parsing State Machine
      bool headerParsed = false;
      final buffer = <int>[];

      // Scrcpy 2.0 Header: 64 (name) + 2 (w) + 2 (h) = 68 bytes?
      // Actually v2.0 might be 69 bytes if it includes a dummy byte or different alignment.
      // Let's assume standard 64+4 = 68 or 69.
      // We'll read until we have enough.

      // PACKET FORMAT (after header):
      // [8 bytes PTS] [4 bytes SIZE] [PAYLOAD]

      int neededBytes =
          ScrcpyProtocolParser.headerSize; // Initial header size attempt
      bool readingPacketHeader =
          true; // True = reading 12 bytes metadata. False = reading payload.
      int currentPayloadSize = 0;

      deviceSocket.listen(
        (data) {
          try {
            buffer.addAll(data);

            if (!headerParsed) {
              // Scrcpy header is variable (device name usually 64 bytes fixed).
              // v1.22+: Device Name (64) + Width (2) + Height (2) = 68 bytes.
              if (buffer.length >= ScrcpyProtocolParser.headerSize) {
                print('VideoProxy: Scrcpy Header stripped.');
                // Remove header
                buffer.removeRange(0, ScrcpyProtocolParser.headerSize);
                headerParsed = true;

                // Now we expect Packet Headers (12 bytes)
                neededBytes = 12;
                readingPacketHeader = true;
              }
            }

            // Allow loop to process multiple packets in one chunk
            while (headerParsed && buffer.length >= neededBytes) {
              if (readingPacketHeader) {
                // We have at least 12 bytes of Packet Header (PTS + Size)
                // 0-7: PTS (skip)
                // 8-11: Size (read)
                final packetHeader = Uint8List.fromList(buffer.sublist(0, 12));
                final payloadSize = ByteData.sublistView(
                  packetHeader,
                ).getUint32(8); // 4 bytes size at offset 8

                print('VideoProxy: Parsed Packet Size: $payloadSize');

                // Remove the 12 packet header bytes
                buffer.removeRange(0, 12);

                currentPayloadSize = payloadSize;
                neededBytes = currentPayloadSize;
                readingPacketHeader = false;
              } else {
                // Reading Payload
                // We have at least 'currentPayloadSize' bytes
                final payload = buffer.sublist(0, currentPayloadSize);

                // Debug first few bytes of payload to check for H.264 start code (00 00 00 01)
                if (payload.length >= 4) {
                  final hex = payload
                      .sublist(0, 4)
                      .map((b) => b.toRadixString(16).padLeft(2, '0'))
                      .join(' ');
                  print('VideoProxy: Payload Start: $hex');
                }

                // WRITE TO PLAYER
                playerSocket.add(payload);

                // Remove used payload
                buffer.removeRange(0, currentPayloadSize);

                // Reset to read next packet header
                neededBytes = 12;
                readingPacketHeader = true;
              }
            }
          } catch (e) {
            print('VideoProxy: Error parsing stream: $e');
            playerSocket.close();
            deviceSocket?.destroy();
          }
        },
        onDone: () {
          print('VideoProxy: Device socket closed.');
          playerSocket.close();
        },
        onError: (Object e) {
          print('VideoProxy: Device socket error: $e');
          playerSocket.close();
        },
      );

      // Close device connection when player disconnects
      playerSocket.done.then((_) {
        print('VideoProxy: Player disconnected.');
        deviceSocket?.destroy();
      });
    } catch (e) {
      print('VideoProxy: Failed to connect to device: $e');
      playerSocket.close();
    }
  }

  void stopAll() {
    _serverSocket?.close();
    _activeProxies.values.forEach((s) => s.destroy());
    _activeProxies.clear();
  }
}
