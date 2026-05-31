import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/word.dart';
import '../data/models/settings.dart';
import '../utils/string_utils.dart';
import '../utils/confusable_characters.dart';

final trainingEngineProvider = Provider<TrainingEngine>((ref) {
  return TrainingEngine();
});

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
  List<Question> generateSession(List<Word> sourceWords, Settings settings, {bool isReviewMode = false}) {
    if (sourceWords.isEmpty) return [];

    final count = settings.questionsCount;
    List<Word> selectedWords;

    if (isReviewMode) {
      // Review mode: take all words in the list, shuffled
      selectedWords = List.from(sourceWords);
      selectedWords.shuffle(_random);
    } else {
      // Learn mode: take up to [count] unlearned words, don't repeat
      List<Word> unlearned = sourceWords.where((w) => w.progress < 5).toList();
      
      if (unlearned.isEmpty) {
        unlearned = List.from(sourceWords);
      }
      
      unlearned.shuffle(_random);
      unlearned.sort((a, b) => a.progress.compareTo(b.progress));

      final actualCount = min(count, unlearned.length);
      selectedWords = unlearned.take(actualCount).toList();
      selectedWords.shuffle(_random);
    }

    return selectedWords.map((w) => _generateQuestion(w, sourceWords, settings)).toList();
  }

  Question _generateQuestion(Word word, List<Word> allWords, Settings settings) {
    List<int> availableTypes = [];
    
    if (settings.questionWordToTranslate) availableTypes.add(2); // Jap->Trans
    if (settings.questionTranslateToWord) availableTypes.add(3); // Trans->Jap
    if (settings.questionWordToReading && word.reading != null && word.reading!.isNotEmpty) {
      availableTypes.add(0); // Jap->Read
    }
    if (settings.questionReadingToWord && word.reading != null && word.reading!.isNotEmpty) {
      availableTypes.add(1); // Read->Jap
    }

    if (availableTypes.isEmpty) {
      availableTypes.add(2); // Fallback
    }

    final type = availableTypes[_random.nextInt(availableTypes.length)];
    
    String prompt = '';
    String? subtitle;
    String correctAnswer = '';
    List<String> wrongOptions = [];

    // Helper to format Japanese + Reading for translation questions
    String getJapaneseDisplay(Word w) {
      if (w.reading != null && w.reading!.isNotEmpty) {
        return '${w.japanese} (${w.reading})';
      }
      return w.japanese;
    }

    switch (type) {
      case 0: // Japanese -> Reading
        prompt = word.japanese;
        correctAnswer = word.reading!;
        wrongOptions = _getWrongOptions(allWords, word, (w) => w.reading, true, settings);
        break;
      case 1: // Reading -> Japanese
        prompt = word.reading!;
        correctAnswer = word.japanese;
        wrongOptions = _getWrongOptions(allWords, word, (w) => w.japanese, true, settings);
        break;
      case 2: // Japanese (+reading) -> Translation
        prompt = word.japanese;
        subtitle = word.reading;
        correctAnswer = word.translation;
        wrongOptions = _getWrongOptions(allWords, word, (w) => w.translation, false, settings);
        break;
      case 3: // Translation -> Japanese (+reading)
        prompt = word.translation;
        correctAnswer = getJapaneseDisplay(word);
        wrongOptions = _getWrongOptions(allWords, word, getJapaneseDisplay, true, settings);
        break;
    }

    // Mix correct answer with wrong ones
    final options = [...wrongOptions, correctAnswer]..shuffle(_random);

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
  List<String> _getWrongOptions(List<Word> allWords, Word targetWord, String? Function(Word) extractor, bool isTargetLanguage, Settings settings) {
    final correctValue = extractor(targetWord);
    if (correctValue == null) return ["Ошибка 1", "Ошибка 2", "Ошибка 3"];

    final possibleWords = allWords.where((w) {
      final val = extractor(w);
      return val != null && val.isNotEmpty && val != correctValue;
    }).toList();

    Set<String> wrongValues = {};
    int attempts = 0;
    
    // Pre-build or get cached confusable map
    final confusableMap = _getConfusableMap(settings.customConfusableGroups);
    
    // Pre-sort by levenshtein if similar words are enabled
    List<String> possibleValues = possibleWords.map((w) => extractor(w)!).toSet().toList();
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
      final option = _generateSingleWrongOption(correctValue, possibleValues, isTargetLanguage, settings, confusableMap, wrongValues.length);
      if (option != null && option != correctValue && !wrongValues.contains(option)) {
        wrongValues.add(option);
      }
    }

    // Fill with random strings if the dictionary is extremely small
    while (wrongValues.length < 3) {
      wrongValues.add('Случайный вариант ${_random.nextInt(100)}');
    }

    return wrongValues.toList();
  }

  String? _generateSingleWrongOption(String correctValue, List<String> possibleValues, bool isTargetLanguage, Settings settings, Map<String, List<String>> confusableMap, int indexToTake) {
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
