import 'package:flutter/material.dart';
import 'package:quizzer/l10n/app_localizations.dart';

import '../../domain/training_engine.dart';

String practiceSkillLabel(AppLocalizations l10n, PracticeSkill skill) =>
    switch (skill) {
      PracticeSkill.translation => l10n.trainingSkillTranslation,
      PracticeSkill.listening => l10n.trainingSkillListening,
      PracticeSkill.writing => l10n.trainingSkillWriting,
    };

class TrainingSkillBreakdown extends StatelessWidget {
  final Map<PracticeSkill, SkillPracticeResult> skills;
  final void Function(PracticeSkill skill, List<int> wordIds)? onPractice;

  const TrainingSkillBreakdown({
    super.key,
    required this.skills,
    this.onPractice,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.trainingSkillsTitle,
            style: theme.textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        for (final skill in PracticeSkill.values)
          _SkillRow(
            skill: skill,
            result: skills[skill]!,
            onPractice: onPractice,
          ),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  final PracticeSkill skill;
  final SkillPracticeResult result;
  final void Function(PracticeSkill skill, List<int> wordIds)? onPractice;

  const _SkillRow({
    required this.skill,
    required this.result,
    required this.onPractice,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final icon = switch (skill) {
      PracticeSkill.translation => Icons.translate,
      PracticeSkill.listening => Icons.headphones_outlined,
      PracticeSkill.writing => Icons.edit_outlined,
    };
    final practiceLabel = switch (skill) {
      PracticeSkill.translation => l10n.trainingPracticeTranslation,
      PracticeSkill.listening => l10n.trainingPracticeListening,
      PracticeSkill.writing => l10n.trainingPracticeWriting,
    };
    final details = [
      if (result.assisted > 0) l10n.trainingSkillAssisted(result.assisted),
      if (result.incorrect > 0) l10n.trainingSkillIncorrect(result.incorrect),
    ];

    return Card(
      color: colors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    practiceSkillLabel(l10n, skill),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              result.total == 0
                  ? l10n.trainingSkillNotPracticed
                  : l10n.trainingSkillIndependent(
                      result.independent,
                      result.total,
                    ),
              style: theme.textTheme.bodyMedium,
            ),
            if (result.total > 0) ...[
              const SizedBox(height: 8),
              ExcludeSemantics(
                child: LinearProgressIndicator(
                  value: result.independent / result.total,
                  backgroundColor: colors.onSurface.withValues(alpha: 0.13),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
            if (details.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (final detail in details)
                    Text(
                      detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
            if (onPractice != null && result.practiceWordIds.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => onPractice!(skill, result.practiceWordIds),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(practiceLabel),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
