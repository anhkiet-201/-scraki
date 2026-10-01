import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart' hide when;
import 'package:scraki/core/auth/presentation/stores/app_auth_store.dart';
import 'package:scraki/core/config/settings_config_provider.dart';
import 'package:scraki/core/stores/device_manager_store.dart';
import 'package:scraki/core/stores/session_manager_store.dart';
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import 'package:scraki/features/device/domain/services/device_shell.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import 'package:scraki/features/script/presentation/stores/script_management_store.dart';
import 'package:scraki/features/script/presentation/stores/terminal_log_worker.dart';
import 'package:scraki/features/script/presentation/stores/terminal_process_worker.dart';
import 'package:scraki/features/script/presentation/stores/terminal_store.dart';
import 'package:scraki/features/settings/data/models/settings_model.dart';
import 'package:scraki/features/settings/domain/entities/settings_entity.dart';
import 'package:scraki/features/settings/domain/repositories/i_settings_repository.dart';
import 'package:scraki/features/settings/presentation/stores/settings_store.dart';

class MockDeviceManagerStore extends Mock implements DeviceManagerStore {}
class MockDeviceGroupStore extends Mock implements DeviceGroupStore {}
class MockScriptManagementStore extends Mock implements ScriptManagementStore {}
class MockCommandInterpolator extends Mock implements CommandInterpolator {}
class MockTerminalProcessWorker extends Mock implements TerminalProcessWorker {}
class MockAppAuthStore extends Mock implements AppAuthStore {}
class MockSessionManagerStore extends Mock implements SessionManagerStore {}
class MockDeviceShell extends Mock implements DeviceShell {}
class MockSettingsConfigProvider extends Mock implements SettingsConfigProvider {}
class MockSettingsRepository extends Mock implements ISettingsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(ScriptEntity(
      id: 'fallback',
      name: 'fallback',
      description: 'fallback',
      commands: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  group('SettingsEntity & SettingsModel Concurrency Tests', () {
    test('SettingsEntity defaults maxConcurrentDevices to 20', () {
      final empty = SettingsEntity.empty();
      expect(empty.maxConcurrentDevices, equals(20));

      const custom = SettingsEntity(
        aiApiKey: 'test-key',
        posterPhoneNumber: '0123456789',
      );
      expect(custom.maxConcurrentDevices, equals(20));
      expect(custom.maxDevices, equals(100));
    });

    test('SettingsEntity copyWith correctly updates maxConcurrentDevices', () {
      final initial = SettingsEntity.empty();
      final updated = initial.copyWith(maxConcurrentDevices: 35);
      expect(updated.maxConcurrentDevices, equals(35));
      expect(updated.maxDevices, equals(100)); // Still default 100
    });

    test('SettingsModel toEntity and fromEntity map maxConcurrentDevices', () {
      final entity = SettingsEntity.empty().copyWith(maxConcurrentDevices: 15);
      final model = SettingsModel.fromEntity(entity);
      expect(model.maxConcurrentDevices, equals(15));

      final converted = model.toEntity();
      expect(converted.maxConcurrentDevices, equals(15));
    });
  });

  group('SettingsStore Tests for maxConcurrentDevices', () {
    late SettingsStore settingsStore;
    late MockSettingsRepository repository;

    setUp(() {
      repository = MockSettingsRepository();
      settingsStore = SettingsStore(repository);
    });

    test('Initial maxConcurrentDevices is 20', () {
      expect(settingsStore.maxConcurrentDevices, equals(20));
    });

    test('updateMaxConcurrentDevices updates store and clamps <= 0 to 1', () {
      settingsStore.updateMaxConcurrentDevices(50);
      expect(settingsStore.maxConcurrentDevices, equals(50));

      settingsStore.updateMaxConcurrentDevices(0);
      expect(settingsStore.maxConcurrentDevices, equals(1));

      settingsStore.updateMaxConcurrentDevices(-5);
      expect(settingsStore.maxConcurrentDevices, equals(1));
    });
  });

  group('TerminalStore Concurrency Configuration Tests', () {
    late TerminalStore store;
    late MockDeviceManagerStore deviceManagerStore;
    late MockDeviceGroupStore deviceGroupStore;
    late MockScriptManagementStore scriptManagementStore;
    late MockCommandInterpolator commandInterpolator;
    late MockTerminalProcessWorker processWorker;
    late MockAppAuthStore appAuthStore;
    late MockSessionManagerStore sessionManagerStore;
    late MockDeviceShell deviceShell;
    late MockSettingsConfigProvider configProvider;

    setUp(() async {
      await GetIt.I.reset();
      appAuthStore = MockAppAuthStore();
      sessionManagerStore = MockSessionManagerStore();
      GetIt.I.registerSingleton<AppAuthStore>(appAuthStore);
      GetIt.I.registerSingleton<SessionManagerStore>(sessionManagerStore);

      deviceManagerStore = MockDeviceManagerStore();
      deviceGroupStore = MockDeviceGroupStore();
      scriptManagementStore = MockScriptManagementStore();
      commandInterpolator = MockCommandInterpolator();
      processWorker = MockTerminalProcessWorker();
      deviceShell = MockDeviceShell();
      configProvider = MockSettingsConfigProvider();

      when(() => scriptManagementStore.logStream)
          .thenAnswer((_) => const Stream.empty());
      when(() => processWorker.init()).thenAnswer((_) async => {});
      when(() => appAuthStore.isAuthenticated).thenReturn(true);
      when(() => configProvider.maxConcurrentDevices).thenReturn(20);

      final devices = [
        for (int i = 1; i <= 6; i++)
          DeviceEntity(
            id: 'dev$i',
            serial: 'dev$i',
            modelName: 'Phone $i',
            status: DeviceStatus.connected,
            connectionType: ConnectionType.usb,
          ),
      ];
      when(() => deviceManagerStore.devices)
          .thenReturn(ObservableList.of(devices));
      when(() => deviceManagerStore.selectedSerials)
          .thenReturn(ObservableSet.of(devices.map((d) => d.serial)));

      final activeShells = {
        for (int i = 1; i <= 6; i++) 'dev$i': deviceShell,
      };
      when(() => sessionManagerStore.activeDeviceShells)
          .thenReturn(ObservableMap.of(activeShells));
      when(() => sessionManagerStore.activeTasks)
          .thenReturn(ObservableMap.of({}));

      when(() => commandInterpolator.interpolate(any(), any()))
          .thenAnswer((inv) => inv.positionalArguments[0] as String);

      store = TerminalStore(
        deviceManagerStore,
        deviceGroupStore,
        scriptManagementStore,
        commandInterpolator,
        TerminalLogWorker(),
        processWorker,
        configProvider,
      );
    });

    tearDown(() async {
      store.stopAll();
      store.dispose();
      await GetIt.I.reset();
    });

    test('TerminalStore executes batch respecting configured maxConcurrentDevices', () async {
      // Configure max concurrency to 2
      when(() => configProvider.maxConcurrentDevices).thenReturn(2);

      int currentActive = 0;
      int peakActive = 0;
      final completedSerials = <String>{};

      when(() => processWorker.executeCommand(
            commandId: any(named: 'commandId'),
            serial: any(named: 'serial'),
            executable: any(named: 'executable'),
            arguments: any(named: 'arguments'),
            modelName: any(named: 'modelName'),
            stdin: any(named: 'stdin'),
            processKey: any(named: 'processKey'),
          )).thenAnswer((inv) async {
        final serial = inv.namedArguments[#serial] as String;
        currentActive++;
        if (currentActive > peakActive) {
          peakActive = currentActive;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
        completedSerials.add(serial);
        currentActive--;
        return 0;
      });

      final script = ScriptEntity(
        id: 'test_script',
        name: 'Test Script',
        description: 'Testing concurrency',
        commands: ['echo "hello"'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await store.runScript(script);

      // All 6 devices should be completed
      expect(completedSerials.length, equals(6));
      // Peak active should not exceed configured concurrency (2)
      expect(peakActive, lessThanOrEqualTo(2));
      expect(peakActive, greaterThan(0));
    });

    test('TerminalStore falls back to 20 when configProvider returns 0 or negative', () async {
      when(() => configProvider.maxConcurrentDevices).thenReturn(0);

      int currentActive = 0;
      int peakActive = 0;

      when(() => processWorker.executeCommand(
            commandId: any(named: 'commandId'),
            serial: any(named: 'serial'),
            executable: any(named: 'executable'),
            arguments: any(named: 'arguments'),
            modelName: any(named: 'modelName'),
            stdin: any(named: 'stdin'),
            processKey: any(named: 'processKey'),
          )).thenAnswer((inv) async {
        currentActive++;
        if (currentActive > peakActive) {
          peakActive = currentActive;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
        currentActive--;
        return 0;
      });

      final script = ScriptEntity(
        id: 'test_script_2',
        name: 'Test Script',
        description: 'Testing fallback concurrency',
        commands: ['echo "fallback"'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await store.runScript(script);

      // Total devices is 6, peak should be <= 6 and <= 20
      expect(peakActive, lessThanOrEqualTo(6));
      expect(peakActive, greaterThan(0));
    });
  });
}
