import 'dart:math';
import 'package:flutter/widgets.dart' show StringCharacters;
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

enum QuestionHintKind { mnemonic, firstCharacter, hideOption }

typedef QuestionHint = ({QuestionHintKind kind, String value});

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

  bool get isVoice =>
      type == QuestionType.voiceToTrans ||
      type == QuestionType.voiceToJap ||
      type == QuestionType.voiceToJapInput ||
      type == QuestionType.voiceToJapConstructor;

  bool get isTextInput =>
      type == QuestionType.transToJapInput ||
      type == QuestionType.voiceToJapInput;

  bool get isConstructor =>
      type == QuestionType.transToJapConstructor ||
      type == QuestionType.voiceToJapConstructor;

  bool get isMultiSelection =>
      type == QuestionType.japToReading && correctAnswer.contains('/');

  bool acceptsAnswer(String answer) {
    if (isTextInput) {
      return answer.trim() == word.japanese.trim() ||
          (word.reading != null && answer.trim() == word.reading!.trim());
    }
    if (isMultiSelection) {
      final selected = _readingOptions(answer);
      final expected = _readingOptions(correctAnswer);
      return selected.length == expected.length &&
          selected.containsAll(expected);
    }
    return answer.trim() == correctAnswer.trim();
  }

  QuestionHint? get hint {
    final mnemonic = word.mnemonic?.trim();
    if (mnemonic != null && mnemonic.isNotEmpty) {
      return (kind: QuestionHintKind.mnemonic, value: mnemonic);
    }
    if (isTextInput || isConstructor) {
      final characters = correctAnswer.trim().characters;
      if (characters.length > 1) {
        return (kind: QuestionHintKind.firstCharacter, value: characters.first);
      }
      return null;
    }
    final correctOptions = isMultiSelection
        ? _readingOptions(correctAnswer)
        : {correctAnswer.trim()};
    final distractors = options.where(
      (option) => !correctOptions.contains(option.trim()),
    );
    if (distractors.length < 2) return null;
    return (kind: QuestionHintKind.hideOption, value: distractors.first);
  }

  static Set<String> _readingOptions(String answer) => answer
      .split('/')
      .map((option) => option.trim())
      .where((option) => option.isNotEmpty)
      .toSet();
}

enum PracticeAnswer { independent, assisted, incorrect }

enum PracticeSkill {
  translation(2),
  listening(3),
  writing(3);

  const PracticeSkill(this.weight);

  final int weight;

  static PracticeSkill forQuestionType(int questionType) =>
      switch (questionType) {
        QuestionType.voiceToTrans || QuestionType.voiceToJap => listening,
        QuestionType.transToJapInput ||
        QuestionType.transToJapConstructor ||
        QuestionType.voiceToJapInput ||
        QuestionType.voiceToJapConstructor => writing,
        _ => translation,
      };
}

typedef PracticeAttempt = ({int questionType, PracticeAnswer answer});

class SkillPracticeResult {
  final int independent;
  final int assisted;
  final int incorrect;
  final List<int> practiceWordIds;

  const SkillPracticeResult({
    required this.independent,
    required this.assisted,
    required this.incorrect,
    required this.practiceWordIds,
  });

  int get total => independent + assisted + incorrect;
}

Map<PracticeSkill, SkillPracticeResult> summarizePracticeSkills(
  Map<int, List<PracticeAttempt>> attemptsByWord,
) {
  final answers = {
    for (final skill in PracticeSkill.values) skill: <PracticeAnswer>[],
  };
  final practiceWords = {
    for (final skill in PracticeSkill.values) skill: <int>{},
  };
  for (final entry in attemptsByWord.entries) {
    for (final attempt in entry.value) {
      final skill = PracticeSkill.forQuestionType(attempt.questionType);
      answers[skill]!.add(attempt.answer);
      if (attempt.answer != PracticeAnswer.independent) {
        practiceWords[skill]!.add(entry.key);
      }
    }
  }
  return {
    for (final skill in PracticeSkill.values)
      skill: SkillPracticeResult(
        independent: answers[skill]!
            .where((answer) => answer == PracticeAnswer.independent)
            .length,
        assisted: answers[skill]!
            .where((answer) => answer == PracticeAnswer.assisted)
            .length,
        incorrect: answers[skill]!
            .where((answer) => answer == PracticeAnswer.incorrect)
            .length,
        practiceWordIds: List.unmodifiable(practiceWords[skill]!),
      ),
  };
}

