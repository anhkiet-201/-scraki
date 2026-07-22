import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/network/p2p/p2p_messages.dart';
import 'package:scraki/core/network/p2p/p2p_peer_node.dart';
import 'package:scraki/core/stores/device_manager_store.dart';
import 'package:scraki/core/stores/session_manager_store.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
import 'package:scraki/features/script/domain/entities/log_entry.dart';
import 'package:scraki/features/script/presentation/stores/terminal_store.dart';
import 'package:uuid/uuid.dart';

@lazySingleton
class P2pGuiService {
  final DeviceManagerStore _deviceManagerStore;
  final DeviceGroupStore _deviceGroupStore;
  final TerminalStore _terminalStore;
  final SessionManagerStore _sessionManagerStore;

  late final P2pPeerNode _peerNode;
  StreamSubscription<P2pMessage>? _messageSub;

  final ObservableSet<String> activeScriptSerials = ObservableSet<String>();

  P2pGuiService(
    this._deviceManagerStore,
    this._deviceGroupStore,
    this._terminalStore,
    this._sessionManagerStore,
  ) {
    _peerNode = P2pPeerNode(peerType: 'GUI');
  }

  /// Initializes the P2P GUI node and starts listening for CLI requests & events
  Future<void> init() async {
    await _peerNode.start(preferredWsPort: 9090);
    logger.i('[P2pGuiService] Started GUI P2P Node on port ${_peerNode.wsPort}');

    _messageSub = _peerNode.onMessage.listen(_handleIncomingMessage);

    // Ask active CLI nodes if any script is currently running
    _queryActiveScripts();
  }

  void _queryActiveScripts() {
    final queryMsg = P2pMessage(
      id: const Uuid().v4(),
      type: P2pMessageType.queryActiveScripts,
      senderId: _peerNode.peerId,
      payload: {},
    );
    _peerNode.broadcastMessage(queryMsg);
  }

  /// Sends a P2P request to CLI nodes to stop script execution (for specific serials or all)
  void stopScript({List<String>? serials}) {
    final stopMsg = P2pMessage(
      id: const Uuid().v4(),
      type: P2pMessageType.stopScript,
      senderId: _peerNode.peerId,
      payload: {
        'serials': serials ?? [],
      },
    );
    _peerNode.broadcastMessage(stopMsg);

    runInAction(() {
      final targets = serials != null && serials.isNotEmpty ? serials : activeScriptSerials.toList();
      for (final s in targets) {
        activeScriptSerials.remove(s);
        _sessionManagerStore.clearDeviceTask(s);
        _terminalStore.shellStates[s] = false;
      }
      if (activeScriptSerials.isEmpty) {
        _terminalStore.isExecuting = false;
      }

      final entry = LogEntry(
        timestamp: DateTime.now(),
        message: '🛑 [GUI P2P] Đã gửi lệnh dừng kịch bản tới CLI ${serials != null && serials.isNotEmpty ? 'cho thiết bị: ${serials.join(', ')}' : ''}',
        type: LogType.error,
      );
      _terminalStore.terminalOutput.add(entry);
    });
  }

  void _handleIncomingMessage(P2pMessage msg) {
    switch (msg.type) {
      case P2pMessageType.queryGroups:
        _handleQueryGroups(msg);
        break;
      case P2pMessageType.querySelectedDevices:
        _handleQuerySelectedDevices(msg);
        break;
      case P2pMessageType.peerAnnounce:
        _queryActiveScripts();
        break;
      case 'PEER_DISCONNECTED':
        _handlePeerDisconnected(msg);
        break;
      case P2pMessageType.activeScriptsStatus:
      case P2pMessageType.scriptStarted:
        _handleScriptStarted(msg);
        break;
      case P2pMessageType.scriptLog:
        _handleScriptLog(msg);
        break;
      case P2pMessageType.scriptFinished:
        _handleScriptFinished(msg);
        break;
    }
  }

  void _handlePeerDisconnected(P2pMessage msg) {
    runInAction(() {
      if (activeScriptSerials.isNotEmpty) {
        for (final s in activeScriptSerials.toList()) {
          _sessionManagerStore.clearDeviceTask(s);
          _terminalStore.shellStates[s] = false;
        }
        activeScriptSerials.clear();
        _terminalStore.isExecuting = false;

        final entry = LogEntry(
          timestamp: DateTime.now(),
          message: '⚠️ [CLI P2P] CLI Peer ngắt kết nối. Đã tự động giải phóng tất cả TaskOverlay.',
          type: LogType.error,
        );
        _terminalStore.terminalOutput.add(entry);
      }
    });
  }

