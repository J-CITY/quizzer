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
    settings.questionImageToWord = false; // Для картинок нужен imageUrl, оставим false
    return settings;
  }

  group('TrainingEngine - 3x Word Questions Feature', () {
    test('Learn Mode: Generates exactly count questions if there are enough words', () {
      final sourceWords = createMockWords(10);
      final settings = createDefaultSettings(questionsCount: 15);

      final session = engine.generateSession(
        sourceWords,
        settings,
        l10n,
        isReviewMode: false,
      );

      expect(session.length, equals(15));
    });

    test('Learn Mode: Each word appears exactly 3 times with different question types', () {
      final sourceWords = createMockWords(10);
      final settings = createDefaultSettings(questionsCount: 15);

      final session = engine.generateSession(
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
        expect(types.length, equals(3), reason: 'Questions for word "${entry.key}" should have unique types');
      }
    });

    test('Review Mode: Generates 3x questions based on sourceWords length and keeps total count matching sourceWords length', () {
      final sourceWords = createMockWords(15); // 15 слов, значит ожидаем 15 вопросов
      final settings = createDefaultSettings();

      final session = engine.generateSession(
        sourceWords,
        settings,
        l10n,
        isReviewMode: true,
      );

      expect(session.length, equals(15));

      final Map<String, List<Question>> questionsByWord = {};
      for (var q in session) {
        questionsByWord.putIfAbsent(q.word.japanese, () => []).add(q);
      }

      // Должно быть выбрано 5 уникальных слов (15 / 3)
      expect(questionsByWord.keys.length, equals(5));

      for (var entry in questionsByWord.entries) {
        final wordQuestions = entry.value;
        expect(wordQuestions.length, equals(3));

        final types = wordQuestions.map((q) => q.type).toSet();
        expect(types.length, equals(3));
      }
    });

    test('Boundary Case: Fewer words than required for a full session', () {
      final sourceWords = createMockWords(2); // Только 2 слова
      final settings = createDefaultSettings(questionsCount: 15);

      final session = engine.generateSession(
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

      // 3 слова по 3 вопроса, 1 слово — 1 вопрос
      int countThree = 0;
      int countOne = 0;

      for (var entry in questionsByWord.entries) {
        if (entry.value.length == 3) {
          countThree++;
          final types = entry.value.map((q) => q.type).toSet();
          expect(types.length, equals(3));
        } else if (entry.value.length == 1) {
          countOne++;
        } else {
          fail('Word ${entry.key} has unexpected number of questions: ${entry.value.length}');
        }
      }

      expect(countThree, equals(3));
      expect(countOne, equals(1));
    });
  });
}