/// Uses first attempts only. Assisted answers provide neither credit nor penalty.
int learningProgressAfterSession(
  int previousProgress,
  List<PracticeAttempt> attempts,
) {
  if (attempts.isEmpty) return previousProgress;
  var totalWeight = 0;
  var independentWeight = 0;
  var incorrectWeight = 0;
  var independentCount = 0;
  var incorrectCount = 0;
  for (final attempt in attempts) {
    final weight = PracticeSkill.forQuestionType(attempt.questionType).weight;
    totalWeight += weight;
    switch (attempt.answer) {
      case PracticeAnswer.independent:
        independentCount++;
        independentWeight += weight;
      case PracticeAnswer.incorrect:
        incorrectCount++;
        incorrectWeight += weight;
      case PracticeAnswer.assisted:
        break;
    }
  }
  if (independentCount >= min(2, attempts.length) &&
      independentWeight * 5 >= totalWeight * 3) {
    return min(5, previousProgress + 1);
  }
  if (incorrectCount >= 2 && incorrectWeight * 5 >= totalWeight * 3) {
    return max(0, previousProgress - 1);
  }
  return previousProgress;
}

class TrainingEngine {
  static const _rushQuestionTypes = {
    QuestionType.japToReading,
    QuestionType.readingToJap,
    QuestionType.japToTrans,
    QuestionType.transToJap,
    QuestionType.transToJapInput,
    QuestionType.transToJapConstructor,
  };
  final _random = Random();

  /// Shuffles the list once and generates each offline question on demand.
  Iterable<Question> generateRushSession(
    List<Word> words,
    Settings settings,
    AppLocalizations l10n, {
    CustomList? customList,
  }) sync* {
    final shuffledWords = words.toList()..shuffle(_random);
    for (final word in shuffledWords) {
      final types = getAvailableQuestionTypes(
        word,
        settings,
        customList,
      ).where(_rushQuestionTypes.contains).toList()..shuffle(_random);
      if (types.isEmpty) types.add(QuestionType.japToTrans);

      Question? question;
      for (final type in types) {
        final candidate = _generateQuestion(
          word,
          words,
          settings,
          l10n,
          customList,
          type,
          true,
        );
        if (candidate.isTextInput ||
            candidate.isConstructor ||
            (!candidate.isMultiSelection && candidate.options.length > 1) ||
            (candidate.isMultiSelection &&
                candidate.options.any(
                  (option) => !Question._readingOptions(
                    candidate.correctAnswer,
                  ).contains(option),
                ))) {
          question = candidate;
          break;
        }
      }
      yield question ??
          _generateQuestion(
            word,
            words,
            settings,
            l10n,
            customList,
            QuestionType.transToJapConstructor,
            true,
          );
    }
  }

  static int sessionQuestionLimit(Settings settings, CustomList? list) {
    if (list != null &&
        list.useCustomTrainingSettings &&
        list.questionsCount > 0) {
      return list.questionsCount;
    }
    return max(1, settings.questionsCount);
  }

  static List<Word> dueReviewWords(Iterable<Word> words, DateTime now) {
    final earliest = DateTime.fromMillisecondsSinceEpoch(0);
    return words.where((word) => word.isReviewDue(now)).toList()..sort((a, b) {
      final byDate = (a.effectiveNextReviewAt ?? earliest).compareTo(
        b.effectiveNextReviewAt ?? earliest,
      );
      return byDate == 0 ? a.id.compareTo(b.id) : byDate;
    });
  }

