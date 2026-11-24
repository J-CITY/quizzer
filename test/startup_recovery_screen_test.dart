import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:quizzer/l10n/app_localizations_en.dart';
import 'package:quizzer/ui/startup_recovery_screen.dart';

void main() {
  final l10n = AppLocalizationsEn();

  Future<void> showScreen(
    WidgetTester tester, {
    required bool hasBackup,
    required Future<void> Function() onRetry,
    required Future<void> Function() onRestore,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StartupRecoveryScreen(
          hasBackup: hasBackup,
          onRetry: onRetry,
          onRestore: onRestore,
        ),
      ),
    );
  }

  testWidgets('Recovery calls restore only after an explicit choice', (
    tester,
  ) async {
    final restoration = Completer<void>();
    var restoreCount = 0;
    await showScreen(
      tester,
      hasBackup: true,
      onRetry: () async {},
      onRestore: () {
        restoreCount++;
        return restoration.future;
      },
    );

    expect(restoreCount, 0);
    await tester.tap(find.text(l10n.startupDatabaseRestore));
    await tester.pump();
    expect(restoreCount, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    restoration.completeError(const FormatException('Malformed backup'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.startupDatabaseRestoreError), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('Recovery offers retry when the backup is missing', (
    tester,
  ) async {
    var retryCount = 0;
    await showScreen(
      tester,
      hasBackup: false,
      onRetry: () async {
        retryCount++;
        throw StateError('Database is locked');
      },
      onRestore: () async => fail('Must not offer restore without a backup'),
    );

    expect(find.text(l10n.startupDatabaseRestore), findsNothing);
    await tester.tap(find.text(l10n.startupDatabaseRetry));
    await tester.pumpAndSettle();
    expect(retryCount, 1);
    expect(find.text(l10n.startupDatabaseRetryError), findsOneWidget);
  });
}
