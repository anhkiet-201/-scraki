import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'p2p_messages.dart';

/// Lớp xử lý hạ tầng mạng P2P cấp thấp (Low-Level Transport Layer) dành cho GUI App.
///
/// Chịu trách nhiệm khởi tạo WebSocket Server nội bộ, phát quảng bá UDP Auto Discovery,
/// quét kết nối tới nút kề (Peer Probing với cơ chế fallback cổng) và duy trì các socket kết nối duy nhất theo Peer ID.
class P2pPeerNode {
  /// Cổng UDP mặc định dùng cho cơ chế Auto Discovery giữa các Peer
  static const int _udpPort = 9988;

  /// Mã định danh duy nhất của nút P2P hiện tại
  final String peerId;

  /// Phân loại nút P2P (mặc định là `'GUI'`)
  final String peerType;

  RawDatagramSocket? _udpSocket;
  HttpServer? _httpServer;

  /// Cổng WebSocket Server đang mở và nhận kết nối
  int? wsPort;

  /// Bản đồ lưu trữ các kết nối duy nhất theo `remotePeerId`
  final Map<String, WebSocket> _connectedPeers = {};

  /// Bản đồ tạm lưu trữ socket chờ bắt tay (handshake) theo `host:port`
  final Map<String, WebSocket> _pendingSockets = {};

  final StreamController<P2pMessage> _messageStreamController =
      StreamController<P2pMessage>.broadcast();

  /// Bản đồ quản lý các Completer lắng nghe phản hồi của yêu cầu theo `replyId`
  final Map<String, Completer<P2pMessage>> _pendingRequests = {};

  Timer? _announcementTimer;
  Timer? _reconnectTimer;
  bool _isProbing = false;

  /// Luồng phát tất cả các sự kiện tin nhắn [P2pMessage] nhận được từ mạng (không bao gồm tin nhắn phản hồi của `request`)
  Stream<P2pMessage> get onMessage => _messageStreamController.stream;

  /// Kiểm tra xem hiện tại nút có kết nối với ít nhất một nút P2P khác hay không
  bool get hasConnectedPeers => _connectedPeers.isNotEmpty;
  bool get hasPeers => _connectedPeers.isNotEmpty;

  /// Khởi tạo một đối tượng [P2pPeerNode].
  P2pPeerNode({
    String? peerId,
    this.peerType = 'GUI',
  }) : peerId = peerId ?? '${peerType}_${const Uuid().v4().substring(0, 8)}';