  List<Question> generateSession(
    List<Word> sourceWords,
    List<Word> dictionaryWords,
    Settings settings,
    AppLocalizations l10n, {
    bool isReviewMode = false,
    CustomList? customList,
    List<int>? reviewWordIds,
    PracticeSkill? reviewSkill,
    DateTime? now,
  }) {
    if (sourceWords.isEmpty) return [];

    final questionLimit = sessionQuestionLimit(settings, customList);
    if (isReviewMode) {
      final List<Word> selectedWords;
      if (reviewWordIds != null) {
        final byId = {for (final word in sourceWords) word.id: word};
        selectedWords = [for (final id in reviewWordIds.toSet()) ?byId[id]];
      } else {
        final due = dueReviewWords(sourceWords, now ?? DateTime.now());
        selectedWords = due.isNotEmpty
            ? due
            : (sourceWords.toList()..shuffle(_random));
      }
      return [
        for (final word in selectedWords.take(questionLimit))
          _generateQuestion(
            word,
            dictionaryWords,
            settings,
            l10n,
            customList,
            reviewSkill == null
                ? null
                : _focusedQuestionType(word, settings, customList, reviewSkill),
          ),
      ];
    }

    final int repetitions = max(
      1,
      customList != null &&
              customList.useCustomTrainingSettings &&
              customList.targetWordRepetitions > 0
          ? customList.targetWordRepetitions
          : settings.targetWordRepetitions,
    );
    final words = sourceWords.where((word) => !word.isLearned).toList()
      ..shuffle(_random)
      ..sort((a, b) => a.progress.compareTo(b.progress));
    if (words.isEmpty) return [];

    final targetWords = (questionLimit / repetitions).ceil();
    // When multiple checks per word are requested, avoid giving the last word
    // a single scored question just to fill the session quota.
    final wordsWithEnoughQuestions = repetitions == 1
        ? targetWords
        : min(targetWords, max(1, questionLimit ~/ 2));
    final selectedWords = words.take(wordsWithEnoughQuestions).toList();
    final totalQuestions = min(
      questionLimit,
      selectedWords.length * repetitions,
    );
    final questionsPerWord = totalQuestions ~/ selectedWords.length;
    final extraQuestions = totalQuestions % selectedWords.length;

    final questions = <Question>[];
    for (final (index, word) in selectedWords.indexed) {
      final questionCount = questionsPerWord + (index < extraQuestions ? 1 : 0);
      final types = getAvailableQuestionTypes(word, settings, customList);
      for (final type in _chooseStudyQuestionTypes(types, questionCount)) {
        questions.add(
          _generateQuestion(
            word,
            dictionaryWords,
            settings,
            l10n,
            customList,
            type,
          ),
        );
      }
    }
    return questions..shuffle(_random);
  }

  Iterable<int> _chooseStudyQuestionTypes(List<int> types, int count) sync* {
    // First sample each available skill, then cycle through unused types.
    final shuffled = types.toList()..shuffle(_random);
    final seenSkills = <PracticeSkill>{};
    final distinctSkills = <int>[];
    final otherTypes = <int>[];
    for (final type in shuffled) {
      if (seenSkills.add(PracticeSkill.forQuestionType(type))) {
        distinctSkills.add(type);
      } else {
        otherTypes.add(type);
      }
    }
    final ordered = [...distinctSkills, ...otherTypes];
    for (var index = 0; index < count; index++) {
      yield ordered[index % ordered.length];
    }
  }

  int _focusedQuestionType(
    Word word,
    Settings settings,
    CustomList? customList,
    PracticeSkill skill,
  ) {
    final types =
        getAvailableQuestionTypes(word, settings, customList)
            .where(
              (type) =>
                  type != QuestionType.imageToJap &&
                  PracticeSkill.forQuestionType(type) == skill,
            )
            .toList()
          ..shuffle(_random);
    return types.firstOrNull ??
        switch (skill) {
          PracticeSkill.translation => QuestionType.japToTrans,
          PracticeSkill.listening => QuestionType.voiceToTrans,
          PracticeSkill.writing => QuestionType.transToJapConstructor,
        };
  }

