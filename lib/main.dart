import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:google_fonts/google_fonts.dart';
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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Modern Indigo
          brightness: Brightness.light,
          surface: Colors.white,
          surfaceVariant: const Color(0xFFF1F2F6),
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: Colors.white,
          titleTextStyle: GoogleFonts.outfit(
            color: const Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: const Color(0xFFF8FAFC),
          selectedIconTheme: const IconThemeData(color: Color(0xFF6366F1)),
          unselectedIconTheme: IconThemeData(
            color: const Color(0xFF64748B).withOpacity(0.8),
          ),
          selectedLabelTextStyle: GoogleFonts.outfit(
            color: const Color(0xFF6366F1),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelTextStyle: GoogleFonts.outfit(
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          indicatorColor: const Color(0xFF6366F1).withOpacity(0.1),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          clipBehavior: Clip.antiAlias,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
