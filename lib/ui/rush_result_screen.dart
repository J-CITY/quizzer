import 'package:flutter/material.dart';
import 'package:quizzer/l10n/app_localizations.dart';

import '../data/models/rush_session.dart';
import '../data/models/word.dart';
import '../domain/training_engine.dart';
import 'training_screen.dart';
import 'widgets/training_skill_breakdown.dart';

class RushResultScreen extends StatelessWidget {
  final RushSession result;
  final String listName;
  final List<Word> missedWords;
  final Map<PracticeSkill, SkillPracticeResult> skills;

  const RushResultScreen({
    super.key,
    required this.result,
    required this.listName,
    required this.missedWords,
    required this.skills,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final completedList = result.answeredQuestions == result.totalWords;
    final errors = result.answeredQuestions - result.correctAnswers;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rushMode)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Card(
                  color: colors.surface,
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          completedList ? Icons.flag_outlined : Icons.bolt,
                          size: 32,
                          color: colors.onSecondaryContainer,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          completedList
                              ? l10n.rushResultListCompleted
                              : l10n.rushResultLimitReached,
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        Text(listName, textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        Text(
                          l10n.rushResultCorrect(
                            result.correctAnswers,
                            result.answeredQuestions,
                          ),
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.rushResultWordsSeen(
                            result.answeredQuestions,
                            result.totalWords,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          l10n.rushResultErrors(errors),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (result.customListId != null)
                  FilledButton.icon(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => TrainingScreen(
                          customListId: result.customListId,
                          rushErrorLimit: result.errorLimit,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.replay),
                    label: Text(l10n.rushResultReplay),
                  ),
                const SizedBox(height: 16),
                TrainingSkillBreakdown(
                  skills: skills,
                  onPractice: result.customListId == null
                      ? null
                      : (skill, wordIds) => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => TrainingScreen.practice(
                              customListId: result.customListId,
                              wordIds: wordIds,
                              skill: skill,
                            ),
                          ),
                        ),
                ),
                if (missedWords.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.rushResultMissedWords,
                    style: theme.textTheme.titleLarge,
                  ),
                  for (final word in missedWords)
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
                    ),
                ],
                TextButton(
                  onPressed: () => Navigator.pop(context),
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
