import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import '../../core/di/injection.dart';
import '../../data/datasources/scrcpy_client.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/entities/scrcpy_options.dart';
import '../../domain/repositories/i_device_repository.dart';
import '../../data/services/scrcpy_service.dart';
import '../../data/services/device_control_service.dart';
import '../../data/services/video_proxy_service.dart';
import '../../data/utils/scrcpy_input_serializer.dart';

part 'device_store.g.dart';

@lazySingleton
class DeviceStore = _DeviceStore with _$DeviceStore;

abstract class _DeviceStore with Store {
  final IDeviceRepository _repository;
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
          // Auto-select broadcast targets if needed? No, user manual selection.
        });
      },
    );
  }

  @action
  Future<String> startMirroring(String serial) async {
    errorMessage = null;
    try {
      print('[DeviceStore] Starting mirroring for $serial');

      // 1. Create a server socket FIRST (before starting scrcpy server)
      const options = ScrcpyOptions();

      print('[DeviceStore] Creating server socket on all IPv4 interfaces...');
      final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      final localPort = serverSocket.port;
      print('[DeviceStore] Server socket listening on $localPort');

      // 2. Initialize Scrcpy Server
      await _scrcpyService.initServer(serial, options, localPort);

      // 3. Wait for server to connect
      final clientSocket = await serverSocket.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          serverSocket.close();
          throw Exception('Timeout waiting for scrcpy server connection');
        },
      );
      serverSocket.close();

      // Get scrcpy client instance
      final scrcpyClient = getIt<ScrcpyClient>();

      // 4. Start Video Proxy
      final proxyPort = await _videoProxyService.startProxyFromStream(
        scrcpyClient.videoStream,
      );

      // 5. Parse header
      await scrcpyClient.parseHeaderFromSocket(clientSocket);

      // 6. Return Proxy URL
      final url = 'tcp://127.0.0.1:$proxyPort';
      print('Stream available at $url');
      return url;
    } catch (e, stackTrace) {
      print('[DeviceStore] ERROR: $e');
      print('[DeviceStore] Stack trace: $stackTrace');
      runInAction(() => errorMessage = 'Mirror failed: $e');
      rethrow;
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

  @action
  void sendTouch(
    String serial,
    int x,
    int y,
    int action,
    int width,
    int height,
  ) {
    if (x < 0 || y < 0) return;

    final message = TouchControlMessage(
      action: action,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    _controlService.sendTouch(serial, message);
  }
}
