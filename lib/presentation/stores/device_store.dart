import 'dart:io';
import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import '../../core/di/injection.dart';
import '../../data/datasources/scrcpy_client.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/entities/scrcpy_options.dart';
import '../../domain/repositories/device_repository.dart';
import '../../data/services/scrcpy_service.dart';
import '../../data/services/device_control_service.dart';
import '../../data/services/video_proxy_service.dart';
import '../../data/utils/scrcpy_input_serializer.dart';
import '../../domain/entities/mirror_session.dart';
import '../../core/utils/logger.dart';

part 'device_store.g.dart';

@lazySingleton
class DeviceStore = _DeviceStore with _$DeviceStore;

/// Store responsible for managing device-related state and mirroring sessions.
///
/// It orchestrates the process of loading devices, starting mirroring,
/// and handling input events.
abstract class _DeviceStore with Store {
  final DeviceRepository _repository;
  final ScrcpyService _scrcpyService;
  final DeviceControlService _controlService;
  final VideoProxyService _videoProxyService;

  _DeviceStore(
    this._repository,
    this._scrcpyService,
    this._controlService,
    this._videoProxyService,
  );

  @observable
  ObservableList<DeviceEntity> devices = ObservableList<DeviceEntity>();

  @observable
  ObservableSet<String> selectedSerials = ObservableSet<String>();

  @observable
  bool isBroadcastingMode = false;

  @observable
  ObservableFuture<void>? loadDevicesFuture;

  @observable
  String? errorMessage;

  @computed
  bool get isLoading => loadDevicesFuture?.status == FutureStatus.pending;

  @action
  void toggleBroadcasting() {
    isBroadcastingMode = !isBroadcastingMode;
  }

  @action
  void toggleDeviceSelection(String serial) {
    if (selectedSerials.contains(serial)) {
      selectedSerials.remove(serial);
    } else {
      selectedSerials.add(serial);
    }
  }

  @action
  Future<void> loadDevices() async {
    errorMessage = null;
    loadDevicesFuture = ObservableFuture(_loadDevicesInternal());
    await loadDevicesFuture;
  }

  Future<void> _loadDevicesInternal() async {
    final result = await _repository.getConnectedDevices();
    result.fold(
      (failure) {
        runInAction(() {
          errorMessage = failure.message;
          devices.clear();
        });
      },
      (list) {
        runInAction(() {
          devices.clear();
          devices.addAll(list);
        });
      },
    );
  }

