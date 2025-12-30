import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scraki/presentation/stores/device_store.dart';
import 'package:scraki/domain/repositories/i_device_repository.dart';
import 'package:scraki/data/services/scrcpy_service.dart';
import 'package:scraki/data/services/device_control_service.dart';
import 'package:scraki/data/services/video_proxy_service.dart';
import 'package:scraki/domain/entities/device_entity.dart';
import 'package:scraki/domain/entities/scrcpy_options.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media_kit/media_kit.dart';

// Mocks
class MockDeviceRepository extends Mock implements IDeviceRepository {}

class MockScrcpyService extends Mock implements ScrcpyService {}

class MockDeviceControlService extends Mock implements DeviceControlService {}

class MockVideoProxyService extends Mock implements VideoProxyService {}

class MockPlayer extends Mock implements Player {}

void main() {
  late MockDeviceRepository repository;
  late MockScrcpyService scrcpyService;
  late MockDeviceControlService controlService;
  late MockVideoProxyService videoProxyService;
  late DeviceStore store;

  setUp(() {
    repository = MockDeviceRepository();
    scrcpyService = MockScrcpyService();
    controlService = MockDeviceControlService();
    videoProxyService = MockVideoProxyService();
    store = DeviceStore(
      repository,
      scrcpyService,
      controlService,
      videoProxyService,
    );

    registerFallbackValue(const ScrcpyOptions());
    registerFallbackValue(Media(''));
  });

  group('DeviceStore', () {
    test('Initial State', () {
      expect(store.devices, isEmpty);
      expect(store.isLoading, false);
      expect(store.errorMessage, isNull);
    });

    test('loadDevices (Success)', () async {
      final devices = [
        const DeviceEntity(
          id: '1',
          serial: 'serial1',
          modelName: 'Pixel',
          status: DeviceStatus.connected,
          connectionType: ConnectionType.usb,
        ),
        const DeviceEntity(
          id: '2',
          serial: 'serial2',
          modelName: 'Samsung',
          status: DeviceStatus.connected,
          connectionType: ConnectionType.usb,
        ),
      ];
      when(
        () => repository.getConnectedDevices(),
      ).thenAnswer((_) async => Right(devices));

      final future = store.loadDevices();
      expect(store.isLoading, true); // Verify loading state during execution
      await future;

      expect(store.isLoading, false);
      expect(store.devices.length, 2);
      expect(store.devices[0].serial, 'serial1');
      expect(store.devices[1].serial, 'serial2');
      expect(store.errorMessage, isNull);
    });

    test('loadDevices (Failure)', () async {
      when(
        () => repository.getConnectedDevices(),
      ).thenAnswer((_) async => const Left(AdbFailure('ADB not found')));

      await store.loadDevices();

      expect(store.isLoading, false);
      expect(store.devices, isEmpty);
      expect(store.errorMessage, 'ADB not found');
    });

    test('startMirroring orchestrates service calls', () async {
      final player = MockPlayer();
      when(
        () => scrcpyService.initServer(any(), any(), any()),
      ).thenAnswer((_) async => 61550);
      when(
        () => controlService.connectControlSocket('serial1', 61550),
      ).thenAnswer((_) async {});
      when(
        () => videoProxyService.startProxy(61550),
      ).thenAnswer((_) async => 9000);
      when(() => player.open(any())).thenAnswer((_) async {});

      await store.startMirroring('serial1', player);

      verify(() => scrcpyService.initServer('serial1', any())).called(1);
      verify(
        () => controlService.connectControlSocket('serial1', 8080),
      ).called(1);
      verify(() => videoProxyService.startProxy(8080)).called(1);
      verify(() => player.open(any())).called(1);
    });
  });
}
