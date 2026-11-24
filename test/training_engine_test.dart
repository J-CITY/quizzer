import 'package:flutter_test/flutter_test.dart';
import 'package:quizzer/domain/training_engine.dart';
import 'package:quizzer/data/models/word.dart';
import 'package:quizzer/data/models/settings.dart';
import 'package:quizzer/l10n/app_localizations_en.dart';

void main() {
  late TrainingEngine engine;
  late AppLocalizationsEn l10n;

  setUp(() {
    engine = TrainingEngine();
    l10n = AppLocalizationsEn();
  });

  List<Word> createMockWords(int count) {
    return List.generate(count, (index) {
      final word = Word();
      word.id = index + 1;
      word.japanese = 'Word $index';
      word.reading = 'Reading $index';
      word.translation = 'Translation $index';
      word.progress = 0;
      return word;
    });
  }

  Settings createDefaultSettings({int questionsCount = 15}) {
    final settings = Settings();
    settings.questionsCount = questionsCount;
    // Включаем все типы вопросов
    settings.questionWordToTranslate = true;
    settings.questionTranslateToWord = true;
    settings.questionWordToReading = true;
    settings.questionReadingToWord = true;
    settings.questionVoiceToTranslate = true;
    settings.questionVoiceToWord = true;
    settings.questionVoiceToWordInput = true;
    settings.questionVoiceToWordConstructor = true;
    settings.questionTranslateToWordInput = true;
    settings.questionTranslateToWordConstructor = true;
    settings.questionImageToWord =
        false; // Для картинок нужен imageUrl, оставим false
    return settings;
  }

  group('TrainingEngine - 3x Word Questions Feature', () {
    test(
      'Learn Mode: Generates exactly count questions if there are enough words',
      () {
        final sourceWords = createMockWords(10);
        final settings = createDefaultSettings(questionsCount: 15);

        final session = engine.generateSession(
          sourceWords,
          sourceWords,
          settings,
          l10n,
          isReviewMode: false,
        );

        expect(session.length, equals(15));
      },
    );

    test(
      'Learn Mode: Each word appears exactly 3 times with different question types',
      () {
        final sourceWords = createMockWords(10);
        final settings = createDefaultSettings(questionsCount: 15);

        final session = engine.generateSession(
          sourceWords,
          sourceWords,
          settings,
          l10n,
          isReviewMode: false,
        );

        // Группируем вопросы по словам
        final Map<String, List<Question>> questionsByWord = {};
        for (var q in session) {
          questionsByWord.putIfAbsent(q.word.japanese, () => []).add(q);
        }

        // Должно быть выбрано 5 уникальных слов (15 / 3)
        expect(questionsByWord.keys.length, equals(5));

        for (var entry in questionsByWord.entries) {
          final wordQuestions = entry.value;
          expect(wordQuestions.length, equals(3));

          // Типы вопросов должны отличаться
          final types = wordQuestions.map((q) => q.type).toSet();
          expect(
            types.length,
            equals(3),
            reason:
                'Questions for word "${entry.key}" should have unique types',
          );
        }
      },
    );

    test('Review prioritizes due words and asks each word once', () {
      final words = createMockWords(5);
      final now = DateTime(2026, 11, 21, 10);
      for (final word in words.take(4)) {
        word.progress = 5;
      }
      words[0].nextReviewAt = DateTime.utc(2026, 11, 21);
      words[1].nextReviewAt = DateTime.utc(2026, 11, 19);
      words[2].nextReviewAt = DateTime.utc(2026, 11, 22);
      final settings = createDefaultSettings(questionsCount: 2);

      final session = engine.generateSession(
        words,
        words,
        settings,
        l10n,
        isReviewMode: true,
        now: now,
      );

      // Overdue legacy words missing a date come first.
      expect(session.map((question) => question.word.id), [4, 2]);
    });

    test('Review honors the order of an explicit list and deduplicates it', () {
      final words = createMockWords(5);
      final session = engine.generateSession(
        words,
        words,
        createDefaultSettings(questionsCount: 2),
        l10n,
        isReviewMode: true,
        reviewWordIds: [5, 5, 3, 2],
      );
      expect(session.map((question) => question.word.id), [5, 3]);
    });

    test('Free review gives each word one question when nothing is due', () {
      final words = createMockWords(3);
      final session = engine.generateSession(
        words,
        words,
        createDefaultSettings(),
        l10n,
        isReviewMode: true,
      );

      expect(
        session.map((question) => question.word.id),
        unorderedEquals([1, 2, 3]),
      );
    });

    test('Boundary Case: Fewer words than required for a full session', () {
      final sourceWords = createMockWords(2); // Только 2 слова
      final settings = createDefaultSettings(questionsCount: 15);

      final session = engine.generateSession(
        sourceWords,
        sourceWords,
        settings,
        l10n,
        isReviewMode: false,
      );

      // Ожидаем 2 слова * 3 повторения = 6 вопросов
      expect(session.length, equals(6));

      final Map<String, List<Question>> questionsByWord = {};
      for (var q in session) {
        questionsByWord.putIfAbsent(q.word.japanese, () => []).add(q);
      }

      expect(questionsByWord.keys.length, equals(2));
      for (var entry in questionsByWord.entries) {
        expect(entry.value.length, equals(3));
        final types = entry.value.map((q) => q.type).toSet();
        expect(types.length, equals(3));
      }
    });

    test('Boundary Case: Total count not divisible by 3 (e.g. 10)', () {
      final sourceWords = createMockWords(10);
      final settings = createDefaultSettings(questionsCount: 10);

      final session = engine.generateSession(
        sourceWords,
        sourceWords,
        settings,
        l10n,
        isReviewMode: false,
      );

      // Ожидаем ровно 10 вопросов
      expect(session.length, equals(10));

      final Map<String, List<Question>> questionsByWord = {};
      for (var q in session) {
        questionsByWord.putIfAbsent(q.word.japanese, () => []).add(q);
      }

      // Должно быть выбрано ceil(10/3) = 4 уникальных слова
      expect(questionsByWord.keys.length, equals(4));

      final counts =
          questionsByWord.values.map((questions) => questions.length).toList()
            ..sort();
      expect(counts, [2, 2, 3, 3]);
    });
  });

  group('Rush', () {
    test(
      'uses every word once regardless of study level or question count',
      () {
        final words = createMockWords(8);
        words.first.progress = 5;
        final settings = createDefaultSettings(questionsCount: 2);
        final session = engine
            .generateRushSession(words, settings, l10n)
            .toList();

        expect(
          session.map((question) => question.word.id),
          unorderedEquals(words.map((word) => word.id)),
        );
        expect(
          session.every(
            (question) =>
                !question.isVoice && question.type != QuestionType.imageToJap,
          ),
          isTrue,
        );
      },
    );

    test('switches to a playable constructor for a one-word list', () {
      final words = createMockWords(1);
      final settings = createDefaultSettings()
        ..questionReadingToWord = false
        ..questionWordToReading = false
        ..questionTranslateToWordInput = false
        ..questionTranslateToWordConstructor = false;
      final question = engine.generateRushSession(words, settings, l10n).single;

      expect(question.isConstructor, isTrue);
      expect(question.options.join().length, question.correctAnswer.length);
    });
  });

  group('Skill breakdown', () {
    test('reports first answers by skill and deduplicates practice words', () {
      final skills = summarizePracticeSkills(const {
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
            questionType: QuestionType.voiceToJapInput,
            answer: PracticeAnswer.incorrect,
          ),
          (
            questionType: QuestionType.transToJapConstructor,
            answer: PracticeAnswer.incorrect,
          ),
        ],
        2: [
          (
            questionType: QuestionType.transToJapInput,
            answer: PracticeAnswer.independent,
          ),
        ],
      });
      expect(skills[PracticeSkill.translation]?.independent, 1);
      expect(skills[PracticeSkill.translation]?.practiceWordIds, isEmpty);
      expect(skills[PracticeSkill.listening]?.assisted, 1);
      expect(skills[PracticeSkill.listening]?.practiceWordIds, [1]);
      expect(skills[PracticeSkill.writing]?.incorrect, 2);
      expect(skills[PracticeSkill.writing]?.total, 3);
      expect(skills[PracticeSkill.writing]?.practiceWordIds, [1]);
      expect(summarizePracticeSkills({})[PracticeSkill.listening]?.total, 0);
    });

    test('focused practice asks for the selected skill and words', () {
      final words = createMockWords(3);
      final settings = createDefaultSettings()
        ..questionVoiceToWordInput = false
        ..questionVoiceToWordConstructor = false
        ..questionTranslateToWordInput = false
        ..questionTranslateToWordConstructor = false;
      final session = engine.generateSession(
        words,
        words,
        settings,
        l10n,
        isReviewMode: true,
        reviewWordIds: [3, 1],
        reviewSkill: PracticeSkill.writing,
      );
      expect(session.map((question) => question.word.id), [3, 1]);
      expect(session.every((question) => question.isConstructor), isTrue);
    });
  });

  group('Hints and learning progress', () {
    test('prefers a custom mnemonic over generated clues', () {
      final word = createMockWords(1).single..mnemonic = 'A shared image';
      final question = Question(
        word: word,
        prompt: word.translation,
        correctAnswer: word.japanese,
        options: const [],
        type: QuestionType.transToJapInput,
      );
      expect(question.hint, (
        kind: QuestionHintKind.mnemonic,
        value: 'A shared image',
      ));
    });

    test('does not reveal the whole answer or the last incorrect option', () {
      final word = createMockWords(1).single..japanese = '猫';
      final text = Question(
        word: word,
        prompt: word.translation,
        correctAnswer: word.japanese,
        options: const [],
        type: QuestionType.transToJapInput,
      );
      final choice = Question(
        word: word,
        prompt: word.translation,
        correctAnswer: word.japanese,
        options: const ['犬', '猫'],
        type: QuestionType.transToJap,
      );
      expect(text.hint, isNull);
      expect(choice.hint, isNull);
    });

    test('only eliminates an incorrect choice when more remain', () {
      final word = createMockWords(1).single..japanese = '猫';
      final choice = Question(
        word: word,
        prompt: word.translation,
        correctAnswer: word.japanese,
        options: const ['犬', '猫', '獅子'],
        type: QuestionType.transToJap,
      );
      expect(choice.hint, (kind: QuestionHintKind.hideOption, value: '犬'));
    });

    test(
      'knowing the translation and audio advances despite a writing error',
      () {
        expect(
          learningProgressAfterSession(2, const [
            (
              questionType: QuestionType.japToTrans,
              answer: PracticeAnswer.independent,
            ),
            (
              questionType: QuestionType.voiceToTrans,
              answer: PracticeAnswer.independent,
            ),
            (
              questionType: QuestionType.transToJapInput,
              answer: PracticeAnswer.incorrect,
            ),
          ]),
          3,
        );
      },
    );

    test(
      'assisted answers supply no credit and a single error has no penalty',
      () {
        expect(
          learningProgressAfterSession(2, const [
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
          ]),
          2,
        );
        expect(
          learningProgressAfterSession(2, const [
            (
              questionType: QuestionType.transToJapInput,
              answer: PracticeAnswer.incorrect,
            ),
          ]),
          2,
        );
      },
    );

    test('two clear weighted misses can lower the level, within 0–5', () {
      const misses = [
        (
          questionType: QuestionType.japToTrans,
          answer: PracticeAnswer.independent,
        ),
        (
          questionType: QuestionType.voiceToTrans,
          answer: PracticeAnswer.incorrect,
        ),
        (
          questionType: QuestionType.transToJapInput,
          answer: PracticeAnswer.incorrect,
        ),
      ];
      expect(learningProgressAfterSession(2, misses), 1);
      expect(learningProgressAfterSession(0, misses), 0);
      expect(
        learningProgressAfterSession(5, const [
          (
            questionType: QuestionType.japToTrans,
            answer: PracticeAnswer.independent,
          ),
        ]),
        5,
      );
    });
  });
}
