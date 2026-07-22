import 'dart:convert';

/// P2P Message Types exchanged between Peers (GUI & CLI)
class P2pMessageType {
  static const String queryActiveScripts = 'QUERY_ACTIVE_SCRIPTS';
  static const String activeScriptsStatus = 'ACTIVE_SCRIPTS_STATUS';
  static const String queryGroups = 'QUERY_GROUPS';
  static const String groupsResponse = 'GROUPS_RESPONSE';
  static const String querySelectedDevices = 'QUERY_SELECTED_DEVICES';
  static const String selectedDevicesResponse = 'SELECTED_DEVICES_RESPONSE';
  static const String scriptStarted = 'SCRIPT_STARTED';
  static const String scriptLog = 'SCRIPT_LOG';
  static const String scriptFinished = 'SCRIPT_FINISHED';
  static const String stopScript = 'STOP_SCRIPT';
  static const String runScript = 'RUN_SCRIPT';
  static const String peerAnnounce = 'PEER_ANNOUNCE';
}

/// Standard container for P2P network messages
class P2pMessage {
  final String id;
  final String type;
  final String senderId;
  final Map<String, dynamic> payload;
  final int timestamp;

  P2pMessage({
    required this.id,
    required this.type,
    required this.senderId,
    required this.payload,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'senderId': senderId,
        'payload': payload,
        'timestamp': timestamp,
      };

  factory P2pMessage.fromJson(Map<String, dynamic> json) {
    return P2pMessage(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  String encode() => jsonEncode(toJson());

  static P2pMessage? decode(String rawJson) {
    try {
      final data = jsonDecode(rawJson) as Map<String, dynamic>;
      return P2pMessage.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
