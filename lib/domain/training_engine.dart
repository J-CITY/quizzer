import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/word.dart';
import '../data/models/settings.dart';
import '../data/models/custom_list.dart';
import '../utils/string_utils.dart';
import '../utils/confusable_characters.dart';
import 'package:quizzer/l10n/app_localizations.dart';

final trainingEngineProvider = Provider<TrainingEngine>((ref) {
  return TrainingEngine();
});

class QuestionType {
  static const int japToReading = 0;
  static const int readingToJap = 1;
  static const int japToTrans = 2;
  static const int transToJap = 3;
  static const int voiceToTrans = 4;
  static const int voiceToJap = 5;
  static const int transToJapInput = 6;
  static const int transToJapConstructor = 7;
  static const int voiceToJapInput = 8;
  static const int voiceToJapConstructor = 9;
  static const int imageToJap = 10;
}

class Question {
  final Word word;
  final String prompt; // e.g. Japanese word
  final String? subtitle; // e.g. reading, shown below the prompt
  final String correctAnswer;
  final List<String> options;
  final int type;

  Question({
    required this.word,
    required this.prompt,
    this.subtitle,
    required this.correctAnswer,
    required this.options,
    required this.type,
  });
}

class TrainingEngine {
  final _random = Random();

  /// Generates a list of [count] questions from [sourceWords].
  /// Generates a list of questions from [sourceWords], repeating each word up to 3 times with different question types.
  List<Question> generateSession(
    List<Word> sourceWords,
    Settings settings,
    AppLocalizations l10n, {
    bool isReviewMode = false,
    CustomList? customList,
  }) {
    if (sourceWords.isEmpty) return [];

    // Целевое количество вопросов
    final targetQuestionsCount = isReviewMode ? sourceWords.length : settings.questionsCount;

    // Рассчитываем необходимое количество уникальных слов (каждое слово до 3 раз)
    final targetUniqueCount = (targetQuestionsCount / 3).ceil();
    final actualUniqueCount = min(targetUniqueCount, sourceWords.length);

    List<Word> selectedWords;

    if (isReviewMode) {
      // Режим повторения: выбираем случайные уникальные слова
      selectedWords = List.from(sourceWords);
      selectedWords.shuffle(_random);
      selectedWords = selectedWords.take(actualUniqueCount).toList();
    } else {
      // Режим обучения: выбираем неизученные слова
      List<Word> unlearned = sourceWords.where((w) => w.progress < 5).toList();

      if (unlearned.isEmpty) {
        unlearned = List.from(sourceWords);
      }

      unlearned.shuffle(_random);
      unlearned.sort((a, b) => a.progress.compareTo(b.progress));

      selectedWords = unlearned.take(actualUniqueCount).toList();
      selectedWords.shuffle(_random);
    }

    // Распределяем вопросы между выбранными словами
    final List<Question> sessionQuestions = [];
    final wordsWithThree = targetQuestionsCount ~/ 3;
    final remainder = targetQuestionsCount % 3;

    for (int i = 0; i < selectedWords.length; i++) {
      final word = selectedWords[i];
      
      // Определяем количество вопросов для данного слова
      int wordQuestionsCount = 0;
      if (i < wordsWithThree) {
        wordQuestionsCount = 3;
      } else if (i == wordsWithThree) {
        wordQuestionsCount = remainder;
      }

      if (wordQuestionsCount == 0) continue;

      // Получаем доступные типы вопросов для этого слова
      final availableTypes = getAvailableQuestionTypes(word, settings, customList);

      // Выбираем уникальные типы вопросов
      final List<int> chosenTypes = [];
      List<int> pool = List.from(availableTypes)..shuffle(_random);
      for (int j = 0; j < wordQuestionsCount; j++) {
        if (pool.isEmpty) {
          pool = List.from(availableTypes)..shuffle(_random);
        }
        chosenTypes.add(pool.removeLast());
      }

      // Генерируем вопросы выбранных типов
      for (final type in chosenTypes) {
        sessionQuestions.add(
          _generateQuestion(word, sourceWords, settings, l10n, customList, type),
        );
      }
    }

    // Перемешиваем финальный список вопросов, чтобы они шли вразнобой
    sessionQuestions.shuffle(_random);

    return sessionQuestions;
  }

