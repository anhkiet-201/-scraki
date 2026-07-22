import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'p2p_messages.dart';

/// P2P Peer Node capable of UDP Auto-Discovery and WebSocket Bi-Directional Messaging
class P2pPeerNode {
  static const int _udpPort = 9988;

  final String peerId;
  final String peerType; // 'GUI' or 'CLI'
  
  RawDatagramSocket? _udpSocket;
  HttpServer? _httpServer;
  int? wsPort;

  final Map<String, WebSocket> _connectedPeers = {};
  final StreamController<P2pMessage> _messageStreamController = StreamController<P2pMessage>.broadcast();
  Timer? _announcementTimer;
  Timer? _reconnectTimer;

  Stream<P2pMessage> get onMessage => _messageStreamController.stream;

  P2pPeerNode({
    String? peerId,
    required this.peerType,
  }) : peerId = peerId ?? '${peerType}_${const Uuid().v4().substring(0, 8)}';

  /// Starts the P2P Node (WebSocket server + UDP Auto Discovery)
  Future<void> start({int preferredWsPort = 0}) async {
    // 1. Start WebSocket Server
    try {
      _httpServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        preferredWsPort,
        shared: true,
      );
      wsPort = _httpServer!.port;
      _httpServer!.transform(WebSocketTransformer()).listen(_handleIncomingWebSocket);
    } catch (e) {
      _httpServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
        shared: true,
      );
      wsPort = _httpServer!.port;
      _httpServer!.transform(WebSocketTransformer()).listen(_handleIncomingWebSocket);
    }

    // 2. Start UDP Auto Discovery
    try {
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _udpPort,
        reuseAddress: true,
        reusePort: true,
      );
      _udpSocket!.broadcastEnabled = true;
      _udpSocket!.listen(_handleUdpPacket);
    } catch (_) {}

    // 3. Periodic UDP Announcement & Reconnect Probe Timer
    _announcementTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _announceSelf();
    });
    _reconnectTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _probeStandardPorts();
    });
    
    _announceSelf();
    _probeStandardPorts();
  }

  void _handleIncomingWebSocket(WebSocket ws) {
    String? remotePeerId;

    ws.listen(
      (data) {
        if (data is String) {
          final msg = P2pMessage.decode(data);
          if (msg != null) {
            if (msg.type == P2pMessageType.peerAnnounce) {
              remotePeerId = msg.senderId;
              _connectedPeers[remotePeerId!] = ws;
            }
            _messageStreamController.add(msg);
          }
        }
      },
      onDone: () {
        if (remotePeerId != null) {
          _connectedPeers.remove(remotePeerId);
          _notifyPeerDisconnected(remotePeerId!);
        }
      },
      onError: (_) {
        if (remotePeerId != null) {
          _connectedPeers.remove(remotePeerId);
          _notifyPeerDisconnected(remotePeerId!);
        }
      },
    );

    // Send self announcement over WebSocket immediately
    final announceMsg = P2pMessage(
      id: const Uuid().v4(),
      type: P2pMessageType.peerAnnounce,
      senderId: peerId,
      payload: {'peerType': peerType, 'wsPort': wsPort},
    );
    ws.add(announceMsg.encode());
  }

  void _notifyPeerDisconnected(String id) {
    _messageStreamController.add(P2pMessage(
      id: const Uuid().v4(),
      type: 'PEER_DISCONNECTED',
      senderId: id,
      payload: {},
    ));
  }

  void _handleUdpPacket(RawSocketEvent event) {
    if (event == RawSocketEvent.read && _udpSocket != null) {
      final datagram = _udpSocket!.receive();
      if (datagram == null) return;

      final rawData = utf8.decode(datagram.data);
      try {
        final data = jsonDecode(rawData) as Map<String, dynamic>;
        final sender = data['peerId'] as String?;
        final senderWsPort = data['wsPort'] as int?;

        if (sender != null && sender != peerId && senderWsPort != null) {
          _connectToPeer(datagram.address.address, senderWsPort);
        }
      } catch (_) {}
    }
  }

  void _announceSelf() {
    if (_udpSocket == null || wsPort == null) return;
    try {
      final announcePayload = jsonEncode({
        'peerId': peerId,
        'peerType': peerType,
        'wsPort': wsPort,
      });
      final bytes = utf8.encode(announcePayload);
      _udpSocket!.send(bytes, InternetAddress('255.255.255.255'), _udpPort);
    } catch (_) {}
  }

  Future<void> _probeStandardPorts() async {
    final portsToProbe = [9090, 9091, 9092];
    for (final port in portsToProbe) {
      if (port != wsPort) {
        await _connectToPeer('127.0.0.1', port);
      }
    }
  }

  Future<void> _connectToPeer(String host, int port) async {
    final key = '$host:$port';
    if (_connectedPeers.containsKey(key)) return;

    try {
      final ws = await WebSocket.connect('ws://$host:$port').timeout(const Duration(milliseconds: 800));
      _connectedPeers[key] = ws;

      String? remoteId;
      ws.listen(
        (data) {
          if (data is String) {
            final msg = P2pMessage.decode(data);
            if (msg != null) {
              if (msg.type == P2pMessageType.peerAnnounce) {
                remoteId = msg.senderId;
                _connectedPeers[remoteId!] = ws;
              }
              _messageStreamController.add(msg);
            }
          }
        },
        onDone: () {
          _connectedPeers.remove(key);
          if (remoteId != null) {
            _connectedPeers.remove(remoteId);
            _notifyPeerDisconnected(remoteId!);
          }
        },
        onError: (_) {
          _connectedPeers.remove(key);
          if (remoteId != null) {
            _connectedPeers.remove(remoteId);
            _notifyPeerDisconnected(remoteId!);
          }
        },
      );

      // Send self announce
      final announceMsg = P2pMessage(
        id: const Uuid().v4(),
        type: P2pMessageType.peerAnnounce,
        senderId: peerId,
        payload: {'peerType': peerType, 'wsPort': wsPort},
      );
      ws.add(announceMsg.encode());
    } catch (_) {}
  }

  /// Sends a P2P message to all currently connected Peers
  void broadcastMessage(P2pMessage message) {
    final encoded = message.encode();
    final deadPeers = <String>[];

    for (final entry in _connectedPeers.entries) {
      try {
        entry.value.add(encoded);
      } catch (_) {
        deadPeers.add(entry.key);
      }
    }

    for (final key in deadPeers) {
      _connectedPeers.remove(key);
    }
  }

  /// Sends a P2P query message and waits for response matching [expectedResponseType]
  Future<P2pMessage?> request(
    P2pMessage message, {
    required String expectedResponseType,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final completer = Completer<P2pMessage?>();

    StreamSubscription? sub;
    sub = onMessage.listen((incoming) {
      if (incoming.type == expectedResponseType || incoming.payload['replyTo'] == message.id) {
        if (!completer.isCompleted) {
          completer.complete(incoming);
          sub?.cancel();
        }
      }
    });

    broadcastMessage(message);

    try {
      return await completer.future.timeout(timeout);
    } catch (_) {
      sub?.cancel();
      return null;
    }
  }

  bool get hasPeers => _connectedPeers.isNotEmpty;

  /// Closes all sockets and timers
  Future<void> stop() async {
    _announcementTimer?.cancel();
    _reconnectTimer?.cancel();
    _udpSocket?.close();
    for (final ws in _connectedPeers.values) {
      try {
        await ws.close();
      } catch (_) {}
    }
    _connectedPeers.clear();
    await _httpServer?.close(force: true);
    await _messageStreamController.close();
  }
}
