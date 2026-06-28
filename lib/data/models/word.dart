import 'package:isar/isar.dart';

part 'word.g.dart';

@collection
class Word {
  Id id = Isar.autoIncrement;

  @Index()
  late int sheetId; // ID from the Google Sheet column

  late String japanese;

  String? reading; // Hiragana / Katakana

  late String translation;

  String? imageUrl;

  String? mnemonic;

  int progress = 0; // 0 to 5

  bool isManuallyLearned = false;

  DateTime? lastTrained;

  int orderIndex = 0;

  int timesLearned = 0; // Tracks how many times progress reached 5

  bool get isLearned => progress >= 5;
}