  Question regenerateQuestionOptions(
    Question oldQuestion,
    List<Word> allWords,
    Settings settings,
    AppLocalizations l10n,
    CustomList? customList,
  ) {
    return _generateQuestion(
      oldQuestion.word,
      allWords,
      settings,
      l10n,
      customList,
      oldQuestion.type,
    );
  }

  List<int> getAvailableQuestionTypes(
    Word word,
    Settings settings,
    CustomList? customList,
  ) {
    List<int> availableTypes = [];

    bool useVoiceToTranslate = settings.questionVoiceToTranslate;
    bool useVoiceToWord = settings.questionVoiceToWord;
    bool useVoiceToWordInput = settings.questionVoiceToWordInput;
    bool useVoiceToWordConstructor = settings.questionVoiceToWordConstructor;
    bool useTranslateToWordInput = settings.questionTranslateToWordInput;
    bool useTranslateToWordConstructor =
        settings.questionTranslateToWordConstructor;
    bool useWordToTranslate = settings.questionWordToTranslate;
    bool useTranslateToWord = settings.questionTranslateToWord;
    bool useWordToReading = settings.questionWordToReading;
    bool useReadingToWord = settings.questionReadingToWord;
    bool useImageToWord = settings.questionImageToWord && word.imageUrl != null && word.imageUrl!.isNotEmpty;

    if (customList != null && customList.useCustomQuestionSettings) {
      useVoiceToTranslate = customList.questionVoiceToTranslate;
      useVoiceToWord = customList.questionVoiceToWord;
      useVoiceToWordInput = customList.questionVoiceToWordInput;
      useVoiceToWordConstructor = customList.questionVoiceToWordConstructor;
      useTranslateToWordInput = customList.questionTranslateToWordInput;
      useTranslateToWordConstructor =
          customList.questionTranslateToWordConstructor;
      useWordToTranslate = customList.questionWordToTranslate;
      useTranslateToWord = customList.questionTranslateToWord;
      useWordToReading = customList.questionWordToReading;
      useReadingToWord = customList.questionReadingToWord;
      useImageToWord = customList.questionImageToWord && word.imageUrl != null && word.imageUrl!.isNotEmpty;
    }

    if (useWordToTranslate) {
      availableTypes.add(QuestionType.japToTrans);
    }
    if (useTranslateToWord) {
      availableTypes.add(QuestionType.transToJap);
    }
    if (useWordToReading && word.reading != null && word.reading!.isNotEmpty) {
      availableTypes.add(QuestionType.japToReading);
    }
    if (useReadingToWord && word.reading != null && word.reading!.isNotEmpty) {
      availableTypes.add(QuestionType.readingToJap);
    }
    if (useVoiceToTranslate) {
      availableTypes.add(QuestionType.voiceToTrans);
    }
    if (useVoiceToWord) {
      availableTypes.add(QuestionType.voiceToJap);
    }
    if (useVoiceToWordInput) {
      availableTypes.add(QuestionType.voiceToJapInput);
    }
    if (useVoiceToWordConstructor) {
      availableTypes.add(QuestionType.voiceToJapConstructor);
    }
    if (useTranslateToWordInput) {
      availableTypes.add(QuestionType.transToJapInput);
    }
    if (useTranslateToWordConstructor) {
      availableTypes.add(QuestionType.transToJapConstructor);
    }
    if (useImageToWord) {
      availableTypes.add(QuestionType.imageToJap);
    }
    if (availableTypes.isEmpty) {
      availableTypes.add(QuestionType.japToTrans); // Fallback
    }

    return availableTypes;
  }

