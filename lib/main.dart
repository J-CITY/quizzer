import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'data/services/database_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/google_sheets_service.dart';
import 'ui/home_screen.dart';
import 'package:quizzer/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DatabaseService();
  await dbService.init();

  await NotificationService.init();
  final settings = await dbService.getSettings();
  if (settings.notificationsEnabled) {
    await NotificationService.updateSchedule(
      settings.notificationIntervalMinutes,
    );
  }

  // Background sync for lists
  final lists = await dbService.getCustomLists();
  for (final list in lists) {
    if (list.syncOnStartup &&
        list.googleSheetId != null &&
        list.googleSheetId!.isNotEmpty) {
      GoogleSheetsService.fetchWords(list.googleSheetId!)
          .then((words) {
            dbService.syncWordsForList(list, words);
          })
          .catchError((_) {
            /* ignore network errors silently */
          });
    }
  }

  runApp(
    ProviderScope(
      overrides: [databaseServiceProvider.overrideWithValue(dbService)],
      child: const QuizzerApp(),
    ),
  );
}

class QuizzerApp extends StatelessWidget {
  const QuizzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quizzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: ColorConstants.seedColorLight,
          brightness: Brightness.light,
        ),
        fontFamilyFallback: const ['Yu Gothic', 'Meiryo', 'Noto Sans JP'],
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: ColorConstants.seedColorDark,
          brightness: Brightness.dark,
        ),
        fontFamilyFallback: const ['Yu Gothic', 'Meiryo', 'Noto Sans JP'],
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru', ''), Locale('en', '')],
      home: const HomeScreen(),
    );
  }
}
