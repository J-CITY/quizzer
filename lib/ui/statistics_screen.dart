import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import '../data/models/word.dart';
import '../data/models/custom_list.dart';
import '../data/models/training_session.dart';
import '../data/services/database_service.dart';
import '../utils/lottie_color_shift.dart';
import 'custom_list_details_screen.dart';
import 'training_screen.dart';
import '../utils/constants.dart';
import 'widgets/acrylic_card.dart';
import 'dart:math';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _streak = 0;
  List<TrainingSession> _sessions = [];
  List<CustomList> _customLists = [];
  List<Word> _allWords = [];

  bool _isLoading = true;
  bool _showCharts = false;
  String? _modifiedLottieJson;

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseServiceProvider);
    final sessions = await db.getAllTrainingSessions();
    final allWords = await db.getAllWords();
    final customLists = await db.getCustomLists();

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

    Color targetColor = _getColorForStreak(currentStreak);
    String lottieJson = await LottieColorShift.shiftLottieHue(
      'assets/fier.json',
      targetColor,
    );

    if (mounted) {
      setState(() {
        _streak = currentStreak;
        _sessions = sessions;
        _allWords = allWords;
        _customLists = customLists;
        _modifiedLottieJson = lottieJson;
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

  void _startQuickTraining() {
    if (_customLists.isEmpty) return;
    final random = Random();
    final list = _customLists[random.nextInt(_customLists.length)];
    list.words.loadSync();
    final words = list.words.toList();
    if (words.isEmpty) return;

    final unlearned = words.where((w) => w.progress < 5).toList();
    final isLearning = unlearned.isNotEmpty;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TrainingScreen(customListId: list.id, isReviewMode: !isLearning),
      ),
    ).then((_) => _loadData());
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
        swapAnimationDuration: const Duration(milliseconds: 400),
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
        Text('$label: $value', style: const TextStyle(fontSize: 14)),
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
            swapAnimationDuration: const Duration(milliseconds: 400),
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                          if (_modifiedLottieJson != null)
                            Lottie.memory(
                              utf8.encode(_modifiedLottieJson!),
                              repeat: false,
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                            )
                          else
                            const SizedBox(width: 80, height: 80),
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

            // Quick Training Card
            AcrylicCard(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.readyForPractice,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.takeATrainingSession,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).extension<AppColorsExtension>()!.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Theme.of(context)
                                    .extension<AppColorsExtension>()!
                                    .textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.threeMinutes,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .extension<AppColorsExtension>()!
                                      .textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _startQuickTraining,
                      child: Text(
                        AppLocalizations.of(context)!.start,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
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
                list.words.loadSync();
                final listWords = list.words.toList();
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
