import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:isar/isar.dart';
import 'package:quizzer/data/models/custom_list.dart';
import 'package:quizzer/data/models/rush_session.dart';
import 'package:quizzer/data/models/settings.dart';
import 'package:quizzer/data/models/word.dart';
import 'package:quizzer/data/models/word_progress_change.dart';
import 'package:quizzer/data/services/database_service.dart';
import 'package:quizzer/domain/training_engine.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:quizzer/l10n/app_localizations_en.dart';
import 'package:quizzer/ui/training_result_screen.dart';
import 'package:quizzer/ui/training_screen.dart';
import 'package:quizzer/utils/constants.dart';

// Widget tests supply loaded links without requiring the native Isar library.
// ignore: subtype_of_sealed_class
class _WordLinks extends Fake implements IsarLinks<Word> {
  final List<Word> words;
  _WordLinks(this.words);

  @override
  Future<void> load({bool overrideChanges = true}) async {}

  @override
  List<Word> toList({bool growable = true}) =>
      List.of(words, growable: growable);
}

class _List extends CustomList {
  final IsarLinks<Word> _words;

  @override
  IsarLinks<Word> get words => _words;

  _List(List<Word> items) : _words = _WordLinks(items) {
    id = 1;
    name = 'Vocabulary';
  }
}

class _SilentTts extends Fake implements FlutterTts {
  @override
  Future<dynamic> setLanguage(String language) async {}
}

class _Database extends Fake implements DatabaseService {
  final settings = Settings()
    ..playSoundEffects = false
    ..hapticFeedbackEnabled = false
    ..autoAdvanceToNextQuestion = false
    ..questionTranslateToWord = false
    ..questionWordToReading = false
    ..questionReadingToWord = false
    ..questionVoiceToTranslate = false
    ..questionVoiceToWord = false
    ..questionVoiceToWordInput = false
    ..questionVoiceToWordConstructor = false
    ..questionTranslateToWordInput = false
    ..questionTranslateToWordConstructor = false
    ..questionImageToWord = false;

  final words = List.generate(
    3,
    (index) => Word()
      ..id = index + 1
      ..japanese = 'Term $index'
      ..translation = 'Meaning $index'
      ..mnemonic = 'A mental image for term $index'
      ..progress = index,
  );
  RushSession? savedRun;
  final savedReviewSets = <Set<int>>[];

  @override
  Future<Settings> getSettings() async => settings;

  @override
  Future<List<CustomList>> getCustomLists() async => [_List(words)];

  @override
  Future<List<Word>> getAllWords() async => words;

  @override
  Future<void> saveRushSession(RushSession session) async {
    expect(savedRun, isNull);
    savedRun = session;
  }

  @override
  Future<int> saveTrainingSession(
    int? customListId, {
    List<WordProgressChange> progressChanges = const [],
    Set<int> independentlyRecalledReviewIds = const {},
  }) async {
    savedReviewSets.add(independentlyRecalledReviewIds);
    return independentlyRecalledReviewIds.length;
  }
}

