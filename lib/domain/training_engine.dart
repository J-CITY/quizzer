import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/word.dart';
import '../data/models/settings.dart';

final trainingEngineProvider = Provider<TrainingEngine>((ref) {
  return TrainingEngine();
});

class Question {
  final Word word;
  final String prompt; // e.g. Japanese word
  final String? subtitle; // e.g. reading, shown below the prompt
  final String correctAnswer;
  final List<String> options;

  Question({
    required this.word,
    required this.prompt,
    this.subtitle,
    required this.correctAnswer,
    required this.options,
  });
}

class TrainingEngine {
  final _random = Random();

  /// Generates a list of [count] questions from [sourceWords].
  List<Question> generateSession(List<Word> sourceWords, Settings settings) {
    if (sourceWords.isEmpty) return [];

    final count = settings.questionsCount;

    // Prioritize words that are not fully learned
    List<Word> candidates = sourceWords.where((w) => w.progress < 5).toList();
    
    // If we don't have enough unlearned words, add learned ones
    if (candidates.length < count) {
      final learned = sourceWords.where((w) => w.progress >= 5).toList();
      learned.shuffle(_random);
      candidates.addAll(learned.take(count - candidates.length));
    }

    // Shuffle and sort by progress (lower progress first)
    candidates.shuffle(_random);
    candidates.sort((a, b) => a.progress.compareTo(b.progress));

    // Select words. If we need 50 but have 10, they repeat.
    List<Word> selectedWords = [];
    for (int i = 0; i < count; i++) {
      selectedWords.add(candidates[i % candidates.length]);
    }

    // Shuffle selected words so they appear in random order
    selectedWords.shuffle(_random);

    return selectedWords.map((w) => _generateQuestion(w, sourceWords, settings)).toList();
  }

  Question _generateQuestion(Word word, List<Word> allWords, Settings settings) {
    List<int> availableTypes = [];
    
    if (settings.questionWordToTranslate) availableTypes.add(2); // Jap->Trans
    if (settings.questionTranslateToWord) availableTypes.add(3); // Trans->Jap
    if (settings.questionReading && word.reading != null && word.reading!.isNotEmpty) {
      availableTypes.addAll([0, 1]); // Jap->Read, Read->Jap
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
        wrongOptions = _getWrongOptions(allWords, word, (w) => w.reading);
        break;
      case 1: // Reading -> Japanese
        prompt = word.reading!;
        correctAnswer = word.japanese;
        wrongOptions = _getWrongOptions(allWords, word, (w) => w.japanese);
        break;
      case 2: // Japanese (+reading) -> Translation
        prompt = word.japanese;
        subtitle = word.reading;
        correctAnswer = word.translation;
        wrongOptions = _getWrongOptions(allWords, word, (w) => w.translation);
        break;
      case 3: // Translation -> Japanese (+reading)
        prompt = word.translation;
        correctAnswer = getJapaneseDisplay(word);
        wrongOptions = _getWrongOptions(allWords, word, getJapaneseDisplay);
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
    );
  }

  /// Extracts 3 wrong options from other words in the list
  List<String> _getWrongOptions(List<Word> allWords, Word targetWord, String? Function(Word) extractor) {
    final correctValue = extractor(targetWord);
    if (correctValue == null) return ["Ошибка 1", "Ошибка 2", "Ошибка 3"];

    final possibleWords = allWords.where((w) {
      final val = extractor(w);
      return val != null && val.isNotEmpty && val != correctValue;
    }).toList();

    possibleWords.shuffle(_random);
    
    final wrongValues = possibleWords.take(3).map((w) => extractor(w)!).toSet().toList();
    
    // Fill with random strings if the dictionary is extremely small (e.g. less than 4 words)
    while (wrongValues.length < 3) {
      wrongValues.add('Случайный вариант ${_random.nextInt(100)}');
    }

    return wrongValues;
  }
}
