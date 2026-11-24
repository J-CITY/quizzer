import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import '../data/models/word.dart';
import '../data/models/custom_list.dart';
import '../data/models/settings.dart';
import '../data/models/training_session.dart';
import '../data/services/database_service.dart';
import '../domain/quick_training_plan.dart';
import '../domain/training_engine.dart';
import '../utils/lottie_color_shift.dart';
import 'custom_list_details_screen.dart';
import 'settings_screen.dart';
import 'training_screen.dart';
import '../utils/constants.dart';
import 'widgets/acrylic_card.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with WidgetsBindingObserver {
  int _streak = 0;
  List<TrainingSession> _sessions = [];
  List<CustomList> _customLists = [];
  Map<int, List<Word>> _listWords = {};
  List<Word> _allWords = [];
  int _loadVersion = 0;
  bool? _wasVisible;
  bool _openingTraining = false;

  bool _isLoading = true;
  bool _showCharts = false;
  Future<Uint8List?>? _streakAnimation;

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isVisible = ModalRoute.isCurrentOf(context) ?? true;
    if (_wasVisible == false && isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    }
    _wasVisible = isVisible;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final loadVersion = ++_loadVersion;
    final db = ref.read(databaseServiceProvider);
    final sessions = await db.getAllTrainingSessions();
    final allWords = await db.getAllWords();
    final customLists = await db.getCustomLists();
    await Future.wait(customLists.map((list) => list.words.load()));
    final listWords = {
      for (final list in customLists) list.id: list.words.toList(),
    };

    // Calculate streak
    final uniqueDays = sessions.map((s) => s.date).toSet().toList();
    uniqueDays.sort((a, b) => b.compareTo(a)); // Descending

    int currentStreak = 0;
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    if (uniqueDays.isNotEmpty) {
      DateTime checkDay = uniqueDays.first;
      if (checkDay == today ||
          checkDay == today.subtract(const Duration(days: 1))) {
        currentStreak = 1;
        for (int i = 1; i < uniqueDays.length; i++) {
          final diff = checkDay.difference(uniqueDays[i]).inDays;
          if (diff == 1) {
            currentStreak++;
            checkDay = uniqueDays[i];
          } else {
            break;
          }
        }
      }
    }

    if (mounted && loadVersion == _loadVersion) {
      setState(() {
        final streakColor = _getColorForStreak(currentStreak);
        if (_streakAnimation == null ||
            streakColor != _getColorForStreak(_streak)) {
          _streakAnimation = _loadStreakAnimation(streakColor);
        }
        _streak = currentStreak;
        _sessions = sessions;
        _allWords = allWords;
        _customLists = customLists;
        _listWords = listWords;
        _isLoading = false;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _showCharts = true;
          });
        }
      });
    }
  }

  Future<Uint8List?> _loadStreakAnimation(Color streakColor) async {
    try {
      final json = await LottieColorShift.shiftLottieHue(
        'assets/fier.json',
        streakColor,
      );
      return utf8.encode(json);
    } catch (error) {
      debugPrint('Could not load the streak animation: $error');
      return null;
    }
  }

  Color _getColorForStreak(int streak) {
    if (streak >= 500) return ColorConstants.streakColor500Days;
    if (streak >= 365) return ColorConstants.streakColor365Days;
    if (streak >= 200) return ColorConstants.streakColor200Days;
    if (streak >= 100) return ColorConstants.streakColor100Days;
    if (streak >= 60) return ColorConstants.streakColor60Days;
    if (streak >= 30) return ColorConstants.streakColor30Days;
    if (streak >= 10) return ColorConstants.streakColor10Days;
    if (streak >= 3) return ColorConstants.streakColor3Days;
    return ColorConstants.streakColorDefault;
  }

  void _onMonthChanged(DateTime month) {
    setState(() {
      _selectedMonth = month;
    });
  }

  Future<void> _startQuickTraining(QuickTrainingPlan plan) async {
    if (_openingTraining) return;
    setState(() => _openingTraining = true);
    try {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => TrainingScreen(
            customListId: plan.list.id,
            isReviewMode: plan.mode != QuickTrainingMode.study,
            reviewWordIds: plan.reviewWordIds,
            updateReviewSchedule:
                plan.mode == QuickTrainingMode.scheduledReview,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingTraining = false);
    }
  }

  Iterable<QuickTrainingPlan> _additionalReviews(
    QuickTrainingPlan? first,
    Settings? settings,
  ) sync* {
    final firstWords = first?.reviewWordIds;
    if (first == null ||
        settings == null ||
        firstWords == null ||
        first.dueWordCount <= firstWords.length) {
      return;
    }
    final queuedWordIds = firstWords.toSet();
    for (final entry in first.dueLists.skip(1)) {
      final wordIds = entry.words
          .map((word) => word.id)
          .where((id) => !queuedWordIds.contains(id))
          .take(TrainingEngine.sessionQuestionLimit(settings, entry.list))
          .toList();
      if (wordIds.isEmpty) continue;
      queuedWordIds.addAll(wordIds);
      yield QuickTrainingPlan(
        list: entry.list,
        mode: QuickTrainingMode.scheduledReview,
        reviewWordIds: wordIds,
      );
    }
  }

  Widget _buildTrainingCard({
    required String title,
    String? subtitle,
    String? detail,
    String? buttonLabel,
    VoidCallback? onPressed,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final secondaryText = TextStyle(
      fontSize: 14,
      color: theme.extension<AppColorsExtension>()!.textSecondary,
    );
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: secondaryText),
        ],
        if (detail != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.repeat, size: 16, color: secondaryText.color),
              const SizedBox(width: 4),
              Expanded(child: Text(detail, style: secondaryText)),
            ],
          ),
        ],
      ],
    );
    final button = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(
        buttonLabel ?? l10n.start,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
    return AcrylicCard(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.2),
              Colors.transparent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final enlargedText =
                MediaQuery.textScalerOf(context).scale(14) > 21;
            if (constraints.maxWidth < 230 || enlargedText) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [text, const SizedBox(height: 12), button],
              );
            }
            return Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: 16),
                button,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final daysInMonth = DateUtils.getDaysInMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    // Count sessions per day in the selected month
    final sessionCounts = List<int>.filled(daysInMonth, 0);
    for (var s in _sessions) {
      if (s.date.year == _selectedMonth.year &&
          s.date.month == _selectedMonth.month) {
        sessionCounts[s.date.day - 1]++;
      }
    }

    double maxY = 0;
    for (var count in sessionCounts) {
      if (count > maxY) maxY = count.toDouble();
    }
    if (maxY < 5) maxY = 5;

    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Theme.of(context).colorScheme.primary,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = group.x + 1;
                final count = rod.toY.toInt();
                return BarTooltipItem(
                  AppLocalizations.of(
                    context,
                  )!.statisticsTooltip(day.toString(), count.toString()),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt() + 1;
                  if (day % 5 == 0 || day == 1 || day == daysInMonth) {
                    return Text(day.toString(), style: TextStyle(fontSize: 10));
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value == value.toInt()) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(fontSize: 10),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(daysInMonth, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _showCharts ? sessionCounts[i].toDouble() : 0,
                  color: Theme.of(
                    context,
                  ).extension<AppColorsExtension>()!.chart,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text('$label: $value', style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildPieChart(
    String title,
    int learned,
    int inProgress,
    int total, {
    VoidCallback? onTap,
    bool showLegend = false,
    bool wrapInCard = true,
  }) {
    final int unlearned = total - learned - inProgress;

    final double learnedPercent = total == 0 ? 0 : (learned / total) * 100;
    final double inProgressPercent = total == 0
        ? 0
        : (inProgress / total) * 100;
    final double unlearnedPercent = total == 0
        ? 100
        : (unlearned / total) * 100;

    final bool allLearned = total > 0 && learned == total;

    final chartWidget = SizedBox(
      height: showLegend ? 100 : null,
      width: showLegend ? 100 : double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: [
                PieChartSectionData(
                  color: Theme.of(
                    context,
                  ).extension<AppColorsExtension>()!.success,
                  value: _showCharts ? learnedPercent : 0,
                  title: '',
                  radius: 14,
                ),
                PieChartSectionData(
                  color: Theme.of(
                    context,
                  ).extension<AppColorsExtension>()!.chart,
                  value: _showCharts ? inProgressPercent : 0,
                  title: '',
                  radius: 14,
                ),
                PieChartSectionData(
                  color: Theme.of(
                    context,
                  ).extension<AppColorsExtension>()!.border,
                  value: _showCharts ? unlearnedPercent : 100,
                  title: '',
                  radius: 10,
                ),
              ],
            ),
            duration: const Duration(milliseconds: 400),
          ),
          if (allLearned)
            Icon(
              Icons.check_circle,
              color: Theme.of(context).extension<AppColorsExtension>()!.success,
              size: 40,
            )
          else
            Text(
              '$learned / $total',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );

    final innerWidget = Padding(
      padding: wrapInCard ? const EdgeInsets.all(12.0) : EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 24,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (showLegend)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                chartWidget,
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendItem(
                      Theme.of(
                        context,
                      ).extension<AppColorsExtension>()!.success,
                      AppLocalizations.of(context)!.learned,
                      learned,
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      Theme.of(context).extension<AppColorsExtension>()!.chart,
                      AppLocalizations.of(context)!.inProgress,
                      inProgress,
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      Theme.of(context).extension<AppColorsExtension>()!.border,
                      AppLocalizations.of(context)!.newWords,
                      unlearned,
                    ),
                  ],
                ),
              ],
            )
          else
            Expanded(child: chartWidget),
        ],
      ),
    );

    if (!wrapInCard) {
      return GestureDetector(onTap: onTap, child: innerWidget);
    }

    return GestureDetector(
      onTap: onTap,
      child: AcrylicCard(margin: EdgeInsets.zero, child: innerWidget),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final now = DateTime.now();
    final settingsState = ref.watch(settingsProvider);
    final settings = settingsState.valueOrNull;
    final plan = settings == null
        ? null
        : planQuickTraining(
            [
              for (final list in _customLists)
                (list: list, words: _listWords[list.id] ?? const <Word>[]),
            ],
            settings,
            now,
          );
    final practiceDetail = switch (plan?.mode) {
      QuickTrainingMode.scheduledReview => l10n.quickTrainingDue(
        plan!.reviewWordIds!.length,
      ),
      QuickTrainingMode.study => l10n.quickTrainingStudy,
      QuickTrainingMode.freeReview => l10n.quickTrainingFreeReview,
      null => null,
    };
    final months = List.generate(12, (i) {
      return DateTime(now.year, now.month - i, 1);
    });

    final int totalWords = _allWords.length;
    final int learnedWords = _allWords.where((w) => w.progress >= 5).length;
    final int inProgressWords = _allWords
        .where((w) => w.progress > 0 && w.progress < 5)
        .length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Lottie Fire & Streak
            AcrylicCard(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FutureBuilder<Uint8List?>(
                            future: _streakAnimation,
                            builder: (context, snapshot) {
                              final bytes = snapshot.data;
                              if (bytes == null) {
                                return SizedBox.square(
                                  dimension: 80,
                                  child: Icon(
                                    Icons.local_fire_department,
                                    size: 48,
                                    color: _getColorForStreak(_streak),
                                  ),
                                );
                              }
                              return Lottie.memory(
                                bytes,
                                repeat: false,
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              );
                            },
                          ),
                          Text(
                            '$_streak',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).extension<AppColorsExtension>()!.textPrimary,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.daysInARow,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).extension<AppColorsExtension>()!.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 140,
                      width: 1,
                      color: Theme.of(context).dividerColor,
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    Expanded(
                      flex: 1,
                      child: _buildPieChart(
                        AppLocalizations.of(context)!.tabAllWords,
                        learnedWords,
                        inProgressWords,
                        totalWords,
                        showLegend: true,
                        wrapInCard: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Bar chart Card
            AcrylicCard(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: months.length,
                        itemBuilder: (context, i) {
                          final m = months[i];
                          final isSelected =
                              m.year == _selectedMonth.year &&
                              m.month == _selectedMonth.month;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: ChoiceChip(
                              label: Text(
                                '${m.month.toString().padLeft(2, '0')}.${m.year}',
                              ),
                              selected: isSelected,
                              onSelected: (val) => _onMonthChanged(m),
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildBarChart(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            _buildTrainingCard(
              title: l10n.readyForPractice,
              subtitle:
                  plan?.list.name ??
                  (settingsState.hasError
                      ? l10n.quickTrainingReload
                      : settings == null
                      ? l10n.takeATrainingSession
                      : l10n.quickTrainingEmpty),
              detail: practiceDetail,
              buttonLabel: settingsState.hasError
                  ? l10n.quickTrainingReload
                  : null,
              onPressed: settingsState.hasError
                  ? () => ref.invalidate(settingsProvider)
                  : plan == null || _openingTraining
                  ? null
                  : () => _startQuickTraining(plan),
            ),
            for (final queued in _additionalReviews(plan, settings))
              _buildTrainingCard(
                title: queued.list.name,
                detail: l10n.quickTrainingDue(queued.reviewWordIds!.length),
                onPressed: _openingTraining
                    ? null
                    : () => _startQuickTraining(queued),
              ),
            const SizedBox(height: 16),

            // Grid of Custom Lists Pie Charts
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.25,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _customLists.length,
              itemBuilder: (context, i) {
                final list = _customLists[i];
                final listWords = _listWords[list.id] ?? const <Word>[];
                final listLearned = listWords
                    .where((w) => w.progress >= 5)
                    .length;
                final listInProgress = listWords
                    .where((w) => w.progress > 0 && w.progress < 5)
                    .length;
                return _buildPieChart(
                  list.name,
                  listLearned,
                  listInProgress,
                  listWords.length,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomListDetailsScreen(customList: list),
                      ),
                    ).then((_) {
                      _loadData();
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
