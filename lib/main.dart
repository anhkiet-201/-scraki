import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'core/di/injection.dart';
import 'presentation/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scraki',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00ADB5),
        ), // Cyberpunk-ish Teal
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