  Question _generateQuestion(
    Word word,
    List<Word> allWords,
    Settings settings,
    AppLocalizations l10n,
    CustomList? customList, [
    int? forceType,
  ]) {
    final availableTypes = getAvailableQuestionTypes(word, settings, customList);
    final type = forceType ?? availableTypes[_random.nextInt(availableTypes.length)];

    String prompt = '';
    String? subtitle;
    String correctAnswer = '';
    List<String> wrongOptions = [];
    List<String>? customOptions;

    // Helper to format Japanese + Reading for translation questions
    String getJapaneseDisplay(Word w) {
      if (w.reading != null && w.reading!.isNotEmpty) {
        return '${w.japanese} (${w.reading})';
      }
      return w.japanese;
    }

    switch (type) {
      case QuestionType.japToReading:
        prompt = word.japanese;
        correctAnswer = word.reading!;
        if (word.reading!.contains('/')) {
          final correctReadings = word.reading!.split('/').map((e) => e.trim()).toList();
          
          wrongOptions = _getWrongOptions(
            allWords,
            word,
            (w) => w.reading,
            true,
            settings,
            l10n,
          );

          Set<String> allWrongChips = {};
          for (var w in wrongOptions) {
            allWrongChips.addAll(w.split('/').map((e) => e.trim()));
          }
          allWrongChips.removeAll(correctReadings);

          const int maxMultipleChoiceOptions = 8;
          int targetWrongCount = maxMultipleChoiceOptions - correctReadings.length;
          if (targetWrongCount < correctReadings.length) {
              targetWrongCount = correctReadings.length;
          }
          final wrongList = allWrongChips.toList()..shuffle(_random);
          final selectedWrong = wrongList.take(targetWrongCount).toList();

          customOptions = [...correctReadings, ...selectedWrong]..shuffle(_random);
          wrongOptions = [];
        } else {
          wrongOptions = _getWrongOptions(
            allWords,
            word,
            (w) => w.reading,
            true,
            settings,
            l10n,
          );
        }
        break;
      case QuestionType.readingToJap:
        prompt = word.reading!;
        correctAnswer = word.japanese;
        wrongOptions = _getWrongOptions(
          allWords,
          word,
          (w) => w.japanese,
          true,
          settings,
          l10n,
        );
        break;
      case QuestionType.japToTrans:
        prompt = word.japanese;
        subtitle = word.reading;
        correctAnswer = word.translation;
        wrongOptions = _getWrongOptions(
          allWords,
          word,
          (w) => w.translation,
          false,
          settings,
          l10n,
        );
        break;
      case QuestionType.transToJap:
        prompt = word.translation;
        correctAnswer = getJapaneseDisplay(word);
        wrongOptions = _getWrongOptions(
          allWords,
          word,
          getJapaneseDisplay,
          true,
          settings,
          l10n,
        );
        break;
      case QuestionType.voiceToTrans:
        prompt = ''; // handled in UI
        correctAnswer = word.translation;
        wrongOptions = _getWrongOptions(
          allWords,
          word,
          (w) => w.translation,
          false,
          settings,
          l10n,
        );
        break;
      case QuestionType.voiceToJap:
        prompt = ''; // handled in UI
        correctAnswer = getJapaneseDisplay(word);
        wrongOptions = _getWrongOptions(
          allWords,
          word,
          getJapaneseDisplay,
          true,
          settings,
          l10n,
        );
        break;
      case QuestionType.transToJapInput:
        prompt = word.translation;
        correctAnswer = word.japanese;
        wrongOptions = [];
        break;
      case QuestionType.transToJapConstructor:
        prompt = word.translation;
        correctAnswer = word.japanese;

        final correctChars = word.japanese.split('');
        final extraCharsCount = _random.nextInt(correctChars.length + 2) + 1;
        final extraChars = <String>[];
        final allChars = allWords.map((w) => w.japanese).join('').split('');
        allChars.shuffle(_random);

        for (final c in allChars) {
          if (!correctChars.contains(c) &&
              !extraChars.contains(c) &&
              c.trim().isNotEmpty) {
            extraChars.add(c);
            if (extraChars.length >= extraCharsCount) break;
          }
        }

        customOptions = [...correctChars, ...extraChars]..shuffle(_random);
        wrongOptions = [];
        break;
      case QuestionType.voiceToJapInput:
        prompt = ''; // Handled in UI
        correctAnswer = word.japanese;
        wrongOptions = [];
        break;
      case QuestionType.voiceToJapConstructor:
        prompt = ''; // Handled in UI
        correctAnswer = word.japanese;

        final correctChars2 = word.japanese.split('');
        final extraCharsCount2 = _random.nextInt(correctChars2.length + 2) + 1;
        final extraChars2 = <String>[];
        final allChars2 = allWords.map((w) => w.japanese).join('').split('');
        allChars2.shuffle(_random);

        for (final c in allChars2) {
          if (!correctChars2.contains(c) &&
              !extraChars2.contains(c) &&
              c.trim().isNotEmpty) {
            extraChars2.add(c);
            if (extraChars2.length >= extraCharsCount2) break;
          }
        }

        customOptions = [...correctChars2, ...extraChars2]..shuffle(_random);
        wrongOptions = [];
        break;
      case QuestionType.imageToJap:
        prompt = ''; // Handled in UI
        correctAnswer = getJapaneseDisplay(word);
        wrongOptions = _getWrongOptions(
          allWords,
          word,
          getJapaneseDisplay,
          true,
          settings,
          l10n,
        );
        break;
    }

    // Mix correct answer with wrong ones (if not already custom)
    final options =
        customOptions ?? ([...wrongOptions, correctAnswer]..shuffle(_random));

    return Question(
      word: word,
      prompt: prompt,
      subtitle: subtitle,
      correctAnswer: correctAnswer,
      options: options,
      type: type,
    );
  }

