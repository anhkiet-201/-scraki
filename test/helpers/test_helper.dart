import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Helper to pump a widget wrapped in MaterialApp
// We can extend this to support Provider/GetIt injection if needed.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget) async {
    await pumpWidget(MaterialApp(home: Scaffold(body: widget)));
    await pump();
  }
}

void registerFallbackValues() {
  // Register generic fallbacks for mocktail if needed
  // registerFallbackValue(FakeDeviceEntity());
}
