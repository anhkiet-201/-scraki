import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scraki/core/stores/device_manager_store.dart';
import 'package:scraki/features/device/domain/repositories/device_repository.dart';
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

import 'package:scraki/core/config/settings_config_provider.dart';

// Mocks
class MockDeviceRepository extends Mock implements DeviceRepository {}
class MockSettingsConfigProvider extends Mock implements SettingsConfigProvider {}

void main() {
  late MockDeviceRepository repository;
  late MockSettingsConfigProvider configProvider;
  late DeviceManagerStore store;

  setUp(() {
    repository = MockDeviceRepository();
    configProvider = MockSettingsConfigProvider();
    when(() => configProvider.ipRange).thenReturn('10.10.0.0');
    store = DeviceManagerStore(repository, configProvider);
  });

  group('DeviceManagerStore', () {
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
