import 'package:isar/isar.dart';

part 'rush_session.g.dart';

@collection
class RushSession {
  static const defaultErrorLimit = 3;
  static const maxErrorLimit = 99;

  Id id = Isar.autoIncrement;

  @Index()
  int? customListId;

  late DateTime date;
  late int correctAnswers;
  late int answeredQuestions;
  late int totalWords;
  late int errorLimit;

  static int? parseErrorLimit(Object? value) {
    if (value is int && value >= 0 && value <= maxErrorLimit) return value;
    return null;
  }
}
