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
    'zh-CN',
    'ko-KR',
    'ar-SA',
  ];

  static String getLanguageLabel(String lang) {
    switch (lang) {
      case 'ja-JP':
        return 'ja-JP (Japanese / japan)';
      case 'en-US':
        return 'en-US (English / usa)';
      case 'es-ES':
        return 'es-ES (Spanish / spain)';
      case 'ru-RU':
        return 'ru-RU (Russian / russia)';
      case 'de-DE':
        return 'de-DE (German / germany)';
      case 'fr-FR':
        return 'fr-FR (French / france)';
      case 'it-IT':
        return 'it-IT (Italian / italy)';
      case 'zh-CN':
        return 'zh-CN (Chinese / mandarin)';
      case 'ko-KR':
        return 'ko-KR (Korean / korea)';
      case 'ar-SA':
        return 'ar-SA (Arabic / arabia)';
      default:
        return lang;
    }
  }

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