  Map<String, List<String>>? _cachedConfusableMap;
  String? _cachedGroupsKey;

  Map<String, List<String>> _getConfusableMap(List<String> groups) {
    final key = groups.join('|');
    if (_cachedGroupsKey == key && _cachedConfusableMap != null) {
      return _cachedConfusableMap!;
    }
    _cachedGroupsKey = key;
    _cachedConfusableMap = buildConfusableMap(groups);
    return _cachedConfusableMap!;
  }

  /// Extracts 3 wrong options from other words in the list
  List<String> _getWrongOptions(
    List<Word> allWords,
    Word targetWord,
    String? Function(Word) extractor,
    bool isTargetLanguage,
    Settings settings,
    AppLocalizations l10n,
  ) {
    final correctValue = extractor(targetWord);
    if (correctValue == null) {
      return [l10n.error1, l10n.error2, l10n.error3];
    }
    final possibleWords = allWords.where((w) {
      final val = extractor(w);
      return val != null && val.isNotEmpty && val != correctValue;
    }).toList();

    Set<String> wrongValues = {};
    int attempts = 0;

    // Pre-build or get cached confusable map
    final confusableMap = _getConfusableMap(settings.customConfusableGroups);

    // Pre-sort by levenshtein if similar words are enabled
    List<String> possibleValues = possibleWords
        .map((w) => extractor(w)!)
        .toSet()
        .toList();
    if (settings.useSimilarWordsForOptions) {
      // Cache levenshtein distances to avoid recalculating during sort
      final distances = <String, int>{};
      for (final val in possibleValues) {
        distances[val] = levenshtein(correctValue, val);
      }
      possibleValues.sort((a, b) => distances[a]!.compareTo(distances[b]!));
    } else {
      possibleValues.shuffle(_random);
    }

    while (wrongValues.length < 3 && attempts < 50) {
      attempts++;
      final option = _generateSingleWrongOption(
        correctValue,
        possibleValues,
        isTargetLanguage,
        settings,
        confusableMap,
        wrongValues.length,
      );
      if (option != null &&
          option != correctValue &&
          !wrongValues.contains(option)) {
        wrongValues.add(option);
      }
    }

    // Fill with random strings if the dictionary is extremely small
    while (wrongValues.length < 3) {
      //TODO: В таком случае сделать неправильные ответы одинаковыми или сократить количество вариантов.
      wrongValues.add(l10n.randomOption(_random.nextInt(100).toString()));
    }

    return wrongValues.toList();
  }

  String? _generateSingleWrongOption(
    String correctValue,
    List<String> possibleValues,
    bool isTargetLanguage,
    Settings settings,
    Map<String, List<String>> confusableMap,
    int indexToTake,
  ) {
    bool useSpoil = false;

    if (isTargetLanguage && settings.useSpoiledWordsForOptions) {
      if (settings.useSimilarWordsForOptions) {
        useSpoil = _random.nextBool();
      } else {
        useSpoil = true;
      }
    }

    if (useSpoil) {
      final spoiled = spoilWord(correctValue, confusableMap);
      if (spoiled != null) return spoiled;
    }

    // Fallback to taking from possibleValues (which are already sorted by levenshtein or shuffled)
    if (indexToTake < possibleValues.length) {
      return possibleValues[indexToTake];
    }

    if (possibleValues.isNotEmpty) {
      return possibleValues[_random.nextInt(possibleValues.length)];
    }

    return null;
  }
}
