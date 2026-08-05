import 'word.dart';

class WordProgressChange {
  final Word word;
  final int oldProgress;
  final int newProgress;

  WordProgressChange({
    required this.word,
    required this.oldProgress,
    required this.newProgress,
  });
}
