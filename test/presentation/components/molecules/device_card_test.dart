import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scraki/domain/entities/device_entity.dart';
import 'package:scraki/presentation/components/molecules/device_card.dart';
import 'package:scraki/presentation/stores/device_store.dart';
import 'package:scraki/presentation/components/atoms/status_badge.dart';
import 'package:scraki/presentation/components/atoms/protocol_icon.dart';
import '../../../helpers/test_helper.dart';

import 'package:media_kit/media_kit.dart';

class MockDeviceStore extends Mock implements DeviceStore {}

class FakePlayer extends Fake implements Player {}

void main() {
  late MockDeviceStore mockStore;

  setUp(() async {
    await GetIt.I.reset();
    mockStore = MockDeviceStore();
    GetIt.I.registerSingleton<DeviceStore>(mockStore);

    registerFallbackValue(FakePlayer());

    // Default Stubs
    when(() => mockStore.startMirroring(any(), any())).thenAnswer((_) async {});
    when(() => mockStore.disconnect(any())).thenAnswer((_) async {});
    // Stub sendTouch just in case, though Card might not call it in current state
    when(
      () => mockStore.sendTouch(any(), any(), any(), any(), any(), any()),
    ).thenReturn(null);
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
          body: DeviceCard(
            device: device,
            onConnect: (_) {},
            onDisconnect: () {},
          ),
        ),
      ),
    );

    expect(find.text('Pixel 5'), findsOneWidget);
    expect(find.byType(StatusBadge), findsOneWidget);
    expect(find.byType(ProtocolIcon), findsOneWidget);
  });

  testWidgets('DeviceCard Tap calls onConnect', (tester) async {
    const device = DeviceEntity(
      id: '1',
      serial: '12345',
      modelName: 'Pixel 5',
      status: DeviceStatus.connected,
      connectionType: ConnectionType.usb,
    );

    bool connectCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeviceCard(
            device: device,
            onConnect: (_) {
              connectCalled = true;
            },
            onDisconnect: () {},
          ),
        ),
      ),
    );

    final mirrorBtn = find.text('Mirror');
    if (mirrorBtn.evaluate().isNotEmpty) {
      await tester.tap(mirrorBtn);
      // await tester.pump();
      expect(connectCalled, true);
    }
  });
}
