import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:isar/isar.dart';
import 'package:quizzer/data/models/custom_list.dart';
import 'package:quizzer/data/models/settings.dart';
import 'package:quizzer/data/models/training_session.dart';
import 'package:quizzer/data/models/word.dart';
import 'package:quizzer/data/services/database_service.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:quizzer/l10n/app_localizations_en.dart';
import 'package:quizzer/ui/statistics_screen.dart';
import 'package:quizzer/ui/training_screen.dart';
import 'package:quizzer/ui/widgets/acrylic_card.dart';
import 'package:quizzer/utils/constants.dart';

// Keep widget tests independent of the native Isar binary.
// ignore: subtype_of_sealed_class
class _WordLinks extends Fake implements IsarLinks<Word> {
  final List<Word> items;

  _WordLinks(this.items);

  @override
  Future<void> load({bool overrideChanges = true}) async {}

  @override
  List<Word> toList({bool growable = true}) =>
      List.of(items, growable: growable);
}

class _List extends CustomList {
  final IsarLinks<Word> _links;

  _List(int listId, String label, List<Word> items)
    : _links = _WordLinks(items) {
    id = listId;
    name = label;
  }

  @override
  IsarLinks<Word> get words => _links;
}

class _Database extends Fake implements DatabaseService {
  final List<CustomList> lists;
  final List<TrainingSession> sessions;
  final Settings settings = Settings()
    ..questionVoiceToWord = false
    ..questionVoiceToTranslate = false
    ..questionVoiceToWordInput = false
    ..questionVoiceToWordConstructor = false;

  _Database(this.lists, [this.sessions = const []]);

  @override
  Future<Settings> getSettings() async => settings;

  @override
  Future<List<CustomList>> getCustomLists() async => lists;

  @override
  Future<List<Word>> getAllWords() async => {
    for (final list in lists)
      for (final word in list.words.toList()) word.id: word,
  }.values.toList();

  @override
  Future<List<TrainingSession>> getAllTrainingSessions() async => sessions;
}

class _SilentTts extends Fake implements FlutterTts {
  @override
  Future<dynamic> setLanguage(String language) async {}
}

void main() {
  final l10n = AppLocalizationsEn();

  Future<void> openStatistics(WidgetTester tester, _Database database) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(database),
          ttsProvider.overrideWithValue(_SilentTts()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.darkTheme,
          home: const StatisticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Statistics starts with the earliest due list and shows the rest as queue cards',
    (tester) async {
      final now = DateTime.now();
      Word word(int id, int overdueDays) => Word()
        ..id = id
        ..japanese = 'Term $id'
        ..translation = 'Meaning $id'
        ..progress = 5
        ..nextReviewAt = DateTime.utc(
          now.year,
          now.month,
          now.day - overdueDays,
        );
      final shared = word(2, 0);
      final oldest = _List(1, 'Japanese', [word(1, 2), shared])
        ..useCustomTrainingSettings = true
        ..questionsCount = 2;
      final other = _List(2, 'Vocabulary', [shared, word(3, 0)]);
      final database = _Database(
        [other, oldest],
        [
          TrainingSession()..date = now,
          TrainingSession()..date = DateTime(now.year, now.month, now.day - 1),
        ],
      );
      await openStatistics(tester, database);

      final primary = find.ancestor(
        of: find.text(l10n.readyForPractice),
        matching: find.byType(AcrylicCard),
      );
      final queued = find.ancestor(
        of: find.text(l10n.quickTrainingDue(1)),
        matching: find.byType(AcrylicCard),
      );
      expect(
        find.descendant(of: primary, matching: find.text('Japanese')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: primary,
          matching: find.text(l10n.quickTrainingDue(2)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: queued, matching: find.text('Vocabulary')),
        findsOneWidget,
      );

      final primaryStart = find.descendant(
        of: primary,
        matching: find.text(l10n.start),
      );
      await tester.ensureVisible(primaryStart);
      await tester.tap(primaryStart);
      await tester.pumpAndSettle();
      var route = tester.widget<TrainingScreen>(find.byType(TrainingScreen));
      expect(route.customListId, oldest.id);
      expect(route.reviewWordIds, [1, 2]);
      expect(route.updateReviewSchedule, isTrue);

      Navigator.pop(tester.element(find.byType(TrainingScreen)));
      await tester.pumpAndSettle();
      final queueStart = find.descendant(
        of: queued,
        matching: find.text(l10n.start),
      );
      await tester.ensureVisible(queueStart);
      await tester.tap(queueStart);
      await tester.pumpAndSettle();
      route = tester.widget<TrainingScreen>(find.byType(TrainingScreen));
      expect(route.customListId, other.id);
      expect(route.reviewWordIds, [3]);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Statistics keeps the practice card when there are no words', (
    tester,
  ) async {
    await openStatistics(tester, _Database([]));

    expect(find.text(l10n.readyForPractice), findsOneWidget);
    expect(find.text(l10n.quickTrainingEmpty), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, l10n.start),
    );
    expect(button.onPressed, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
