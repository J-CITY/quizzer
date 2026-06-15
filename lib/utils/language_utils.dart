import 'package:flutter_tts/flutter_tts.dart';
import '../data/services/database_service.dart';

class LanguageUtils {
  static const List<String> defaultLanguages = [
    'ja-JP',
    'en-US',
    'es-ES',
    'ru-RU',
    'de-DE',
    'fr-FR',
    'it-IT',
  ];

  static Future<bool> isLanguageValid(String language) async {
    final tts = FlutterTts();
    final isAvailable = await tts.isLanguageAvailable(language);
    return isAvailable as bool;
  }

  static Future<bool> validateAndSaveCustomLanguage(String language, DatabaseService db) async {
    if (language.trim().isEmpty) return false;
    
    bool isValid = await isLanguageValid(language);
    if (!isValid) return false;

    final settings = await db.getSettings();
    if (!defaultLanguages.contains(language) && !settings.customLanguages.contains(language)) {
      settings.customLanguages.add(language);
      await db.saveSettings(settings);
    }
    return true;
  }
}
