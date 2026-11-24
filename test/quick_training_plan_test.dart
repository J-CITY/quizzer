import 'package:flutter_test/flutter_test.dart';
import 'package:quizzer/data/models/custom_list.dart';
import 'package:quizzer/data/models/settings.dart';
import 'package:quizzer/data/models/word.dart';
import 'package:quizzer/domain/quick_training_plan.dart';

void main() {
  final now = DateTime(2026, 5, 1);

  Word due(int id, {int daysAgo = 0}) => Word()
    ..id = id
    ..progress = 5
    ..nextReviewAt = DateTime.utc(now.year, now.month, now.day - daysAgo);

  CustomList list(int id, String name, {bool pinned = false}) => CustomList()
    ..id = id
    ..name = name
    ..isPinned = pinned;

  test(
    'plans the oldest due list with its cap and deduplicates the backlog',
    () {
      final earlier = list(1, 'Earliest')
        ..useCustomTrainingSettings = true
        ..questionsCount = 1;
      final pinned = list(2, 'Pinned', pinned: true);
      final shared = due(3);
      final plan = planQuickTraining(
        [
          (list: pinned, words: [shared, due(2)]),
          (list: earlier, words: [shared, due(1, daysAgo: 4)]),
        ],
        Settings(),
        now,
      );

      expect(plan?.list.id, earlier.id);
      expect(plan?.mode, QuickTrainingMode.scheduledReview);
      expect(plan?.reviewWordIds, [1]);
      expect(plan?.dueWordCount, 3);
      expect(plan?.dueLists.map((entry) => entry.list.id), [
        earlier.id,
        pinned.id,
      ]);
      expect(plan?.dueLists.first.words.map((word) => word.id), [1, 3]);
    },
  );

  test('breaks ties predictably regardless of list iteration order', () {
    final first = (list: list(1, 'First'), words: [due(1)]);
    final pinned = (list: list(2, 'Second', pinned: true), words: [due(2)]);

    for (final source in [
      [first, pinned],
      [pinned, first],
    ]) {
      final plan = planQuickTraining(source, Settings(), now);
      expect(plan?.list.id, pinned.list.id);
      expect(plan?.reviewWordIds, [2]);
    }
  });

  test('offers studying, then free review when everything is mastered', () {
    final mastered = due(1)..nextReviewAt = DateTime.utc(2026, 5, 2);
    final sources = [
      (list: list(1, 'Mastered', pinned: true), words: [mastered]),
      (list: list(2, 'Mixed'), words: [Word()..id = 2]),
    ];

    final study = planQuickTraining(sources, Settings(), now);
    expect(study?.list.id, 2);
    expect(study?.mode, QuickTrainingMode.study);

    final free = planQuickTraining([sources.first], Settings(), now);
    expect(free?.list.id, 1);
    expect(free?.mode, QuickTrainingMode.freeReview);
    expect(free?.reviewWordIds, isNull);
  });

  test('ignores empty lists when suggesting training', () {
    final empty = (list: list(1, 'Empty'), words: <Word>[]);

    expect(planQuickTraining([empty], Settings(), now), isNull);
  });
}
