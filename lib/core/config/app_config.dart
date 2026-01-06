import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get geminiModel =>
      dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash-lite';
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://timviec.vieclamhr.com/api';
}