  @action
  Future<MirrorSession> startMirroring(String serial) async {
    errorMessage = null;

    // Force stop previous session if any to ensure cleanup
    await stopMirroring(serial);

    // Wait for Scrcpy Server on device to release resources (Camera/Encoder)
    // await Future.delayed(const Duration(milliseconds: 1000));

    try {
      logger.i('[DeviceStore] Starting mirroring for $serial');

      // 1. Create a server socket FIRST (before starting scrcpy server)
      const options = ScrcpyOptions();

      logger.d(
        '[DeviceStore] Creating server socket on all IPv4 interfaces...',
      );
      final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      final localPort = serverSocket.port;
      logger.i('[DeviceStore] Server socket listening on $localPort');

      await _scrcpyService.initServer(serial, options, localPort);

      // 3. Handle connections (Video, then Control)
      final completer = Completer<MirrorSession>();
      int connectionCount = 0;

      // We expect 2 connections: Video and Control (Audio disabled)
      serverSocket.listen(
        (socket) async {
          connectionCount++;
          logger.d(
            '[DeviceStore] Connection $connectionCount received from ${socket.remoteAddress.address}',
          );

          if (connectionCount == 1) {
            // --- VIDEO SOCKET ---
            try {
              final scrcpyClient = getIt<ScrcpyClient>();

              // Parse Header & Get Session (Stream)
              final session = await scrcpyClient.parseHeaderFromSocket(socket);

              // Start Video Proxy with the specific stream for this device
              final proxyPort = await _videoProxyService.startProxyFromStream(
                serial,
                session.videoStream,
              );

              // Return Session info
              final url = 'tcp://127.0.0.1:$proxyPort';
              logger.i(
                '[DeviceStore] Stream available at $url (${session.header.width}x${session.header.height})',
              );
              if (!completer.isCompleted) {
                completer.complete(
                  MirrorSession(
                    videoUrl: url,
                    width: session.header.width,
                    height: session.header.height,
                  ),
                );
              }
            } catch (e) {
              logger.e('[DeviceStore] Error setting up video', error: e);
              socket.destroy(); // Ensure accepted socket is closed on error
              if (!completer.isCompleted) completer.completeError(e);
              serverSocket.close();
            }
          } else if (connectionCount == 2) {
            // --- CONTROL SOCKET ---
            logger.d('[DeviceStore] Setting up Control Socket');
            _controlService.setControlSocket(serial, socket);

            // We have both, close listener
            logger.i(
              '[DeviceStore] All channels connected. Closing server listener.',
            );
            serverSocket.close();
          }
        },
        onError: (Object e) {
          logger.e('[DeviceStore] Server socket error', error: e);
          if (!completer.isCompleted) completer.completeError(e);
        },
      );

      return completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          serverSocket.close();
          throw Exception('Timeout waiting for connections');
        },
      );
    } catch (e, stackTrace) {
      logger.e(
        '[DeviceStore] ERROR during mirroring setup',
        error: e,
        stackTrace: stackTrace,
      );
      runInAction(() => errorMessage = 'Mirror failed: $e');
      rethrow;
    }
  }

  @action
  Future<void> stopMirroring(String serial) async {
    logger.i('[DeviceStore] Stopping mirroring for $serial');
    await _videoProxyService.stopProxy(serial);
    await _controlService.dispose(serial);
    _scrcpyService.cleanup(serial);

    try {
      await getIt<ScrcpyClient>().removeTunnel(serial, 0);
      await _scrcpyService.killServer(serial);
    } catch (e) {
      logger.w('[DeviceStore] Error cleaning up', error: e);
    }
  }

  @action
  Future<void> connectTcp(String ip, int port) async {
    errorMessage = null;
    final result = await _repository.connectTcp(ip, port);
    await result.fold(
      (failure) async => runInAction(() => errorMessage = failure.message),
      (_) async => await loadDevices(),
    );
  }

  @action
  Future<void> disconnect(String serial) async {
    errorMessage = null;
    final result = await _repository.disconnectDevice(serial);
    await result.fold(
      (failure) async => runInAction(() => errorMessage = failure.message),
      (_) async => await loadDevices(),
    );
  }

  void sendTouch(
    String serial,
    int x,
    int y,
    int action,
    int width,
    int height, {
    int buttons = 0,
  }) {
    if (x < 0 || y < 0) return;

    final message = TouchControlMessage(
      action: action,
      x: x,
      y: y,
      width: width,
      height: height,
      buttons: buttons,
      pointerId: 0, // Mouse always 0
    );

    _controlService.sendControlMessage(serial, message);
  }

  void sendScroll(
    String serial,
    int x,
    int y,
    int width,
    int height,
    int hScroll,
    int vScroll,
  ) {
    if (x < 0 || y < 0) return;

    final message = ScrollControlMessage(
      x: x,
      y: y,
      width: width,
      height: height,
      hScroll: hScroll,
      vScroll: vScroll,
    );

    _controlService.sendControlMessage(serial, message);
  }

  void sendKey(String serial, int keyCode, int action, {int metaState = 0}) {
    if (keyCode == 0) return;

    final message = KeyControlMessage(
      action: action, // 0=Down, 1=Up
      keyCode: keyCode,
      metaState: metaState,
    );

    _controlService.sendControlMessage(serial, message);
  }
}
