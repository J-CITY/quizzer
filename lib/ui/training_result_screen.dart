import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizzer/l10n/app_localizations.dart';

import '../data/models/word.dart';
import '../data/models/word_progress_change.dart';
import '../data/services/database_service.dart';
import '../domain/training_engine.dart';
import '../main.dart';
import 'training_screen.dart';
import 'widgets/training_skill_breakdown.dart';

class TrainingResultScreen extends ConsumerStatefulWidget {
  final int? customListId;
  final List<Word> mistakes;
  final List<WordProgressChange> progressChanges;
  final Map<PracticeSkill, SkillPracticeResult> skills;
  final bool isReviewMode;
  final int scheduledReviewCount;
  final int advancedReviewCount;

  const TrainingResultScreen({
    super.key,
    this.customListId,
    required this.mistakes,
    this.progressChanges = const [],
    required this.skills,
    this.isReviewMode = false,
    this.scheduledReviewCount = 0,
    this.advancedReviewCount = 0,
  });

  @override
  ConsumerState<TrainingResultScreen> createState() =>
      _TrainingResultScreenState();
}

class _TrainingResultScreenState extends ConsumerState<TrainingResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(adsServiceProvider).showInterstitialAd();
      if (widget.mistakes.isNotEmpty ||
          widget.skills.values.any((result) => result.assisted > 0)) {
        return;
      }
      final settings = await ref.read(databaseServiceProvider).getSettings();
      if (mounted && settings.hapticFeedbackEnabled) {
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _practiceWords(List<int> wordIds, {PracticeSkill? skill}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TrainingScreen.practice(
          customListId: widget.customListId,
          wordIds: wordIds,
          skill: skill,
        ),
      ),
    );
  }

  void _showProgressDialog() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              l10n.progressChangesTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(l10n.trainingStudyScoringGuide),
            for (final change in widget.progressChanges)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(change.word.japanese),
                subtitle: Text(change.word.translation),
                trailing: Text(
                  l10n.trainingWordLevelChange(
                    change.oldProgress,
                    change.newProgress,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final raised = widget.progressChanges
        .where((change) => change.newProgress > change.oldProgress)
        .length;
    final lowered = widget.progressChanges
        .where((change) => change.newProgress < change.oldProgress)
        .length;
    final unchanged = widget.progressChanges.length - raised - lowered;
    final isScheduledReview = widget.scheduledReviewCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isReviewMode
              ? l10n.trainingReviewResultsTitle
              : l10n.trainingResultsTitle,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                TrainingSkillBreakdown(
                  skills: widget.skills,
                  onPractice: (skill, wordIds) =>
                      _practiceWords(wordIds, skill: skill),
                ),
                if (widget.mistakes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () => _practiceWords([
                      for (final word in widget.mistakes) word.id,
                    ]),
                    icon: const Icon(Icons.replay),
                    label: Text(l10n.trainingPracticeMistakes),
                  ),
                ],
                const SizedBox(height: 12),
                Card(
                  color: theme.colorScheme.surface,
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isReviewMode
                              ? (isScheduledReview
                                    ? l10n.trainingReviewSchedulesAdvanced(
                                        widget.advancedReviewCount,
                                        widget.scheduledReviewCount,
                                      )
                                    : l10n.trainingFreeReview)
                              : l10n.trainingStudyLevels,
                          style: theme.textTheme.titleLarge,
                        ),
                        if (!widget.isReviewMode) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.trainingStudyLevelSummary(
                              raised,
                              unchanged,
                              lowered,
                            ),
                          ),
                        ],
                        if (isScheduledReview &&
                            widget.advancedReviewCount <
                                widget.scheduledReviewCount) ...[
                          const SizedBox(height: 8),
                          Text(l10n.trainingReviewStillDue),
                        ],
                        if (!widget.isReviewMode) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _showProgressDialog,
                            icon: const Icon(Icons.stacked_bar_chart),
                            label: Text(l10n.progressChangesTitle),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (widget.mistakes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.trainingMistakesTitle(widget.mistakes.length),
                    style: theme.textTheme.titleLarge,
                  ),
                  for (final word in widget.mistakes)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(word.japanese),
                      subtitle: Text(
                        [
                          if (word.reading?.trim().isNotEmpty ?? false)
                            word.reading!,
                          word.translation,
                        ].join(' · '),
                      ),
                      trailing: IconButton(
                        tooltip: l10n.playWord,
                        icon: const Icon(Icons.volume_up),
                        onPressed: () => ref
                            .read(ttsProvider)
                            .speak(
                              (word.reading?.trim().isNotEmpty ?? false)
                                  ? word.reading!
                                  : word.japanese,
                            ),
                      ),
                    ),
                ] else
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(l10n.trainingNoMistakes),
                  ),
                TextButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: Text(l10n.close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
