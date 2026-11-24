import '../data/models/custom_list.dart';
import '../data/models/settings.dart';
import '../data/models/word.dart';
import 'training_engine.dart';

enum QuickTrainingMode { scheduledReview, study, freeReview }

typedef QuickTrainingList = ({CustomList list, List<Word> words});

class QuickTrainingPlan {
  final CustomList list;
  final QuickTrainingMode mode;
  final List<int>? reviewWordIds;
  final int dueWordCount;
  final List<QuickTrainingList> dueLists;

  const QuickTrainingPlan({
    required this.list,
    required this.mode,
    this.reviewWordIds,
    this.dueWordCount = 0,
    this.dueLists = const [],
  });
}

QuickTrainingPlan? planQuickTraining(
  Iterable<QuickTrainingList> lists,
  Settings settings,
  DateTime now,
) {
  final available = lists.where((item) => item.words.isNotEmpty).toList()
    ..sort((a, b) => _compareLists(a.list, b.list));
  if (available.isEmpty) return null;

  final dueIds = <int>{};
  final scheduled = <QuickTrainingList>[];
  for (final item in available) {
    final dueWords = TrainingEngine.dueReviewWords(item.words, now);
    if (dueWords.isEmpty) continue;
    dueIds.addAll(dueWords.map((word) => word.id));
    scheduled.add((list: item.list, words: dueWords));
  }

  if (scheduled.isNotEmpty) {
    scheduled.sort((a, b) {
      final oldestFirst = _compareReviewDates(a.words.first, b.words.first);
      if (oldestFirst != 0) return oldestFirst;
      final largestFirst = b.words.length.compareTo(a.words.length);
      return largestFirst != 0 ? largestFirst : _compareLists(a.list, b.list);
    });
    final selected = scheduled.first;
    final limit = TrainingEngine.sessionQuestionLimit(settings, selected.list);
    return QuickTrainingPlan(
      list: selected.list,
      mode: QuickTrainingMode.scheduledReview,
      reviewWordIds: selected.words.take(limit).map((word) => word.id).toList(),
      dueWordCount: dueIds.length,
      dueLists: List.unmodifiable(scheduled),
    );
  }

  for (final item in available) {
    if (item.words.any((word) => !word.isLearned)) {
      return QuickTrainingPlan(list: item.list, mode: QuickTrainingMode.study);
    }
  }

  return QuickTrainingPlan(
    list: available.first.list,
    mode: QuickTrainingMode.freeReview,
  );
}

int _compareLists(CustomList a, CustomList b) {
  if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
  final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  return byName != 0 ? byName : a.id.compareTo(b.id);
}

int _compareReviewDates(Word a, Word b) {
  final first = a.effectiveNextReviewAt;
  final second = b.effectiveNextReviewAt;
  if (first == null) return second == null ? 0 : -1;
  if (second == null) return 1;
  return first.compareTo(second);
}
