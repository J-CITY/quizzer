import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'database_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final db = DatabaseService();
    await db.init();
    final settings = await db.getSettings();

    if (!settings.notificationsEnabled) return Future.value(true);

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final startParts = settings.notificationTimeStart.split(':');
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);

    final endParts = settings.notificationTimeEnd.split(':');
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    bool isInWindow = false;
    if (startMinutes <= endMinutes) {
      isInWindow = currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      isInWindow = currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }

    if (!isInWindow) return Future.value(true);

    final words = await db.getAllWords();
    final wordsToRepeat = words.where((w) => w.progress < 5).length;

    if (wordsToRepeat > 0) {
      final fln = FlutterLocalNotificationsPlugin();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await fln.initialize(settings: initSettings);

      const androidDetails = AndroidNotificationDetails(
        'quizzer_channel',
        'Quizzer Notifications',
        channelDescription: 'Reminders to repeat words',
        importance: Importance.max,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails);

      await fln.show(
        id: 0,
        title: 'Время тренировки!',
        body: 'У вас $wordsToRepeat слов для повторения.',
        notificationDetails: details,
      );
    }

    return Future.value(true);
  });
}

class NotificationService {
  static Future<void> init() async {
    final fln = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await fln.initialize(settings: initSettings);

    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> updateSchedule(int intervalMinutes) async {
    await Workmanager().cancelByUniqueName('quizzer_notification');
    await Workmanager().registerPeriodicTask(
      'quizzer_notification',
      'check_notifications',
      frequency: Duration(minutes: intervalMinutes < 15 ? 15 : intervalMinutes), // Android min is 15
    );
  }

  static Future<void> cancelSchedule() async {
    await Workmanager().cancelByUniqueName('quizzer_notification');
  }
}
