import 'package:flutter_test/flutter_test.dart';
import 'package:quizzer/data/models/word.dart';

void main() {
  test('mastery schedules a review on the next calendar day', () {
    final word = Word()..progress = 5;
    word.beginReviewSchedule(DateTime(2026, 10, 31, 23, 59));

    expect(word.nextReviewAt, DateTime.utc(2026, 11, 1));
    expect(word.effectiveNextReviewAt, DateTime(2026, 11, 1));
    expect(word.isReviewDue(DateTime(2026, 10, 31, 23, 59)), isFalse);
    expect(word.isReviewDue(DateTime(2026, 11, 1)), isTrue);
  });

  test('only a due review advances and the next dates use the review day', () {
    final word = Word()..progress = 5;
    word.beginReviewSchedule(DateTime(2026, 10, 1));

    expect(word.advanceReviewIfDue(DateTime(2026, 10, 1)), isFalse);
    expect(word.advanceReviewIfDue(DateTime(2026, 10, 4)), isTrue);
    expect(word.effectiveNextReviewAt, DateTime(2026, 10, 7));
    expect(word.advanceReviewIfDue(DateTime(2026, 10, 4)), isFalse);
    expect(word.advanceReviewIfDue(DateTime(2026, 10, 7)), isTrue);
    expect(word.effectiveNextReviewAt, DateTime(2026, 10, 14));
    expect(word.progress, 5);
  });

  test('reviews continue at the longest interval without lowering mastery', () {
    final word = Word()
      ..progress = 5
      ..reviewIntervalIndex = 6
      ..nextReviewAt = DateTime.utc(2026, 4, 1);

    expect(word.advanceReviewIfDue(DateTime(2026, 4, 1)), isTrue);
    expect(word.effectiveNextReviewAt, DateTime(2026, 9, 28));
    expect(word.reviewIntervalIndex, 6);
    expect(word.progress, 5);
  });

  test(
    'preserves legacy timing and the attained stage at the first review',
    () {
      final word = Word()
        ..progress = 5
        ..timesLearned = 2
        ..lastTrained = DateTime(2026, 10, 1, 14);

      expect(word.effectiveNextReviewAt, DateTime(2026, 10, 31));
      expect(word.isReviewDue(DateTime(2026, 10, 30, 23)), isFalse);
      expect(word.advanceReviewIfDue(DateTime(2026, 10, 31)), isTrue);
      expect(word.effectiveNextReviewAt, DateTime(2027, 1, 29));
    },
  );

  test('legacy manual mastery is eligible and absent history is due now', () {
    final word = Word()
      ..progress = 5
      ..isManuallyLearned = true
      ..lastTrained = DateTime(2026, 10, 31);

    expect(word.effectiveNextReviewAt, DateTime(2026, 11, 1));
    word.lastTrained = null;
    expect(word.effectiveNextReviewAt, isNull);
    expect(word.isReviewDue(DateTime(2026, 11, 1)), isTrue);
  });

  test('unlearned words stay out of the review queue', () {
    final word = Word()
      ..progress = 4
      ..nextReviewAt = DateTime.utc(2026, 10, 1)
      ..reviewIntervalIndex = 3;

    expect(word.isReviewDue(DateTime(2026, 10, 2)), isFalse);
    expect(word.advanceReviewIfDue(DateTime(2026, 10, 2)), isFalse);
    word.clearReviewSchedule();
    expect(word.nextReviewAt, isNull);
    expect(word.reviewIntervalIndex, isNull);
  });
}
