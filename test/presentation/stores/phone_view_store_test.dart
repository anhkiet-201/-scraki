import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scraki/presentation/stores/phone_view_store.dart';
import 'package:scraki/domain/repositories/device_repository.dart';
import 'package:scraki/data/services/scrcpy_service.dart';
import 'package:scraki/data/services/device_control_service.dart';
import 'package:scraki/data/services/video_proxy_service.dart';
import 'package:scraki/domain/entities/device_entity.dart';
import 'package:scraki/domain/entities/scrcpy_options.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

// Mocks
class MockDeviceRepository extends Mock implements DeviceRepository {}

class MockScrcpyService extends Mock implements ScrcpyService {}

class MockDeviceControlService extends Mock implements DeviceControlService {}

class MockVideoProxyService extends Mock implements VideoProxyService {}

void main() {
  late MockDeviceRepository repository;
  late MockScrcpyService scrcpyService;
  late MockDeviceControlService controlService;
  late MockVideoProxyService videoProxyService;
  late PhoneViewStore store;

  setUp(() {
    repository = MockDeviceRepository();
    scrcpyService = MockScrcpyService();
    controlService = MockDeviceControlService();
    videoProxyService = MockVideoProxyService();
    store = PhoneViewStore(
      repository,
      scrcpyService,
      controlService,
      videoProxyService,
    );

    registerFallbackValue(const ScrcpyOptions());
  });

  group('PhoneViewStore', () {
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
  });
}
