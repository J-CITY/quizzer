import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:quizzer/utils/constants.dart';
import 'dart:io';
import 'database_service.dart';
import 'word_image_files.dart';
import '../models/custom_list.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:quizzer/l10n/app_localizations.dart';

Future<String?> _notificationImagePath(String source, String fileName) async {
  if (!WordImageFiles.isRemote(source)) {
    return (await WordImageFiles.findLocal(source))?.path;
  }
  final Directory directory = await getApplicationDocumentsDirectory();
  final String filePath = '${directory.path}/$fileName';
  final http.Response response = await http.get(Uri.parse(source));
  if (response.statusCode != HttpStatus.ok) return null;
  final File file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);
  return filePath;
}

void notificationTapForeground(NotificationResponse notificationResponse) async {
  if (notificationResponse.actionId == 'play_word') {
    final payload = notificationResponse.payload;
    if (payload != null) {
      final parts = payload.split('|');
      if (parts.length >= 2) {
        final lang = parts[0];
        final text = parts[1];
        final tts = FlutterTts();
        await tts.setVolume(1.0);
        await tts.setLanguage(lang);
        await tts.speak(text);
      }
    }
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  if (notificationResponse.actionId == 'play_word') {
    final payload = notificationResponse.payload;
    if (payload != null) {
      final parts = payload.split('|');
      if (parts.length >= 2) {
        final lang = parts[0];
        final text = parts[1];
        ui.DartPluginRegistrant.ensureInitialized();
        WidgetsFlutterBinding.ensureInitialized();
        final tts = FlutterTts();
        await tts.setVolume(1.0);
        await tts.setLanguage(lang);
        await tts.speak(text);
        // Keep the background isolate alive long enough for the speech to finish
        await Future.delayed(const Duration(seconds: 3));
      }
    }
  }
}

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
    const androidInit = AndroidInitializationSettings(AppConstants.notificationIcon);
    const windowsInit = WindowsInitializationSettings(
      appName: 'Quizzer',
      appUserModelId: 'com.pets.quizzer',
      guid: '217d842b-6c4c-4286-90f6-281baf1ec202',
    );
    const initSettings = InitializationSettings(android: androidInit, windows: windowsInit);
    await fln.initialize(settings: initSettings);

    final locale = ui.PlatformDispatcher.instance.locale;
    final targetLocale = AppLocalizations.supportedLocales.contains(Locale(locale.languageCode))
        ? Locale(locale.languageCode)
        : const Locale('en');
    final l10n = lookupAppLocalizations(targetLocale);

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
            title: l10n.notificationTrainingTitle,
            body: l10n.notificationTrainingBody(wordsToRepeat.toString()),
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
            title: l10n.notificationStreakTitle,
            body: l10n.notificationStreakBody,
            notificationDetails: detailsStreak,
          );
        }
      }
    }
    
    // Логика случайного слова
    if (task == 'random_word_notification' || task == Workmanager.iOSBackgroundTask) {
      if (settings.randomWordNotificationEnabled) {
        var words = <dynamic>[];
        CustomList? list;
        if (settings.randomWordNotificationListId != null) {
          list = await db.isar.customLists.get(settings.randomWordNotificationListId!);
          if (list != null) {
            await list.words.load();
            words = list.words.toList();
          }
        } else {
          words = await db.getAllWords();
        }

        if (words.isNotEmpty) {
          words.shuffle();
          final word = words.first;
          
          final title = word.reading != null && word.reading!.isNotEmpty 
              ? '${word.japanese} (${word.reading})' 
              : word.japanese;

          StyleInformation? styleInformation = const BigTextStyleInformation('');
          if (word.imageUrl != null && word.imageUrl!.isNotEmpty) {
            try {
              final largeIconPath = await _notificationImagePath(
                  word.imageUrl!, 'largeIcon_${word.id}');
              if (largeIconPath != null) {
                styleInformation = BigPictureStyleInformation(
                  FilePathAndroidBitmap(largeIconPath),
                  hideExpandedLargeIcon: true,
                );
              }
            } catch (e) {
              // Ignore download errors
            }
          }

          final listLanguage = list?.language ?? 'ja-JP';
          final payload = '$listLanguage|${word.japanese}';

          final androidDetailsRandom = AndroidNotificationDetails(
            'quizzer_random_word_channel',
            'Random Word Notifications',
            channelDescription: 'Shows a random word periodically',
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: styleInformation,
            autoCancel: false,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'play_word',
                l10n.playWord,
                showsUserInterface: false,
                cancelNotification: false,
              ),
            ],
          );
          final detailsRandom = NotificationDetails(android: androidDetailsRandom);

          await fln.show(
            id: 2,
            title: title,
            body: word.translation,
            notificationDetails: detailsRandom,
            payload: payload,
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
    const androidInit = AndroidInitializationSettings(AppConstants.notificationIcon);
    const windowsInit = WindowsInitializationSettings(
      appName: 'Quizzer',
      appUserModelId: 'com.pets.quizzer',
      guid: '217d842b-6c4c-4286-90f6-281baf1ec202',
    );
    const initSettings = InitializationSettings(android: androidInit, windows: windowsInit);
    await fln.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: notificationTapForeground,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isAndroid || Platform.isIOS) {
      await Workmanager().initialize(callbackDispatcher);
    }
  }

  static Future<void> testNotification(String type, DatabaseService db) async {
    final settings = await db.getSettings();
    final fln = FlutterLocalNotificationsPlugin();

    final locale = ui.PlatformDispatcher.instance.locale;
    final targetLocale = AppLocalizations.supportedLocales.contains(Locale(locale.languageCode))
        ? Locale(locale.languageCode)
        : const Locale('en');
    final l10n = lookupAppLocalizations(targetLocale);

    if (type == 'training') {
      final words = await db.getAllWords();
      final wordsToRepeat = words.where((w) => w.progress < 5).length;
      if (wordsToRepeat > 0) {
        const androidDetails = AndroidNotificationDetails('quizzer_channel', 'Quizzer Notifications', channelDescription: 'Reminders to repeat words', importance: Importance.max, priority: Priority.high);
        await fln.show(
          id: 0,
          title: l10n.notificationTrainingTitle,
          body: l10n.notificationTrainingBody(wordsToRepeat.toString()),
          notificationDetails: const NotificationDetails(android: androidDetails),
        );
      }
    } else if (type == 'streak') {
      const androidDetailsStreak = AndroidNotificationDetails('quizzer_streak_channel', 'Quizzer Streak', channelDescription: 'Reminders to keep your streak', importance: Importance.max, priority: Priority.high);
      await fln.show(
        id: 1,
        title: l10n.notificationStreakTitle,
        body: l10n.notificationStreakBody,
        notificationDetails: const NotificationDetails(android: androidDetailsStreak),
      );
    } else if (type == 'random') {
      var words = <dynamic>[];
      CustomList? list;
      if (settings.randomWordNotificationListId != null) {
        list = await db.isar.customLists.get(settings.randomWordNotificationListId!);
        if (list != null) {
          await list.words.load();
          words = list.words.toList();
        }
      } else {
        words = await db.getAllWords();
      }
      if (words.isNotEmpty) {
        words.shuffle();
        final word = words.first;
        final title = word.reading != null && word.reading!.isNotEmpty ? '${word.japanese} (${word.reading})' : word.japanese;
        StyleInformation? styleInformation = const BigTextStyleInformation('');
        if (word.imageUrl != null && word.imageUrl!.isNotEmpty) {
          try {
            final largeIconPath = await _notificationImagePath(word.imageUrl!, 'largeIcon_${word.id}');
            if (largeIconPath != null) {
              styleInformation = BigPictureStyleInformation(FilePathAndroidBitmap(largeIconPath), hideExpandedLargeIcon: true);
            }
          } catch (e) {}
        }
        final listLanguage = list?.language ?? 'ja-JP';
        final payload = '$listLanguage|${word.japanese}';
        final androidDetailsRandom = AndroidNotificationDetails(
          'quizzer_random_word_channel',
          'Random Word Notifications',
          channelDescription: 'Shows a random word periodically',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: styleInformation,
          autoCancel: false,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'play_word',
              l10n.playWord,
              showsUserInterface: false,
              cancelNotification: false,
            )
          ],
        );
        await fln.show(
          id: 2,
          title: title,
          body: word.translation,
          notificationDetails: NotificationDetails(android: androidDetailsRandom),
          payload: payload,
        );
      }
    }
  }

  static Future<void> updateSchedule(int intervalMinutes) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    
    await Workmanager().cancelByUniqueName('quizzer_notification');
    await Workmanager().registerPeriodicTask(
      'quizzer_notification',
      'check_notifications',
      frequency: Duration(minutes: intervalMinutes < 15 ? 15 : intervalMinutes), // Android min is 15
    );
  }

  static Future<void> cancelSchedule() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    
    await Workmanager().cancelByUniqueName('quizzer_notification');
  }

  static Future<void> updateRandomWordSchedule(int intervalMinutes) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    
    await Workmanager().cancelByUniqueName('random_word_notification');
    await Workmanager().registerPeriodicTask(
      'random_word_notification',
      'random_word_notification',
      frequency: Duration(minutes: intervalMinutes < 15 ? 15 : intervalMinutes),
    );
  }

  static Future<void> cancelRandomWordSchedule() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    
    await Workmanager().cancelByUniqueName('random_word_notification');
  }

  static Future<void> requestPermissions() async {
    final fln = FlutterLocalNotificationsPlugin();
    await fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
}