  /// Khởi chạy hạ tầng nút P2P.
  Future<void> start({int preferredWsPort = 0}) async {
    try {
      _httpServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        preferredWsPort,
        shared: true,
      );
      wsPort = _httpServer!.port;
      _httpServer!
          .transform(WebSocketTransformer())
          .listen(_handleIncomingWebSocket);
    } catch (_) {
      _httpServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
        shared: true,
      );
      wsPort = _httpServer!.port;
      _httpServer!
          .transform(WebSocketTransformer())
          .listen(_handleIncomingWebSocket);
    }

    try {
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _udpPort,
        reuseAddress: true,
        reusePort: !Platform.isWindows,
      );
      _udpSocket!.broadcastEnabled = true;
      _udpSocket!.listen(_handleUdpPacket);
    } catch (_) {}

    _announcementTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _announceSelf();
    });
    _reconnectTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _probeStandardPorts();
    });

    _announceSelf();
    await _probeStandardPorts();
  }

  /// Đăng ký và đảm bảo chỉ duy trì duy nhất 1 kết nối WebSocket cho mỗi `remotePeerId`
  void _registerPeerConnection(
    String remoteId,
    WebSocket ws,
    String socketKey,
  ) {
    _pendingSockets.remove(socketKey);

    if (_connectedPeers.containsKey(remoteId)) {
      if (_connectedPeers[remoteId] != ws) {
        try {
          ws.close();
        } catch (_) {}
      }
      return;
    }

    _connectedPeers[remoteId] = ws;
  }

  /// Gỡ bỏ kết nối khi socket bị đóng
  void _removePeerConnection(String? remoteId, String socketKey, [WebSocket? ws]) {
    _pendingSockets.remove(socketKey);
    if (remoteId != null && _connectedPeers[remoteId] != null) {
      if (ws == null || _connectedPeers[remoteId] == ws) {
        _connectedPeers.remove(remoteId);
        _notifyPeerDisconnected(remoteId);
      }
    }
  }

  /// Xử lý tin nhắn nhận được: kiểm tra xem có phải phản hồi của `request` hay không.
  void _routeIncomingMessage(P2pMessage msg) {
    final replyId = msg.replyId ?? msg.payload['replyTo'] as String?;

    if (replyId != null && _pendingRequests.containsKey(replyId)) {
      final completer = _pendingRequests.remove(replyId);
      if (completer != null && !completer.isCompleted) {
        completer.complete(msg);
      }
      return;
    }

    if (!_messageStreamController.isClosed) {
      _messageStreamController.add(msg);
    }
  }

  /// Xử lý khi có một kết nối WebSocket mới từ một Peer khác truy cập tới HttpServer nội bộ
  void _handleIncomingWebSocket(WebSocket ws) {
    String? remotePeerId;
    final socketKey = 'incoming_${ws.hashCode}';
    _pendingSockets[socketKey] = ws;

    ws.listen(
      (data) {
        if (data is String) {
          final msg = P2pMessage.decode(data);
          if (msg != null) {
            if (msg.type == P2pMessageType.peerAnnounce) {
              remotePeerId = msg.senderId;
              _registerPeerConnection(remotePeerId!, ws, socketKey);
            }
            _routeIncomingMessage(msg);
          }
        }
      },
      onDone: () => _removePeerConnection(remotePeerId, socketKey, ws),
      onError: (_) => _removePeerConnection(remotePeerId, socketKey, ws),
    );

    final announceMsg = P2pMessage(
      id: const Uuid().v4(),
      type: P2pMessageType.peerAnnounce,
      senderId: peerId,
      payload: {'peerType': peerType, 'wsPort': wsPort},
    );
    ws.add(announceMsg.encode());
  }

  /// Đẩy sự kiện ngắt kết nối của một Peer tới Stream listener
  void _notifyPeerDisconnected(String id) {
    if (_messageStreamController.isClosed) return;
    _messageStreamController.add(
      PeerDisconnectedMessage(disconnectedPeerId: id),
    );
  }

  /// Xử lý đọc dữ liệu gói tin UDP Broadcast
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
          if (_connectedPeers.containsKey(sender)) return;
          _connectToPeer(datagram.address.address, senderWsPort);
        }
      } catch (_) {}
    }
  }

  /// Gửi gói tin quảng bá UDP
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

  /// Thử kết nối tuần tự tới các cổng kề
  Future<void> _probeStandardPorts() async {
    if (_isProbing || hasConnectedPeers) return;
    _isProbing = true;

    try {
      final portsToProbe = [9090, 9091, 9092];
      for (final port in portsToProbe) {
        if (hasConnectedPeers) break;
        if (port != wsPort) {
          final success = await _connectToPeer('127.0.0.1', port);
          if (success) break;
        }
      }
    } finally {
      _isProbing = false;
    }
  }

  /// Chủ động tạo kết nối WebSocket Client tới một Peer tại địa chỉ [host]:[port].
  Future<bool> _connectToPeer(String host, int port) async {
    final key = '$host:$port';
    if (_pendingSockets.containsKey(key)) return false;

    try {
      final ws = await WebSocket.connect(
        'ws://$host:$port',
      ).timeout(const Duration(milliseconds: 800));
      _pendingSockets[key] = ws;

      String? remoteId;
      ws.listen(
        (data) {
          if (data is String) {
            final msg = P2pMessage.decode(data);
            if (msg != null) {
              if (msg.type == P2pMessageType.peerAnnounce) {
                remoteId = msg.senderId;
                _registerPeerConnection(remoteId!, ws, key);
              }
              _routeIncomingMessage(msg);
            }
          }
        },
        onDone: () => _removePeerConnection(remoteId, key, ws),
        onError: (_) => _removePeerConnection(remoteId, key, ws),
      );

      final announceMsg = P2pMessage(
        id: const Uuid().v4(),
        type: P2pMessageType.peerAnnounce,
        senderId: peerId,
        payload: {'peerType': peerType, 'wsPort': wsPort},
      );
      ws.add(announceMsg.encode());
      return true;
    } catch (_) {
      _pendingSockets.remove(key);
      return false;
    }
  }

  /// Gửi gói tin [message] đến toàn bộ các Peer đang có kết nối WebSocket mở
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
      _notifyPeerDisconnected(key);
    }
  }

  /// Gửi một tin nhắn truy vấn [message] và lắng nghe tin nhắn phản hồi.
  Future<P2pMessage?> request(
    P2pMessage message, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final completer = Completer<P2pMessage>();
    _pendingRequests[message.id] = completer;

    broadcastMessage(message);

    try {
      return await completer.future.timeout(timeout);
    } catch (_) {
      _pendingRequests.remove(message.id);
      return null;
    }
  }

  /// Ngắt toàn bộ kết nối, đóng socket UDP/WebSocket server và giải phóng các Timer
  Future<void> stop() async {
    _announcementTimer?.cancel();
    _reconnectTimer?.cancel();
    _udpSocket?.close();
    _pendingRequests.clear();
    final sockets = List<WebSocket>.from(_connectedPeers.values);
    _pendingSockets.clear();
    _connectedPeers.clear();
    for (final ws in sockets) {
      try {
        await ws.close();
      } catch (_) {}
    }
    await _httpServer?.close(force: true);
    if (!_messageStreamController.isClosed) {
      await _messageStreamController.close();
    }
  }
}
