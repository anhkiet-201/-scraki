import 'dart:convert';
import 'dart:math';

/// Tập hợp loại tin nhắn (Message Type) trong mạng P2P.
enum P2pMessageType {
  /// Yêu cầu truy vấn danh sách các script đang thực thi
  queryActiveScripts('QUERY_ACTIVE_SCRIPTS'),

  /// Phản hồi trạng thái các script đang thực thi
  activeScriptsStatus('ACTIVE_SCRIPTS_STATUS'),

  /// Yêu cầu lấy danh sách nhóm thiết bị
  queryGroups('QUERY_GROUPS'),

  /// Phản hồi danh sách nhóm thiết bị
  groupsResponse('GROUPS_RESPONSE'),

  /// Yêu cầu lấy danh sách thiết bị đang được chọn
  querySelectedDevices('QUERY_SELECTED_DEVICES'),

  /// Phản hồi danh sách thiết bị đang được chọn
  selectedDevicesResponse('SELECTED_DEVICES_RESPONSE'),

  /// Thông báo một script đã bắt đầu thực thi
  scriptStarted('SCRIPT_STARTED'),

  /// Gửi nhật ký (log) trong quá trình script vận hành
  scriptLog('SCRIPT_LOG'),

  /// Thông báo một script đã hoàn tất thực thi
  scriptFinished('SCRIPT_FINISHED'),

  /// Yêu cầu dừng thực thi script
  stopScript('STOP_SCRIPT'),

  /// Yêu cầu khởi chạy script
  runScript('RUN_SCRIPT'),

  /// Tin nhắn quảng bá/khai báo sự tồn tại của nút P2P (Peer Announcement)
  peerAnnounce('PEER_ANNOUNCE'),

  /// Cập nhật trạng thái của thiết bị
  deviceStatusUpdate('DEVICE_STATUS_UPDATE'),

  /// Thông báo ngắt kết nối nút P2P
  peerDisconnected('PEER_DISCONNECTED'),

  /// Loại tin nhắn không xác định (dành cho fallback)
  unknown('UNKNOWN');

  /// Giá trị chuỗi (String value) dùng để mã hóa JSON truyền qua mạng
  final String value;

  const P2pMessageType(this.value);

  /// Chuyển đổi từ chuỗi JSON [val] sang enum [P2pMessageType]
  static P2pMessageType fromValue(String val) {
    return P2pMessageType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => P2pMessageType.unknown,
    );
  }
}

/// Helper tạo ID duy nhất cho tin nhắn
String _generateId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';

/// Helper tự sinh Sender ID duy nhất cho thiết bị P2P Node
String _generatePeerId() => _generateId('CLI');

/// Dữ liệu gói tin chuẩn (Data Packet) truyền tải qua lại giữa các nút trong mạng P2P.
class P2pMessage {
  /// Mã định danh duy nhất của tin nhắn (UUID hoặc Timestamp microsecond)
  final String id;

  /// Loại tin nhắn định danh mục đích gói tin, tham chiếu tại [P2pMessageType]
  final P2pMessageType type;

  /// Mã định danh duy nhất của nút P2P phát tin nhắn (Peer ID/Device ID)
  final String senderId;

  /// Mã định danh của tin nhắn gốc cần phản hồi (nếu gói tin này là câu trả lời)
  final String? replyId;

  /// Dữ liệu chi tiết đính kèm theo dạng chuỗi khóa-giá trị (Key-Value)
  final Map<String, dynamic> payload;

  /// Dấu thời gian Unix Epoch (tính bằng miligiây) tại thời điểm khởi tạo gói tin
  final int timestamp;