  void _handleQueryGroups(P2pMessage msg) {
    final groupsList = _deviceGroupStore.groups.map((g) {
      return {
        'id': g.id,
        'name': g.name,
        'serials': g.deviceSerials,
      };
    }).toList();

    final response = P2pMessage(
      id: const Uuid().v4(),
      type: P2pMessageType.groupsResponse,
      senderId: _peerNode.peerId,
      payload: {
        'replyTo': msg.id,
        'groups': groupsList,
      },
    );
    _peerNode.broadcastMessage(response);
  }

  void _handleQuerySelectedDevices(P2pMessage msg) {
    final selected = _deviceManagerStore.selectedSerials.toList();

    final response = P2pMessage(
      id: const Uuid().v4(),
      type: P2pMessageType.selectedDevicesResponse,
      senderId: _peerNode.peerId,
      payload: {
        'replyTo': msg.id,
        'selectedSerials': selected,
      },
    );
    _peerNode.broadcastMessage(response);
  }

  void _handleScriptStarted(P2pMessage msg) {
    final payload = msg.payload;
    final rawSerials = payload['serials'];
    final serials = rawSerials is List ? rawSerials.cast<String>() : <String>[];
    final scriptName = payload['scriptName'] as String? ?? 'Script';

    runInAction(() {
      activeScriptSerials.addAll(serials);
      _terminalStore.isExecuting = true;

      // Update TaskOverlay and shellState on each device
      for (final serial in serials) {
        _terminalStore.shellStates[serial] = true;
        _sessionManagerStore.updateDeviceTask(
          serial,
          type: DeviceTaskType.script,
          label: 'CLI: $scriptName',
          status: 'Đang thực thi kịch bản...',
          phase: DeviceTaskPhase.running,
        );
      }

      // Add log to terminal
      final entry = LogEntry(
        timestamp: DateTime.now(),
        message: '🚀 [CLI P2P] Kịch bản "$scriptName" đang chạy trên ${serials.length} thiết bị: ${serials.join(', ')}',
        type: LogType.info,
      );
      _terminalStore.terminalOutput.add(entry);
    });

    logger.i('[P2pGuiService] Script started from CLI on serials: $serials');
  }

  void _handleScriptLog(P2pMessage msg) {
    final payload = msg.payload;
    final serial = payload['serial'] as String? ?? 'system';
    final text = payload['message'] as String? ?? '';
    final level = payload['level'] as String? ?? 'info';

    LogType logType = LogType.info;
    if (level == 'error') {
      logType = LogType.error;
    } else if (level == 'command') {
      logType = LogType.command;
    } else if (level == 'output') {
      logType = LogType.output;
    }

    final entry = LogEntry(
      timestamp: DateTime.now(),
      message: text,
      serial: serial,
      type: logType,
    );

    runInAction(() {
      _terminalStore.terminalOutput.add(entry);
      if (!_terminalStore.deviceLogs.containsKey(serial)) {
        _terminalStore.deviceLogs[serial] = ObservableList<LogEntry>();
      }
      _terminalStore.deviceLogs[serial]!.add(entry);

      if (serial != 'system' && serial.isNotEmpty) {
        _sessionManagerStore.updateDeviceTask(
          serial,
          type: DeviceTaskType.script,
          status: text,
          phase: DeviceTaskPhase.running,
        );
      }
    });
  }

  void _handleScriptFinished(P2pMessage msg) {
    final payload = msg.payload;
    final rawSerials = payload['serials'];
    final serials = rawSerials is List ? rawSerials.cast<String>() : <String>[];
    final exitCode = payload['exitCode'] as int? ?? 0;

    runInAction(() {
      for (final s in serials) {
        activeScriptSerials.remove(s);
        _terminalStore.shellStates[s] = false;
        _sessionManagerStore.updateDeviceTask(
          s,
          type: DeviceTaskType.script,
          status: exitCode == 0 ? 'Hoàn thành' : 'Thất bại',
          phase: exitCode == 0 ? DeviceTaskPhase.success : DeviceTaskPhase.failed,
        );
        Future.delayed(const Duration(seconds: 3), () {
          _sessionManagerStore.clearDeviceTask(s);
        });
      }

      if (activeScriptSerials.isEmpty) {
        _terminalStore.isExecuting = false;
      }

      final entry = LogEntry(
        timestamp: DateTime.now(),
        message: '🏁 [CLI P2P] Kịch bản hoàn thành (Exit Code: $exitCode)',
        type: exitCode == 0 ? LogType.info : LogType.error,
      );
      _terminalStore.terminalOutput.add(entry);
    });

    logger.i('[P2pGuiService] Script finished with exit code $exitCode');
  }

  Future<void> dispose() async {
    await _messageSub?.cancel();
    await _peerNode.stop();
  }
}