  Question replaceUnavailableImageQuestion(
    Question question,
    List<Word> dictionaryWords,
    Settings settings,
    AppLocalizations l10n,
    CustomList? customList,
  ) {
    final alternatives =
        getAvailableQuestionTypes(
            question.word,
            settings,
            customList,
          ).where((type) => type != QuestionType.imageToJap).toList()
          ..shuffle(_random);
    return _generateQuestion(
      question.word,
      dictionaryWords,
      settings,
      l10n,
      customList,
      alternatives.firstOrNull ?? QuestionType.japToTrans,
    );
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
    bool useImageToWord =
        settings.questionImageToWord &&
        word.imageUrl != null &&
        word.imageUrl!.isNotEmpty;

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
      useImageToWord =
          customList.questionImageToWord &&
          word.imageUrl != null &&
          word.imageUrl!.isNotEmpty;
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
    bool isRush = false,
  ]) {
    final availableTypes = getAvailableQuestionTypes(
      word,
      settings,
      customList,
    );
    final type =
        forceType ?? availableTypes[_random.nextInt(availableTypes.length)];

    String prompt = '';
    String? subtitle;
    String correctAnswer = '';
    List<String> wrongOptions = [];
    List<String>? customOptions;

    List<String> getWrongOptions(
      String? Function(Word) extractor,
      bool isTargetLanguage,
    ) => _getWrongOptions(
      allWords,
      word,
      extractor,
      isTargetLanguage,
      settings,
      l10n,
      isRush: isRush,
    );

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
          final correctReadings = word.reading!
              .split('/')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

          wrongOptions = getWrongOptions((w) => w.reading, true);

          Set<String> allWrongChips = {};
          for (var w in wrongOptions) {
            allWrongChips.addAll(
              w.split('/').map((e) => e.trim()).where((e) => e.isNotEmpty),
            );
          }
          allWrongChips.removeAll(correctReadings);

          const int maxMultipleChoiceOptions = 8;
          int targetWrongCount =
              maxMultipleChoiceOptions - correctReadings.length;
          if (targetWrongCount < correctReadings.length) {
            targetWrongCount = correctReadings.length;
          }
          final wrongList = allWrongChips.toList()..shuffle(_random);
          final selectedWrong = wrongList.take(targetWrongCount).toList();

          customOptions = [...correctReadings, ...selectedWrong]
            ..shuffle(_random);
          wrongOptions = [];
        } else {
          wrongOptions = getWrongOptions((w) => w.reading, true);
        }
        break;
      case QuestionType.readingToJap:
        prompt = word.reading!;
        correctAnswer = word.japanese;
        wrongOptions = getWrongOptions((w) => w.japanese, true);
        break;
      case QuestionType.japToTrans:
        prompt = word.japanese;
        subtitle = word.reading;
        correctAnswer = word.translation;
        wrongOptions = getWrongOptions((w) => w.translation, false);
        break;
      case QuestionType.transToJap:
        prompt = word.translation;
        correctAnswer = getJapaneseDisplay(word);
        wrongOptions = getWrongOptions(getJapaneseDisplay, true);
        break;
      case QuestionType.voiceToTrans:
        prompt = ''; // handled in UI
        correctAnswer = word.translation;
        wrongOptions = getWrongOptions((w) => w.translation, false);
        break;
      case QuestionType.voiceToJap:
        prompt = ''; // handled in UI
        correctAnswer = getJapaneseDisplay(word);
        wrongOptions = getWrongOptions(getJapaneseDisplay, true);
        break;
      case QuestionType.transToJapInput:
        prompt = word.translation;
        correctAnswer = word.japanese;
        wrongOptions = [];
        break;
      case QuestionType.voiceToJapInput:
        prompt = ''; // Handled in UI
        correctAnswer = word.japanese;
        wrongOptions = [];
        break;
      case QuestionType.transToJapConstructor:
      case QuestionType.voiceToJapConstructor:
        if (type == QuestionType.transToJapConstructor) {
          prompt = word.translation;
        }
        correctAnswer = word.japanese.replaceAll(' ', '');

        final correctChars = correctAnswer.characters.toList();
        final usedChars = correctChars.toSet();
        final extraCharsCount = _random.nextInt(correctChars.length + 2) + 1;
        final distractors =
            allWords
                .expand((w) => w.japanese.characters)
                .where(
                  (char) => char.trim().isNotEmpty && !usedChars.contains(char),
                )
                .toSet()
                .toList()
              ..shuffle(_random);
        customOptions = [...correctChars, ...distractors.take(extraCharsCount)]
          ..shuffle(_random);
        break;
      case QuestionType.imageToJap:
        prompt = ''; // Handled in UI
        correctAnswer = getJapaneseDisplay(word);
        wrongOptions = getWrongOptions(getJapaneseDisplay, true);
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
    AppLocalizations l10n, {
    required bool isRush,
  }) {
    final correctValue = extractor(targetWord);
    if (correctValue == null) {
      return [l10n.error1, l10n.error2, l10n.error3];
    }
    final possibleWords = allWords.where((w) {
      final val = extractor(w);
      return val != null &&
          val.trim().isNotEmpty &&
          val.trim() != correctValue.trim();
    }).toList();

    Set<String> wrongValues = {};
    int attempts = 0;

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

    if (isRush) return possibleValues.take(3).toList();

    final confusableMap = _getConfusableMap(settings.customConfusableGroups);
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
