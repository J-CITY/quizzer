import 'package:isar/isar.dart';

part 'settings.g.dart';

@collection
class Settings {
  Id id = 0; // Singleton pattern (only one settings object)

  int questionsCount = 50;

  bool notificationsEnabled = true;

  int notificationIntervalMinutes = 60;

  String notificationTimeStart = '10:00';

  String notificationTimeEnd = '22:00';

  bool autoPlayVoice = false;
  bool playSoundEffects = true;

  bool questionWordToTranslate = true;
  bool questionTranslateToWord = true;
  bool questionReading = true;

  bool isMigratedV2 = false;
}
