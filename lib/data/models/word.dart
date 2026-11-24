import 'package:isar/isar.dart';

part 'word.g.dart';

@collection
class Word {
  static const _reviewIntervals = [1, 3, 7, 14, 30, 90, 180];
  static const _legacyReviewStages = [2, 4, 5, 6];

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

  // UTC midnight encodes a calendar day without a timezone offset.
  DateTime? nextReviewAt;
  int? reviewIntervalIndex;

  int orderIndex = 0;

  int timesLearned = 0; // Tracks how many times progress reached 5

  bool get isLearned => progress >= 5;

  @ignore
  DateTime? get effectiveNextReviewAt {
    if (!isLearned) return null;
    final scheduledDay = nextReviewAt?.toUtc();
    if (scheduledDay != null) {
      return DateTime(scheduledDay.year, scheduledDay.month, scheduledDay.day);
    }
    final trained = lastTrained?.toLocal();
    if (trained == null) return null;
    return DateTime(
      trained.year,
      trained.month,
      trained.day + _reviewIntervals[_effectiveReviewStage],
    );
  }

  bool isReviewDue(DateTime now) {
    if (!isLearned) return false;
    final due = effectiveNextReviewAt;
    return due == null || !due.isAfter(DateTime(now.year, now.month, now.day));
  }

  void beginReviewSchedule(DateTime now) => _scheduleReview(now, 0);

  bool advanceReviewIfDue(DateTime now) {
    if (!isReviewDue(now)) return false;
    final stage = (_effectiveReviewStage + 1).clamp(
      0,
      _reviewIntervals.length - 1,
    );
    _scheduleReview(now, stage);
    return true;
  }

  void clearReviewSchedule() {
    nextReviewAt = null;
    reviewIntervalIndex = null;
  }

  int get _effectiveReviewStage {
    final savedStage = reviewIntervalIndex;
    if (savedStage != null &&
        savedStage >= 0 &&
        savedStage < _reviewIntervals.length) {
      return savedStage;
    }
    if (isManuallyLearned || lastTrained == null) return 0;
    final legacyIndex = timesLearned.clamp(1, _legacyReviewStages.length) - 1;
    return _legacyReviewStages[legacyIndex];
  }

  void _scheduleReview(DateTime now, int stage) {
    reviewIntervalIndex = stage;
    nextReviewAt = DateTime.utc(
      now.year,
      now.month,
      now.day + _reviewIntervals[stage],
    );
  }
}
