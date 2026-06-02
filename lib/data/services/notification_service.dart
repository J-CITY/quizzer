import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'database_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final db = DatabaseService();
    await db.init();
    final settings = await db.getSettings();

    if (!settings.notificationsEnabled && !settings.streakNotificationsEnabled) {
      return Future.value(true);
    }

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final fln = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await fln.initialize(settings: initSettings);

    // Логика обычных уведомлений
    if (settings.notificationsEnabled) {
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

      if (isInWindow) {
        final words = await db.getAllWords();
        final wordsToRepeat = words.where((w) => w.progress < 5).length;

        if (wordsToRepeat > 0) {
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
      }
    }

    // Логика уведомлений о стрике
    if (settings.streakNotificationsEnabled) {
      // Показывать между 21:00 и 21:59
      if (now.hour == 21) {
        final sessions = await db.getAllTrainingSessions();
        final uniqueDays = sessions.map((s) => s.date).toSet().toList();
        uniqueDays.sort((a, b) => b.compareTo(a));

        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        bool trainedToday = uniqueDays.isNotEmpty && uniqueDays.first == today;
        bool trainedYesterday = uniqueDays.contains(yesterday);

        // Если вчера тренировались, а сегодня еще нет - стрик под угрозой
        if (!trainedToday && trainedYesterday) {
          const androidDetailsStreak = AndroidNotificationDetails(
            'quizzer_streak_channel',
            'Quizzer Streak',
            channelDescription: 'Reminders to keep your streak',
            importance: Importance.max,
            priority: Priority.high,
          );
          const detailsStreak = NotificationDetails(android: androidDetailsStreak);

          await fln.show(
            id: 1,
            title: '🔥 Ваш стрик может сгореть!',
            body: 'Вы еще не тренировались сегодня. Зайдите в приложение, чтобы не потерять прогресс!',
            notificationDetails: detailsStreak,
          );
        }
      }
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

  static Future<void> requestPermissions() async {
    final fln = FlutterLocalNotificationsPlugin();
    await fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
}
