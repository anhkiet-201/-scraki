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
    final queryMsg = QueryActiveScriptsMessage(
      senderId: _peerNode.peerId,
    );
    _peerNode.broadcastMessage(queryMsg);
  }

  /// Sends a P2P request to CLI nodes to stop script execution (for specific serials or all)
  void stopScript({List<String>? serials}) {
    final stopMsg = StopScriptMessage(
      senderId: _peerNode.peerId,
      serials: serials ?? [],
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
    final typedMsg = msg.toTypedMessage();
    logger.i('[P2pGuiService] ${typedMsg.type}: ${typedMsg.payload}');
    switch (typedMsg) {
      case QueryGroupsMessage():
        _handleQueryGroups(typedMsg);
        break;
      case QuerySelectedDevicesMessage():
        _handleQuerySelectedDevices(typedMsg);
        break;
      case PeerAnnounceMessage():
        _queryActiveScripts();
        break;
      case PeerDisconnectedMessage():
        _handlePeerDisconnected(typedMsg);
        break;
      case ActiveScriptsStatusMessage():
        _handleActiveScriptsStatus(typedMsg);
        break;
      case ScriptStartedMessage():
        _handleScriptStarted(typedMsg);
        break;
      case ScriptLogMessage():
        _handleScriptLog(typedMsg);
        break;
      case ScriptFinishedMessage():
        _handleScriptFinished(typedMsg);
        break;
      case DeviceStatusUpdateMessage():
        _handleDeviceStatusUpdate(typedMsg);
        break;
      default:
        break;
    }
  }

  void _handleActiveScriptsStatus(ActiveScriptsStatusMessage msg) {
    if (!msg.isExecuting) return;
    _handleScriptStarted(ScriptStartedMessage(
      scriptName: msg.scriptName ?? 'Script',
      serials: msg.serials,
      executionId: msg.executionId ?? '',
    ));
  }

  void _handlePeerDisconnected(PeerDisconnectedMessage msg) {
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

  void _handleQueryGroups(QueryGroupsMessage msg) {
    final groupsList = _deviceGroupStore.groups.map((g) {
      return {
        'id': g.id,
        'name': g.name,
        'serials': g.deviceSerials,
      };
    }).toList();

    final response = GroupsResponseMessage(
      senderId: _peerNode.peerId,
      replyId: msg.id,
      groups: groupsList,
    );
    _peerNode.broadcastMessage(response);
  }

  void _handleQuerySelectedDevices(QuerySelectedDevicesMessage msg) {
    final selected = _deviceManagerStore.selectedSerials.toList();

    final response = SelectedDevicesResponseMessage(
      senderId: _peerNode.peerId,
      replyId: msg.id,
      selectedSerials: selected,
    );
    _peerNode.broadcastMessage(response);
  }

  void _handleScriptStarted(ScriptStartedMessage msg) {
    List<String> serials = msg.serials;
    String scriptName = msg.scriptName;

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

  void _handleScriptLog(ScriptLogMessage msg) {
    final serial = msg.serial ?? 'system';
    final text = msg.message;
    final level = msg.level;

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

  void _handleScriptFinished(ScriptFinishedMessage msg) {
    final serials = msg.serials;
    final exitCode = msg.exitCode;

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

  void _handleDeviceStatusUpdate(DeviceStatusUpdateMessage msg) {
    final serial = msg.serial;
    final status = msg.status;
    final reason = msg.reason;

    if (serial.isEmpty) return;

    runInAction(() {
      if (status == 'stopped') {
        activeScriptSerials.remove(serial);
        _terminalStore.shellStates[serial] = false;

        final statusMsg = reason != null && reason.isNotEmpty
            ? 'Đã dừng ($reason)'
            : 'Đã dừng session';

        _sessionManagerStore.updateDeviceTask(
          serial,
          type: DeviceTaskType.script,
          status: statusMsg,
          phase: DeviceTaskPhase.failed,
        );

        Future.delayed(const Duration(seconds: 3), () {
          _sessionManagerStore.clearDeviceTask(serial);
        });

        if (activeScriptSerials.isEmpty) {
          _terminalStore.isExecuting = false;
        }

        final entry = LogEntry(
          timestamp: DateTime.now(),
          serial: serial,
          message: '🛑 [CLI P2P] Thiết bị $serial đã dừng session: ${reason ?? 'Hoàn tất dispose'}',
          type: LogType.error,
        );
        _terminalStore.terminalOutput.add(entry);
      }
    });

    logger.i('[P2pGuiService] Device status update for $serial: $status (reason: $reason)');
  }

  Future<void> dispose() async {
    await _messageSub?.cancel();
    await _peerNode.stop();
  }
}
