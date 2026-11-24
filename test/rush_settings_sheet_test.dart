import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:quizzer/ui/widgets/rush_settings_sheet.dart';

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required int? initialLimit,
    int? globalLimit,
    required ValueChanged<({int errorLimit, int? override})?> onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                onResult(
                  await showRushSettingsSheet(
                    context,
                    initialErrorLimit: initialLimit,
                    globalErrorLimit: globalLimit,
                  ),
                );
              },
              child: const Text('Open Rush setup'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Rush setup'));
    await tester.pumpAndSettle();
  }

  testWidgets('Following the global limit clears the list override', (
    tester,
  ) async {
    ({int errorLimit, int? override})? configuration;
    await openSheet(
      tester,
      initialLimit: 2,
      globalLimit: 3,
      onResult: (value) => configuration = value,
    );

    await tester.tap(find.text('Use the default limit'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('3 mistakes'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pumpAndSettle();

    expect(configuration, (errorLimit: 3, override: null));
  });

  testWidgets('Playing the entire list saves a distinct override', (
    tester,
  ) async {
    ({int errorLimit, int? override})? configuration;
    await openSheet(
      tester,
      initialLimit: null,
      globalLimit: 3,
      onResult: (value) => configuration = value,
    );

    await tester.tap(find.text('Use the default limit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play through the entire list'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pumpAndSettle();

    expect(configuration, (errorLimit: 0, override: 0));
  });

  testWidgets('An invalid limit cannot be saved', (tester) async {
    var responseReceived = false;
    await openSheet(
      tester,
      initialLimit: 3,
      onResult: (_) => responseReceived = true,
    );

    await tester.enterText(find.byType(TextFormField), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(responseReceived, isFalse);
    expect(find.text('Enter a number from 1 to 99.'), findsOneWidget);
  });
}
