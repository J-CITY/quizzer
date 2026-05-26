// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get errorNoSheetId => 'Specify Google Sheet ID in settings';

  @override
  String get errorNetwork =>
      'Failed to update words. Check your network connection.';

  @override
  String wordReading(String reading) {
    return 'Reading: $reading';
  }

  @override
  String wordTranslation(String translation) {
    return 'Translation: $translation';
  }

  @override
  String wordProgress(String progress) {
    return 'Progress: $progress / 5';
  }

  @override
  String wordLastTrained(String date) {
    return 'Last trained: $date';
  }

  @override
  String get never => 'Never';

  @override
  String get close => 'Close';

  @override
  String get searchHint => 'Search...';

  @override
  String get syncTooltip => 'Sync';

  @override
  String get noWordsFound => 'No words found';

  @override
  String get noWordsForTraining => 'No words for training';

  @override
  String get trainingResultsTitle => 'Training Results';

  @override
  String get trainingResultsPerfect => 'Perfect! No mistakes! 🎉';

  @override
  String trainingResultsMistakes(String count) {
    return 'Mistakes ($count):';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsQuestionsCount => 'Number of questions';

  @override
  String get settingsSheetId => 'Google Sheet ID';

  @override
  String get settingsSheetIdHint =>
      'Example: 1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsDesc => 'Remind to review words';

  @override
  String get settingsAutoTts => 'Auto TTS';

  @override
  String get settingsAutoTtsDesc => 'Plays Japanese words automatically';

  @override
  String get errorLoadingSettings => 'Error loading settings';

  @override
  String get tabAllWords => 'All words';

  @override
  String get tabCustomLists => 'Lists';

  @override
  String get errorEmptyListName => 'Enter list name';

  @override
  String get newListTitle => 'New List';

  @override
  String get editListTitle => 'List Settings';

  @override
  String get listNameLabel => 'List Name';

  @override
  String get selectWordsLabel => 'Select words:';

  @override
  String get listEmpty => 'This list is empty';

  @override
  String get noCustomLists => 'You don\'t have any lists yet';

  @override
  String wordsCount(String count) {
    return 'Words: $count';
  }

  @override
  String errorLoadingLists(String error) {
    return 'Error loading lists: $error';
  }

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get syncOnStartup => 'Sync on startup';

  @override
  String get deleteList => 'Delete list';

  @override
  String get editList => 'Edit';

  @override
  String get addToAnotherList => 'Add to another list';

  @override
  String get notificationFrequency => 'Notification frequency (minutes)';

  @override
  String get notificationTimeWindow => 'Notification time window';

  @override
  String timeStart(String time) {
    return 'From: $time';
  }

  @override
  String timeEnd(String time) {
    return 'To: $time';
  }

  @override
  String get settingsSoundEffects => 'Sound Effects';

  @override
  String get settingsSoundEffectsDesc =>
      'Sounds for correct and incorrect answers';

  @override
  String get questionTypes => 'Question types';

  @override
  String get questionWordToTranslate => 'Japanese -> English';

  @override
  String get questionTranslateToWord => 'English -> Japanese';

  @override
  String get questionReading => 'Reading';

  @override
  String get freq30m => '30 min';

  @override
  String get freq1h => '1 hour';

  @override
  String get freq1_5h => '1.5 hours';

  @override
  String get freq2h => '2 hours';

  @override
  String get freq3h => '3 hours';

  @override
  String get freq6h => '6 hours';

  @override
  String get freq1d => '1 time a day';
}
