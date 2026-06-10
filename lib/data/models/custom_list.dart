import 'package:isar/isar.dart';
import 'word.dart';

part 'custom_list.g.dart';

@collection
class CustomList {
  Id id = Isar.autoIncrement;

  late String name;

  String? googleSheetId;
  String? googleSheetTabName;

  String language = 'ja-JP';

  String? emoji;

  bool syncOnStartup = false;
  
  bool isPinned = false;

  final words = IsarLinks<Word>();
  
  final learningQueue = IsarLinks<Word>();

  bool useCustomQuestionSettings = false;

  bool questionWordToTranslate = true;
  bool questionTranslateToWord = true;
  bool questionWordToReading = true;
  bool questionReadingToWord = true;

  bool questionVoiceToTranslate = true;
  bool questionVoiceToWord = true;
  bool questionVoiceToWordInput = true;
  bool questionVoiceToWordConstructor = true;
  bool questionTranslateToWordInput = true;
  bool questionTranslateToWordConstructor = true;
  bool questionImageToWord = true;
}
