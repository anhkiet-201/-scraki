import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import 'package:scraki/features/device/presentation/widgets/device_card/device_card.dart';
import 'package:scraki/features/device/presentation/widgets/phone_view/store/phone_view_store.dart';
import 'package:scraki/core/widgets/status_badge.dart';
import 'package:scraki/core/widgets/protocol_icon.dart';

class MockPhoneViewStore extends Mock implements PhoneViewStore {}

void main() {
  late MockPhoneViewStore mockStore;

  setUp(() async {
    await GetIt.I.reset();
    mockStore = MockPhoneViewStore();
    GetIt.I.registerSingleton<PhoneViewStore>(mockStore);
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
    expect(find.byType(ProtocolIcon), findsOneWidget);
    expect(find.text('Mirror'), findsOneWidget);
  });
}
