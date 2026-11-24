import 'package:isar/isar.dart';

import 'rush_session.dart';

part 'settings.g.dart';

@collection
class Settings {
  Id id = 0; // Singleton pattern (only one settings object)

  int questionsCount = 50;
  int learningQueueSize = 50;
  int targetWordRepetitions = 3;

  bool notificationsEnabled = true;
  bool streakNotificationsEnabled = false;

  int notificationIntervalMinutes = 60;

  String notificationTimeStart = '10:00';

  String notificationTimeEnd = '22:00';

  bool autoPlayVoice = false;
  bool playSoundEffects = true;
  bool hapticFeedbackEnabled = true;

  bool questionWordToTranslate = true;
  bool questionTranslateToWord = true;

  bool questionWordToReading = true;
  bool questionReadingToWord = true;

  bool questionVoiceToTranslate = true;
  bool questionVoiceToWord = true;
  bool questionVoiceToWordInput = true;
  bool questionVoiceToWordConstructor = true;
  bool questionTranslateToWordInput = true;
  bool questionTranslateToWordConstructor = true;
  bool questionImageToWord = true;

  bool autoAdvanceToNextQuestion = true;

  bool learningHintsDisabled = false;
  bool reviewHintsDisabled = false;
  int? defaultRushErrorLimit;

  @ignore
  int get rushErrorLimit =>
      RushSession.parseErrorLimit(defaultRushErrorLimit) ??
      RushSession.defaultErrorLimit;

  bool useSimilarWordsForOptions = false;
  bool useSpoiledWordsForOptions = false;

  String? confusableCharactersSheetId;
  List<String> customConfusableGroups = [];
  List<String> customLanguages = [];

  String? pixabayApiKey;

  bool isAdFree = false;

  String searchSourceLanguage = 'en-US';
  String searchTargetLanguage = 'ja-JP';

  bool hasSeenTutorial = false;

  bool flashcardShowWord = true;
  bool flashcardShowReading = true;
  bool flashcardShowTranslation = true;
  bool flashcardShowImage = true;

  bool randomWordNotificationEnabled = false;
  int randomWordNotificationIntervalMinutes = 60;
  int? randomWordNotificationListId;

  bool flashcardShuffleCards = false;
}
