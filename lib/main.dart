import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'data/services/database_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/google_sheets_service.dart';
import 'data/services/profile_service.dart';
import 'ui/home_screen.dart';
import 'ui/startup_recovery_screen.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final dbService = DatabaseService();
  try {
    await dbService.init();
  } catch (error) {
    debugPrint('Unable to open the local database: $error');
    final hasBackup = await _hasStartupBackup();
    runApp(
      QuizzerApp(
        home: StartupRecoveryScreen(
          hasBackup: hasBackup,
          onRetry: () => _retryStartup(restore: false),
          onRestore: () => _retryStartup(restore: true),
        ),
      ),
    );
    return;
  }
  await _launchApplication(dbService);
}

Future<bool> _hasStartupBackup() async {
  try {
    return await ProfileService.hasAutoBackup();
  } catch (error) {
    debugPrint('Unable to find the local backup: $error');
    return false;
  }
}

Future<void> _retryStartup({required bool restore}) async {
  final dbService = DatabaseService();
  if (restore) {
    await dbService.initFromAutoBackup();
  } else {
    await dbService.init();
  }
  await _launchApplication(dbService);
}

Future<void> _launchApplication(DatabaseService dbService) async {
  unawaited(ProfileService.createAutoBackup(dbService));
  final adsService = AdsService(dbService);
  final iapService = IapService(dbService);
  await _initializeIntegration('ads', adsService.init);
  await _initializeIntegration('purchases', iapService.init);
  await _initializeIntegration('notifications', () async {
    await NotificationService.init();
    final settings = await dbService.getSettings();
    if (settings.notificationsEnabled) {
      await NotificationService.updateSchedule(
        settings.notificationIntervalMinutes,
      );
    }
  });

  unawaited(
    _initializeIntegration('list sync', () => _syncStartupLists(dbService)),
  );

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

Future<void> _initializeIntegration(
  String name,
  Future<void> Function() initialize,
) async {
  try {
    await initialize();
  } catch (error) {
    debugPrint('Unable to initialize $name: $error');
  }
}

Future<void> _syncStartupLists(DatabaseService dbService) async {
  // Background sync for lists
  final lists = await dbService.getCustomLists();
  for (final list in lists) {
    if (list.syncOnStartup &&
        list.googleSheetId != null &&
        list.googleSheetId!.isNotEmpty) {
      GoogleSheetsService.fetchWords(
        list.googleSheetId!,
        sheetName: list.googleSheetTabName,
      ).then((words) => dbService.syncWordsForList(list, words)).catchError((
        _,
      ) {
        /* ignore network errors silently */
      });
    }
  }
}

class QuizzerApp extends StatelessWidget {
  final Widget home;

  const QuizzerApp({super.key, this.home = const HomeScreen()});

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
      home: home,
    );
  }
}
