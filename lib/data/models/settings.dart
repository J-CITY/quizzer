import 'package:isar/isar.dart';

part 'settings.g.dart';

@collection
class Settings {
  Id id = 0; // Singleton pattern (only one settings object)

  int questionsCount = 50;
  int learningQueueSize = 50;

  bool notificationsEnabled = true;
  bool streakNotificationsEnabled = false;

  int notificationIntervalMinutes = 60;

  String notificationTimeStart = '10:00';

  String notificationTimeEnd = '22:00';

  bool autoPlayVoice = false;
  bool playSoundEffects = true;

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

  bool useSimilarWordsForOptions = false;
  bool useSpoiledWordsForOptions = false;

  String? confusableCharactersSheetId;
  List<String> customConfusableGroups = [];
}
