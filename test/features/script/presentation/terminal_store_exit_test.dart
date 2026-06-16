import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart' hide when;
import 'package:scraki/features/script/presentation/stores/terminal_store.dart';
import 'package:scraki/core/stores/device_manager_store.dart';
import 'package:scraki/features/script/presentation/stores/terminal_log_worker.dart';
import 'package:scraki/features/script/presentation/stores/terminal_process_worker.dart';
import 'package:scraki/features/script/presentation/stores/script_management_store.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
import 'package:scraki/core/auth/presentation/stores/app_auth_store.dart';
import 'package:scraki/core/stores/session_manager_store.dart';
import 'package:scraki/features/script/domain/interpolation/command_interpolator.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import 'package:scraki/features/device/domain/services/device_shell.dart';

// Mocks
class MockDeviceManagerStore extends Mock implements DeviceManagerStore {}
class MockDeviceGroupStore extends Mock implements DeviceGroupStore {}
class MockScriptManagementStore extends Mock implements ScriptManagementStore {}
class MockCommandInterpolator extends Mock implements CommandInterpolator {}
class MockTerminalProcessWorker extends Mock implements TerminalProcessWorker {}
class MockAppAuthStore extends Mock implements AppAuthStore {}
class MockSessionManagerStore extends Mock implements SessionManagerStore {}
class MockDeviceShell extends Mock implements DeviceShell {}

void main() {
  late TerminalStore store;
  late MockDeviceManagerStore deviceManagerStore;
  late MockDeviceGroupStore deviceGroupStore;
  late MockScriptManagementStore scriptManagementStore;
  late MockCommandInterpolator commandInterpolator;
  late MockTerminalProcessWorker processWorker;
  late MockAppAuthStore appAuthStore;
  late MockSessionManagerStore sessionManagerStore;
  late MockDeviceShell deviceShell;

  setUp(() {
    GetIt.I.reset();

    deviceManagerStore = MockDeviceManagerStore();
    deviceGroupStore = MockDeviceGroupStore();
    scriptManagementStore = MockScriptManagementStore();
    commandInterpolator = MockCommandInterpolator();
    processWorker = MockTerminalProcessWorker();
    appAuthStore = MockAppAuthStore();
    sessionManagerStore = MockSessionManagerStore();
    deviceShell = MockDeviceShell();

    // Register singletons
    GetIt.I.registerSingleton<AppAuthStore>(appAuthStore);
    GetIt.I.registerSingleton<SessionManagerStore>(sessionManagerStore);

    // Mock initial setups
    when(() => scriptManagementStore.logStream).thenAnswer((_) => const Stream.empty());
    when(() => processWorker.init()).thenAnswer((_) async => {});
    when(() => appAuthStore.isAuthenticated).thenReturn(true);
    when(() => deviceManagerStore.selectedSerials).thenReturn(ObservableSet.of({'dev1'}));
    when(() => deviceManagerStore.devices).thenReturn(ObservableList.of([
      const DeviceEntity(
        id: 'dev1',
        serial: 'dev1',
        modelName: 'Pixel 6',
        status: DeviceStatus.connected,
        connectionType: ConnectionType.usb,
      ),
    ]));

    // Mock active shell for device
    final activeShells = <String, DeviceShell>{'dev1': deviceShell};
    when(() => sessionManagerStore.activeDeviceShells).thenReturn(ObservableMap.of(activeShells));
    when(() => sessionManagerStore.activeTasks).thenReturn(ObservableMap.of({}));

    // Mock interpolator to return the same command
    when(() => commandInterpolator.interpolate(any(), any())).thenAnswer((inv) => inv.positionalArguments[0] as String);

    store = TerminalStore(
      deviceManagerStore,
      deviceGroupStore,
      scriptManagementStore,
      commandInterpolator,
      TerminalLogWorker(),
      processWorker,
    );
  });

  tearDown(() {
    GetIt.I.reset();
  });

  group('TerminalStore Exit Code 99 Tests', () {
    test('Script halts execution and breaks block loop when exitCode is 99', () async {
      final script = ScriptEntity(
        id: 'test_script',
        name: 'Test Exit 99',
        description: 'Test Script',
        commands: const [
          'input tap 100 200', // Block 1
          '#bash server',
          'exit 99',
          '#end bash',
          'input keyevent 4', // Block 3 (Should NOT be run)
        ],
      );

      final executedCommands = <String>[];

      // Setup process worker stub to capture executing commands and mock exit codes
      when(() => processWorker.executeCommand(
            commandId: any(named: 'commandId'),
            serial: any(named: 'serial'),
            executable: any(named: 'executable'),
            arguments: any(named: 'arguments'),
            modelName: any(named: 'modelName'),
            stdin: any(named: 'stdin'),
            processKey: any(named: 'processKey'),
          )).thenAnswer((inv) async {
        final executable = inv.namedArguments[#executable] as String;
        final args = inv.namedArguments[#arguments] as List<String>;
        final stdin = inv.namedArguments[#stdin] as String?;

        bool isExit99 = false;
        if (stdin != null && stdin.contains('exit 99')) {
          isExit99 = true;
        } else if (executable == 'powershell.exe') {
          final encodedIdx = args.indexOf('-EncodedCommand');
          if (encodedIdx != -1 && encodedIdx + 1 < args.length) {
            final encoded = args[encodedIdx + 1];
            try {
              final bytes = base64.decode(encoded);
              final decoded = String.fromCharCodes(
                List.generate(bytes.length ~/ 2, (i) => bytes[i * 2] + (bytes[i * 2 + 1] << 8)),
              );
              if (decoded.contains('exit 99')) {
                isExit99 = true;
              }
            } catch (_) {}
          }
        } else if (executable == 'sh' && args.any((arg) => arg.contains('exit 99'))) {
          isExit99 = true;
        }

        if (isExit99) {
          executedCommands.add('exit 99 block');
          return 99; // Mock early exit signal
        } else if (executable == 'adb' && args.contains('keyevent')) {
          // Block 3
          executedCommands.add('keyevent block');
          return 0;
        } else {
          // Block 1
          executedCommands.add(executable);
          return 0;
        }
      });

      await store.runScript(script);

      // Verify that block 3 was NOT executed (loop broken after exit 99)
      expect(executedCommands.length, equals(2));
      expect(executedCommands[0], equals('adb')); // Block 1 executed
      expect(executedCommands[1], equals('exit 99 block')); // Block 2 executed
      // Block 3 was skipped!
    });
  });
}
