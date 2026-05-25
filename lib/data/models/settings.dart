import 'package:isar/isar.dart';

part 'settings.g.dart';

@collection
class Settings {
  Id id = 0; // Singleton pattern (only one settings object)

  int questionsCount = 50;

  String sheetId = '';

  bool notificationsEnabled = true;

  int notificationIntervalHours = 1;

  bool autoPlayVoice = false;
}