  P2pMessage({
    String? id,
    required this.type,
    String? senderId,
    this.replyId,
    required this.payload,
    int? timestamp,
  })  : id = id ?? _generateId('MSG'),
        senderId = senderId ?? _generatePeerId(),
        timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  /// Chuyển đổi đối tượng [P2pMessage] thành cấu trúc [Map<String, dynamic>] để phục vụ mã hóa.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.value,
        'senderId': senderId,
        if (replyId != null) 'replyId': replyId,
        'payload': payload,
        'timestamp': timestamp,
      };

  /// Khởi tạo đối tượng [P2pMessage] từ dữ liệu định dạng Map [json].
  factory P2pMessage.fromJson(Map<String, dynamic> json) {
    final replyIdVal = (json['replyId'] as String?) ??
        (json['payload'] is Map ? json['payload']['replyTo'] as String? : null);

    final baseMsg = P2pMessage(
      id: json['id'] as String? ?? '',
      type: P2pMessageType.fromValue(json['type'] as String? ?? ''),
      senderId: json['senderId'] as String? ?? '',
      replyId: replyIdVal,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );

    return baseMsg.toTypedMessage();
  }

  /// Chuyển đổi đối tượng [P2pMessage] generic sang lớp thông điệp chuyên biệt (Typed Subclass).
  P2pMessage toTypedMessage() {
    switch (type) {
      case P2pMessageType.queryActiveScripts:
        return QueryActiveScriptsMessage(
          id: id,
          senderId: senderId,
          replyId: replyId,
        );
      case P2pMessageType.activeScriptsStatus:
        return ActiveScriptsStatusMessage(
          id: id,
          senderId: senderId,
          replyId: replyId ?? '',
          scriptName: payload['scriptName'] as String?,
          serials: (payload['serials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          executionId: payload['executionId'] as String?,
          isExecuting: payload['isExecuting'] as bool? ?? false,
        );
      case P2pMessageType.queryGroups:
        return QueryGroupsMessage(
          id: id,
          senderId: senderId,
          replyId: replyId,
        );
      case P2pMessageType.groupsResponse:
        final rawGroups = payload['groups'] as List<dynamic>? ?? [];
        return GroupsResponseMessage(
          id: id,
          senderId: senderId,
          replyId: replyId ?? '',
          groups: rawGroups.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
      case P2pMessageType.querySelectedDevices:
        return QuerySelectedDevicesMessage(
          id: id,
          senderId: senderId,
          replyId: replyId,
        );
      case P2pMessageType.selectedDevicesResponse:
        return SelectedDevicesResponseMessage(
          id: id,
          senderId: senderId,
          replyId: replyId ?? '',
          selectedSerials: (payload['selectedSerials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        );
      case P2pMessageType.scriptStarted:
        return ScriptStartedMessage(
          id: id,
          senderId: senderId,
          scriptName: payload['scriptName'] as String? ?? '',
          serials: (payload['serials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          executionId: payload['executionId'] as String? ?? '',
        );
      case P2pMessageType.scriptLog:
        return ScriptLogMessage(
          id: id,
          senderId: senderId,
          executionId: payload['executionId'] as String? ?? '',
          serial: payload['serial'] as String?,
          message: payload['message'] as String? ?? '',
          level: payload['level'] as String? ?? 'info',
        );
      case P2pMessageType.scriptFinished:
        return ScriptFinishedMessage(
          id: id,
          senderId: senderId,
          executionId: payload['executionId'] as String? ?? '',
          serials: (payload['serials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          exitCode: payload['exitCode'] as int? ?? 0,
        );
      case P2pMessageType.stopScript:
        return StopScriptMessage(
          id: id,
          senderId: senderId,
          executionId: payload['executionId'] as String?,
          serials: (payload['serials'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
        );
      case P2pMessageType.runScript:
        return RunScriptMessage(
          id: id,
          senderId: senderId,
          scriptName: payload['scriptName'] as String? ?? '',
          serials: (payload['serials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        );
      case P2pMessageType.peerAnnounce:
        return PeerAnnounceMessage(
          id: id,
          senderId: senderId,
          peerType: payload['peerType'] as String? ?? '',
          wsPort: payload['wsPort'] as int?,
        );
      case P2pMessageType.deviceStatusUpdate:
        return DeviceStatusUpdateMessage(
          id: id,
          senderId: senderId,
          serial: payload['serial'] as String? ?? '',
          status: payload['status'] as String? ?? '',
          reason: payload['reason'] as String?,
          executionId: payload['executionId'] as String?,
        );
      case P2pMessageType.peerDisconnected:
        return PeerDisconnectedMessage(
          id: id,
          disconnectedPeerId: senderId,
        );
      case P2pMessageType.unknown:
        return this;
    }
  }

  /// Mã hóa đối tượng [P2pMessage] thành chuỗi JSON dạng text để truyền qua WebSocket.
  String encode() => jsonEncode(toJson());

  /// Giải mã một chuỗi văn bản JSON [rawJson] thành đối tượng [P2pMessage].
  static P2pMessage? decode(String rawJson) {
    try {
      final data = jsonDecode(rawJson) as Map<String, dynamic>;
      return P2pMessage.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}

// ============================================================================
// CÁC LỚP THÔNG ĐIỆP CHUYÊN BIỆT KẾ THỪA TỪ P2pMessage
// ============================================================================

/// Tin nhắn truy vấn các script đang chạy [P2pMessageType.queryActiveScripts]
class QueryActiveScriptsMessage extends P2pMessage {
  QueryActiveScriptsMessage({
    super.id,
    super.senderId,
    super.replyId,
  }) : super(
          type: P2pMessageType.queryActiveScripts,
          payload: {},
        );
}

/// Tin nhắn phản hồi trạng thái script đang chạy [P2pMessageType.activeScriptsStatus]
class ActiveScriptsStatusMessage extends P2pMessage {
  String? get scriptName => payload['scriptName'] as String?;
  List<String> get serials =>
      (payload['serials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
  String? get executionId => payload['executionId'] as String?;
  bool get isExecuting => payload['isExecuting'] as bool? ?? false;

  ActiveScriptsStatusMessage({
    super.id,
    super.senderId,
    required String replyId,
    String? scriptName,
    List<String> serials = const [],
    String? executionId,
    bool isExecuting = false,
  }) : super(
          type: P2pMessageType.activeScriptsStatus,
          replyId: replyId,
          payload: {
            'scriptName': ?scriptName,
            'serials': serials,
            'executionId': ?executionId,
            'isExecuting': isExecuting,
          },
        );
}

/// Tin nhắn truy vấn danh sách nhóm [P2pMessageType.queryGroups]
class QueryGroupsMessage extends P2pMessage {
  QueryGroupsMessage({
    super.id,
    super.senderId,
    super.replyId,
  }) : super(
          type: P2pMessageType.queryGroups,
          payload: {},
        );
}

/// Tin nhắn phản hồi danh sách nhóm [P2pMessageType.groupsResponse]
class GroupsResponseMessage extends P2pMessage {
  List<Map<String, dynamic>> get groups {
    final raw = payload['groups'] as List<dynamic>? ?? [];
    return raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  GroupsResponseMessage({
    super.id,
    super.senderId,
    required String replyId,
    required List<Map<String, dynamic>> groups,
  }) : super(
          type: P2pMessageType.groupsResponse,
          replyId: replyId,
          payload: {
            'groups': groups,
          },
        );
}

/// Tin nhắn truy vấn thiết bị đang được chọn [P2pMessageType.querySelectedDevices]
class QuerySelectedDevicesMessage extends P2pMessage {
  QuerySelectedDevicesMessage({
    super.id,
    super.senderId,
    super.replyId,
  }) : super(
          type: P2pMessageType.querySelectedDevices,
          payload: {},
        );
}

/// Tin nhắn phản hồi danh sách thiết bị đang chọn [P2pMessageType.selectedDevicesResponse]
class SelectedDevicesResponseMessage extends P2pMessage {
  List<String> get selectedSerials =>
      (payload['selectedSerials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

  SelectedDevicesResponseMessage({
    super.id,
    super.senderId,
    required String replyId,
    required List<String> selectedSerials,
  }) : super(
          type: P2pMessageType.selectedDevicesResponse,
          replyId: replyId,
          payload: {
            'selectedSerials': selectedSerials,
          },
        );
}

/// Tin nhắn thông báo script bắt đầu [P2pMessageType.scriptStarted]
class ScriptStartedMessage extends P2pMessage {
  String get scriptName => payload['scriptName'] as String? ?? '';
  List<String> get serials =>
      (payload['serials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
  String get executionId => payload['executionId'] as String? ?? '';

  ScriptStartedMessage({
    super.id,
    super.senderId,
    required String scriptName,
    required List<String> serials,
    required String executionId,
  }) : super(
          type: P2pMessageType.scriptStarted,
          payload: {
            'scriptName': scriptName,
            'serials': serials,
            'executionId': executionId,
          },
        );
}

/// Tin nhắn truyền log script [P2pMessageType.scriptLog]
class ScriptLogMessage extends P2pMessage {
  String get executionId => payload['executionId'] as String? ?? '';
  String? get serial => payload['serial'] as String?;
  String get message => payload['message'] as String? ?? '';
  String get level => payload['level'] as String? ?? 'info';

  ScriptLogMessage({
    super.id,
    super.senderId,
    required String executionId,
    String? serial,
    required String message,
    String level = 'info',
  }) : super(
          type: P2pMessageType.scriptLog,
          payload: {
            'executionId': executionId,
            'serial': ?serial,
            'message': message,
            'level': level,
          },
        );
}

/// Tin nhắn thông báo script kết thúc [P2pMessageType.scriptFinished]
class ScriptFinishedMessage extends P2pMessage {
  String get executionId => payload['executionId'] as String? ?? '';
  List<String> get serials =>
      (payload['serials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
  int get exitCode => payload['exitCode'] as int? ?? 0;

  ScriptFinishedMessage({
    super.id,
    super.senderId,
    required String executionId,
    required List<String> serials,
    int exitCode = 0,
  }) : super(
          type: P2pMessageType.scriptFinished,
          payload: {
            'executionId': executionId,
            'serials': serials,
            'exitCode': exitCode,
          },
        );
}

/// Tin nhắn yêu cầu dừng script [P2pMessageType.stopScript]
class StopScriptMessage extends P2pMessage {
  String? get executionId => payload['executionId'] as String?;
  List<String> get serials =>
      (payload['serials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

  StopScriptMessage({
    super.id,
    super.senderId,
    String? executionId,
    List<String>? serials,
  }) : super(
          type: P2pMessageType.stopScript,
          payload: {
            'executionId': ?executionId,
            'serials': serials ?? [],
          },
        );
}

/// Tin nhắn yêu cầu chạy script [P2pMessageType.runScript]
class RunScriptMessage extends P2pMessage {
  String get scriptName => payload['scriptName'] as String? ?? '';
  List<String> get serials =>
      (payload['serials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

  RunScriptMessage({
    super.id,
    super.senderId,
    required String scriptName,
    required List<String> serials,
  }) : super(
          type: P2pMessageType.runScript,
          payload: {
            'scriptName': scriptName,
            'serials': serials,
          },
        );
}

/// Tin nhắn quảng bá thông tin node [P2pMessageType.peerAnnounce]
class PeerAnnounceMessage extends P2pMessage {
  String get peerType => payload['peerType'] as String? ?? '';
  int? get wsPort => payload['wsPort'] as int?;

  PeerAnnounceMessage({
    super.id,
    super.senderId,
    required String peerType,
    int? wsPort,
  }) : super(
          type: P2pMessageType.peerAnnounce,
          payload: {
            'peerType': peerType,
            'wsPort': ?wsPort,
          },
        );
}

/// Tin nhắn cập nhật trạng thái thiết bị [P2pMessageType.deviceStatusUpdate]
class DeviceStatusUpdateMessage extends P2pMessage {
  String get serial => payload['serial'] as String? ?? '';
  String get status => payload['status'] as String? ?? '';
  String? get reason => payload['reason'] as String?;
  String? get executionId => payload['executionId'] as String?;

  DeviceStatusUpdateMessage({
    super.id,
    super.senderId,
    required String serial,
    required String status,
    String? reason,
    String? executionId,
  }) : super(
          type: P2pMessageType.deviceStatusUpdate,
          payload: {
            'serial': serial,
            'status': status,
            'reason': ?reason,
            'executionId': ?executionId,
          },
        );
}

/// Tin nhắn thông báo ngắt kết nối nút P2P [P2pMessageType.peerDisconnected]
class PeerDisconnectedMessage extends P2pMessage {
  String get disconnectedPeerId => senderId;

  PeerDisconnectedMessage({
    super.id,
    required String disconnectedPeerId,
  }) : super(
          type: P2pMessageType.peerDisconnected,
          senderId: disconnectedPeerId,
          payload: {},
        );
}