void main() {
  final l10n = AppLocalizationsEn();

  Future<void> openScreen(
    WidgetTester tester,
    _Database db,
    Widget screen, {
    Size viewport = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(db),
          ttsProvider.overrideWithValue(_SilentTts()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> answerIncorrectly(WidgetTester tester) async {
    final incorrectIndex = find.text('Term 0').evaluate().isEmpty ? 0 : 1;
    await tester.tap(find.text('Meaning $incorrectIndex'));
    await tester.pumpAndSettle();
  }

  testWidgets('Rush stops at the error limit and saves only the Rush result', (
    tester,
  ) async {
    final db = _Database();
    await openScreen(
      tester,
      db,
      const TrainingScreen(customListId: 1, rushErrorLimit: 1),
    );
    expect(find.byTooltip(l10n.trainingHint), findsNothing);

    await answerIncorrectly(tester);
    expect(find.text(l10n.rushResultErrorsWithLimit(1, 1)), findsOneWidget);
    await tester.tap(find.text(l10n.rushResultShow));
    await tester.pumpAndSettle();

    expect(find.text(l10n.rushResultLimitReached), findsOneWidget);
    expect(db.savedRun?.answeredQuestions, 1);
    expect(db.savedRun?.totalWords, 3);
    expect(db.savedRun?.correctAnswers, 0);
    expect(db.words.map((word) => word.progress), [0, 1, 2]);
  });

  testWidgets(
    'Uncapped Rush continues after mistakes and finishes at list end',
    (tester) async {
      final db = _Database();
      await openScreen(
        tester,
        db,
        const TrainingScreen(customListId: 1, rushErrorLimit: 0),
      );
      for (var index = 0; index < db.words.length; index++) {
        await answerIncorrectly(tester);
        expect(db.savedRun, isNull);
        await tester.tap(
          find.text(
            index + 1 == db.words.length ? l10n.rushResultShow : l10n.forward,
          ),
        );
        await tester.pumpAndSettle();
      }

      expect(find.text(l10n.rushResultListCompleted), findsOneWidget);
      expect(db.savedRun?.answeredQuestions, 3);
      expect(db.savedRun?.correctAnswers, 0);
      expect(db.savedRun?.errorLimit, 0);
    },
  );

  testWidgets('Rush fits a compact screen with enlarged system text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openScreen(
      tester,
      _Database(),
      const TrainingScreen(customListId: 1, rushErrorLimit: 3),
      viewport: const Size(320, 640),
    );
    expect(find.text(l10n.rushResultErrorsWithLimit(0, 3)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Skill results fit a compact screen with enlarged system text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = _Database();
    await openScreen(
      tester,
      db,
      TrainingResultScreen(
        mistakes: [db.words.first],
        skills: summarizePracticeSkills({
          1: [
            (
              questionType: QuestionType.japToTrans,
              answer: PracticeAnswer.independent,
            ),
            (
              questionType: QuestionType.voiceToTrans,
              answer: PracticeAnswer.assisted,
            ),
            (
              questionType: QuestionType.transToJapInput,
              answer: PracticeAnswer.incorrect,
            ),
          ],
        }),
      ),
      viewport: const Size(320, 640),
    );

    expect(find.text(l10n.trainingSkillsTitle), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(l10n.trainingPracticeWriting),
      120,
    );
    expect(find.text(l10n.trainingPracticeWriting), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Only unaided recall moves a scheduled review forward', (
    tester,
  ) async {
    final db = _Database();
    for (final word in db.words.take(2)) {
      word.progress = 5;
      word.nextReviewAt = DateTime.utc(2020);
    }
    await openScreen(
      tester,
      db,
      const TrainingScreen(
        customListId: 1,
        isReviewMode: true,
        reviewWordIds: [1, 2],
      ),
    );

    await tester.tap(find.byTooltip(l10n.trainingHint));
    await tester.pumpAndSettle();
    expect(find.text(l10n.trainingHintReviewEffect), findsOneWidget);
    await tester.tap(find.text(l10n.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meaning 0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.forward));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meaning 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.forward));
    await tester.pumpAndSettle();

    expect(db.savedReviewSets, [
      {2},
    ]);
    expect(
      find.text(l10n.trainingReviewSchedulesAdvanced(1, 2)),
      findsOneWidget,
    );
    expect(find.text(l10n.trainingReviewStillDue), findsOneWidget);
    expect(find.text(l10n.trainingSkillIndependent(1, 2)), findsOneWidget);
    expect(find.text(l10n.trainingSkillAssisted(1)), findsOneWidget);
    await tester.tap(find.text(l10n.trainingPracticeTranslation));
    await tester.pumpAndSettle();
    expect(
      find.text(
        l10n.trainingModeWithProgress(l10n.trainingSkillTranslation, '1 / 1'),
      ),
      findsOneWidget,
    );
    expect(find.text('Term 0'), findsOneWidget);
    await tester.tap(find.text('Meaning 0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.forward));
    await tester.pumpAndSettle();
    expect(db.savedReviewSets, [
      {2},
      <int>{},
    ]);
  });

  testWidgets('Practicing missed words leaves a due review on its schedule', (
    tester,
  ) async {
    final db = _Database();
    db.words.first
      ..progress = 5
      ..nextReviewAt = DateTime.utc(2020);
    await openScreen(
      tester,
      db,
      const TrainingScreen(
        customListId: 1,
        isReviewMode: true,
        reviewWordIds: [1],
      ),
    );
    await answerIncorrectly(tester);
    await tester.tap(find.text(l10n.forward));
    await tester.pumpAndSettle();
    expect(db.savedReviewSets, [<int>{}]);

    await tester.tap(find.text(l10n.trainingPracticeMistakes));
    await tester.pumpAndSettle();
    expect(
      find.text(
        l10n.trainingModeWithProgress(l10n.trainingMistakesMode, '1 / 1'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Meaning 0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.forward));
    await tester.pumpAndSettle();
    expect(db.savedReviewSets, [<int>{}, <int>{}]);
    expect(find.text(l10n.trainingFreeReview), findsOneWidget);
  });

  testWidgets(
    'An unavailable image prompt is replaced without recording an error',
    (tester) async {
      final db = _Database();
      db.settings
        ..questionWordToTranslate = false
        ..questionImageToWord = true;
      db.words.first.imageUrl = 'missing:gallery-image';
      await openScreen(
        tester,
        db,
        const TrainingScreen(
          customListId: 1,
          isReviewMode: true,
          reviewWordIds: [1],
        ),
      );

      expect(find.text(l10n.trainingImageQuestionReplaced), findsOneWidget);
      expect(find.text('Meaning 0'), findsOneWidget);
      await tester.tap(find.text('Meaning 0'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.forward));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(l10n.trainingNoMistakes), 120);
      expect(find.text(l10n.trainingNoMistakes), findsOneWidget);
    },
  );

  for (final isReview in [false, true]) {
    testWidgets(
      'Study and review respect independent hint settings (review: $isReview)',
      (tester) async {
        final db = _Database()..settings.learningHintsDisabled = true;
        await openScreen(tester, db, TrainingScreen(isReviewMode: isReview));

        final hint = find.byTooltip(l10n.trainingHint);
        if (isReview) {
          await tester.tap(hint);
          await tester.pumpAndSettle();
          expect(
            find.textContaining('A mental image for term'),
            findsOneWidget,
          );
        } else {
          expect(hint, findsNothing);
        }
      },
    );
  }
}
