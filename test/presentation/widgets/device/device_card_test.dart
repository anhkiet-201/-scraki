import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobx/mobx.dart' hide when;
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import 'package:scraki/features/device/presentation/widgets/device_card/device_card.dart';
import 'package:scraki/features/device/presentation/widgets/phone_view/store/phone_view_store.dart';
import 'package:scraki/features/device/presentation/widgets/phone_view/phone_view.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
import 'package:scraki/features/device/presentation/stores/device_nickname_store.dart';
import 'package:scraki/features/device/data/datasources/scrcpy_service.dart';
import 'package:scraki/features/device/data/datasources/video_worker_manager.dart';
import 'package:scraki/features/dashboard/presentation/stores/dashboard_store.dart';
import 'package:scraki/features/device/domain/services/i_device_task_service.dart';
import 'package:scraki/features/device/data/datasources/adb_remote_data_source.dart';
import 'package:scraki/features/device/domain/services/i_video_decoder_service.dart';
import 'package:scraki/core/stores/session_manager_store.dart';
import 'package:scraki/core/auth/presentation/stores/app_auth_store.dart';
import 'package:scraki/features/device/domain/entities/device_group_entity.dart';
import 'package:scraki/features/device/domain/entities/mirror_session.dart';
import 'package:scraki/core/widgets/status_badge.dart';
import 'package:scraki/core/widgets/protocol_icon.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MockPhoneViewStore extends Mock implements PhoneViewStore {}
class MockDeviceGroupStore extends Mock implements DeviceGroupStore {}
class MockDeviceNicknameStore extends Mock implements DeviceNicknameStore {}
class MockScrcpyService extends Mock implements ScrcpyService {}
class MockVideoWorkerManager extends Mock implements VideoWorkerManager {}
class MockDashboardStore extends Mock implements DashboardStore {}
class MockDeviceTaskService extends Mock implements IDeviceTaskService {}
class MockAdbRemoteDataSource extends Mock implements IAdbRemoteDataSource {}
class MockVideoDecoderService extends Mock implements IVideoDecoderService {}
class MockSessionManagerStore extends Mock implements SessionManagerStore {}
class MockAppAuthStore extends Mock implements AppAuthStore {}

void main() {
  late MockPhoneViewStore mockStore;

  setUp(() async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    await GetIt.I.reset();
    mockStore = MockPhoneViewStore();
    final mockGroupStore = MockDeviceGroupStore();
    final mockNicknameStore = MockDeviceNicknameStore();
    final mockScrcpyService = MockScrcpyService();
    final mockVideoWorkerManager = MockVideoWorkerManager();
    final mockDashboardStore = MockDashboardStore();
    final mockDeviceTaskService = MockDeviceTaskService();
    final mockAdbRemoteDataSource = MockAdbRemoteDataSource();
    final mockVideoDecoderService = MockVideoDecoderService();
    final mockSessionManagerStore = MockSessionManagerStore();
    final mockAppAuthStore = MockAppAuthStore();

    // Stub DeviceGroupStore
    when(() => mockGroupStore.groups).thenReturn(ObservableList<DeviceGroupEntity>());
    
    // Stub DeviceNicknameStore
    when(() => mockNicknameStore.getNickname(any(), any())).thenAnswer((invocation) {
      return invocation.positionalArguments[1] as String;
    });

    // Stub AppAuthStore
    when(() => mockAppAuthStore.isAuthenticated).thenReturn(true);

    // Stub DashboardStore
    when(() => mockDashboardStore.selectedIndex).thenReturn(0);
    when(() => mockDashboardStore.searchQuery).thenReturn('');

    // Stub SessionManagerStore
    when(() => mockSessionManagerStore.activeSessions).thenReturn(ObservableMap<String, MirrorSession>());
    when(() => mockSessionManagerStore.activeTasks).thenReturn(ObservableMap<String, DeviceTaskState?>());
    when(() => mockSessionManagerStore.floatingSerial).thenReturn(null);
    when(() => mockSessionManagerStore.isFloatingVisible).thenReturn(false);

    // Stub ScrcpyService
    when(() => mockScrcpyService.isDeviceConnected(any())).thenAnswer((_) async => false);
    when(() => mockScrcpyService.killServer(any())).thenAnswer((_) async => {});

    GetIt.I.registerSingleton<PhoneViewStore>(mockStore);
    GetIt.I.registerSingleton<DeviceGroupStore>(mockGroupStore);
    GetIt.I.registerSingleton<DeviceNicknameStore>(mockNicknameStore);
    GetIt.I.registerSingleton<ScrcpyService>(mockScrcpyService);
    GetIt.I.registerSingleton<VideoWorkerManager>(mockVideoWorkerManager);
    GetIt.I.registerSingleton<DashboardStore>(mockDashboardStore);
    GetIt.I.registerSingleton<IDeviceTaskService>(mockDeviceTaskService);
    GetIt.I.registerSingleton<IAdbRemoteDataSource>(mockAdbRemoteDataSource);
    GetIt.I.registerSingleton<IVideoDecoderService>(mockVideoDecoderService);
    GetIt.I.registerSingleton<SessionManagerStore>(mockSessionManagerStore);
    GetIt.I.registerSingleton<AppAuthStore>(mockAppAuthStore);
  });

  testWidgets('DeviceCard renders device info correctly', (tester) async {
    const device = DeviceEntity(
      id: '1',
      serial: '12345',
      modelName: 'Pixel 5',
      status: DeviceStatus.connected,
      connectionType: ConnectionType.usb,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeviceCard(device: device, onDisconnect: () {}),
        ),
      ),
    );

    expect(find.text('Pixel 5'), findsOneWidget);
    expect(find.byType(StatusBadge), findsOneWidget);
    expect(find.byIcon(Icons.usb_rounded), findsOneWidget);
    expect(find.byType(PhoneView), findsOneWidget);
  });
}

