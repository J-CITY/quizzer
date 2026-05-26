import 'package:isar/isar.dart';
import 'word.dart';

part 'custom_list.g.dart';

@collection
class CustomList {
  Id id = Isar.autoIncrement;

  late String name;

  String? googleSheetId;

  bool syncOnStartup = false;

  final words = IsarLinks<Word>();
}
