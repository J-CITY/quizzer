import 'package:isar/isar.dart';

part 'training_session.g.dart';

@collection
class TrainingSession {
  Id id = Isar.autoIncrement;

  late DateTime date;

  int? customListId;
}
