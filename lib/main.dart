import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'data/services/database_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/google_sheets_service.dart';
import 'ui/home_screen.dart';
import 'package:quizzer/utils/constants.dart';
import 'package:quizzer/services/ads_service.dart';
import 'package:quizzer/services/iap_service.dart';

// Create providers for new services
final adsServiceProvider = Provider<AdsService>((ref) {
  return AdsService(ref.read(databaseServiceProvider));
});

final iapServiceProvider = ChangeNotifierProvider<IapService>((ref) {
  return IapService(ref.read(databaseServiceProvider));
});


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final dbService = DatabaseService();
  await dbService.init();

  // Initialize Ads
  final adsService = AdsService(dbService);
  await adsService.init();

  // Initialize IAP
  final iapService = IapService(dbService);
  await iapService.init();

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
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
        adsServiceProvider.overrideWithValue(adsService),
        iapServiceProvider.overrideWith((ref) => iapService),
      ],
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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
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
