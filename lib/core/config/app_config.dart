import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:scraki/core/config/settings_config_provider.dart';
import 'package:scraki/core/di/injection.dart';

class AppConfig {
  /// Get Gemini API Key from Settings (user preference) or fallback to .env
  static String get geminiApiKey {
    try {
      final provider = getIt<SettingsConfigProvider>();
      final userApiKey = provider.aiApiKey;
      // Use user's API key if available, otherwise fallback to .env
      if (userApiKey.isNotEmpty) {
        return userApiKey;
      }
    } catch (e) {
      // If provider is not initialized yet, fallback to .env
    }
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  /// Get poster phone number from Settings (user preference)
  static String get posterPhoneNumber {
    try {
      final provider = getIt<SettingsConfigProvider>();
      return provider.posterPhoneNumber;
    } catch (e) {
      return '';
    }
  }

  static String get geminiModel =>
      dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash-lite';
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://timviec.vieclamhr.com/api';
}
