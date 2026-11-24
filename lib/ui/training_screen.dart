import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../data/models/word.dart';
import '../data/models/word_progress_change.dart';
import '../data/models/custom_list.dart';
import '../data/models/rush_session.dart';
import '../data/models/settings.dart';
import '../domain/training_engine.dart';
import '../data/services/database_service.dart';
import 'training_result_screen.dart';
import 'rush_result_screen.dart';
import '../utils/constants.dart';
import 'widgets/glow_button.dart';
import 'widgets/training_skill_breakdown.dart';
import 'widgets/word_image.dart';

final ttsProvider = Provider<FlutterTts>((ref) {
  final tts = FlutterTts();
  tts.setLanguage("ja-JP");
  tts.awaitSpeakCompletion(true);
  return tts;
});

class TrainingScreen extends ConsumerStatefulWidget {
  final int? customListId;
  final bool isReviewMode;
  final List<int>? reviewWordIds;
  final PracticeSkill? reviewSkill;
  final bool updateReviewSchedule;
  final int? rushErrorLimit;

  const TrainingScreen({
    super.key,
    this.customListId,
    this.isReviewMode = false,
    this.reviewWordIds,
    this.reviewSkill,
    this.updateReviewSchedule = true,
    this.rushErrorLimit,
  }) : assert(
         rushErrorLimit == null || (customListId != null && !isReviewMode),
       ),
       assert(reviewWordIds == null || isReviewMode),
       assert(
         reviewSkill == null ||
             (reviewWordIds != null && !updateReviewSchedule),
       );

  const TrainingScreen.practice({
    Key? key,
    int? customListId,
    required List<int> wordIds,
    PracticeSkill? skill,
  }) : this(
         key: key,
         customListId: customListId,
         isReviewMode: true,
         reviewWordIds: wordIds,
         reviewSkill: skill,
         updateReviewSchedule: false,
       );

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen>
    with TickerProviderStateMixin {
  AudioPlayer? _audioPlayer;
  List<Question> _questions = [];
  Iterator<Question>? _rushQuestions;
  int _currentIndex = 0;
  int _initialQuestionsCount = 0;
  final Set<int> _hintedQuestions = {};
  final Set<int> _wrongQuestions = {};
  final Set<int> _scheduledReviewIds = {};
  final Set<int> _wordsWithUnavailableImage = {};
  Question? _imageReplacement;

  final TextEditingController _textController = TextEditingController();
  final List<int> _selectedCharIndices = [];
  final Set<int> _selectedMultiIndices = {};

  final Map<int, String> _userAnswers = {};

  late final Settings _settings;
  List<Word> _allWords = [];
  CustomList? _customList;
  int _currentTrainingStreak = 0;
  static const int _streakThreshold = 10;

  late final AnimationController _pulseController;

  bool _isLoading = true;
  bool _isFinishing = false;
  bool _confirmingExit = false;

  bool get _isRush => widget.rushErrorLimit != null;
  bool get _rushErrorLimitReached =>
      _isRush &&
      widget.rushErrorLimit! > 0 &&
      _wrongQuestions.length >= widget.rushErrorLimit!;
  bool get _isLastRushQuestion =>
      _isRush &&
      (_rushErrorLimitReached || _currentIndex + 1 == _initialQuestionsCount);

  @override
  void dispose() {
    _pulseController.dispose();
    _audioPlayer?.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initSession();
  }

  Future<void> _initSession() async {
    final db = ref.read(databaseServiceProvider);
    final engine = ref.read(trainingEngineProvider);
    _settings = await db.getSettings();

    List<Word> sourceWords;
    String listLanguage = 'ja-JP';

    if (widget.customListId != null) {
      final lists = await db.getCustomLists();
      final list = lists
          .where((list) => list.id == widget.customListId)
          .firstOrNull;
      if (list == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      _customList = list;
      listLanguage = list.language;
      await list.words.load();
      _allWords = list.words.toList();

      if (!widget.isReviewMode && !_isRush) {
        final queueSize =
            (list.useCustomTrainingSettings && list.learningQueueSize > 0)
            ? list.learningQueueSize
            : _settings.learningQueueSize;
        await db.updateLearningQueue(list, queueSize);
        await list.learningQueue.load();
        sourceWords = list.learningQueue.toList();

        if (sourceWords.isEmpty) {
          sourceWords = _allWords;
        }
      } else {
        sourceWords = _allWords;
      }
    } else {
      _allWords = await db.getAllWords();
      sourceWords = _allWords;
    }

    if (!mounted) return;
    if (!_isRush) {
      await ref.read(ttsProvider).setLanguage(listLanguage);
    }
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    if (_isRush) {
      _initialQuestionsCount = sourceWords.length;
      final questions = engine
          .generateRushSession(
            sourceWords,
            _settings,
            l10n,
            customList: _customList,
          )
          .iterator;
      _rushQuestions = questions;
      if (questions.moveNext()) _questions = [questions.current];
    } else {
      final now = DateTime.now();
      _questions = engine.generateSession(
        sourceWords,
        _allWords,
        _settings,
        l10n,
        isReviewMode: widget.isReviewMode,
        customList: _customList,
        reviewWordIds: widget.reviewWordIds,
        reviewSkill: widget.reviewSkill,
        now: now,
      );
      _initialQuestionsCount = _questions.length;
      if (widget.isReviewMode && widget.updateReviewSchedule) {
        _scheduledReviewIds.addAll(
          _questions
              .where((question) => question.word.isReviewDue(now))
              .map((question) => question.word.id),
        );
      }
    }

    setState(() => _isLoading = false);
    _playVoiceOnAppearIfNeeded();
  }

  void _playVoiceOnAppearIfNeeded() {
    if (_questions.isEmpty || _currentIndex >= _questions.length) return;
    final q = _questions[_currentIndex];
    final bool hasAnswered = _userAnswers.containsKey(_currentIndex);

    if (q.isVoice ||
        (_settings.autoPlayVoice &&
            (hasAnswered || (!_isRush && _canPlaySupplementaryVoice(q))))) {
      _playVoice();
    }
  }

  bool _canPlaySupplementaryVoice(Question question) =>
      !question.isVoice &&
      question.type != QuestionType.transToJap &&
      question.type != QuestionType.transToJapInput &&
      question.type != QuestionType.transToJapConstructor &&
      question.type != QuestionType.imageToJap &&
      question.type != QuestionType.japToReading;

  Future<void> _playVoice() async {
    if (_questions.isEmpty || _currentIndex >= _questions.length) return;
    final q = _questions[_currentIndex];

    final textToSpeak = (q.word.reading != null && q.word.reading!.isNotEmpty)
        ? q.word.reading!
        : q.word.japanese;

    try {
      final tts = ref.read(ttsProvider);
      if (!Platform.isWindows) {
        await tts.stop();
      }
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted && !_isFinishing && _questions[_currentIndex] == q) {
        await tts.speak(textToSpeak);
      }
    } on Exception catch (error) {
      debugPrint('Unable to play the answer: $error');
    }
  }

  Future<void> _onOptionSelected(String option) async {
    if (_isFinishing || _userAnswers.containsKey(_currentIndex)) return;

    final answeredIndex = _currentIndex;
    final question = _questions[answeredIndex];
    final isCorrect = question.acceptsAnswer(option);

    setState(() {
      _userAnswers[answeredIndex] = option;
      if (!isCorrect) {
        _wrongQuestions.add(answeredIndex);
        if (!_isRush &&
            !widget.isReviewMode &&
            answeredIndex < _initialQuestionsCount) {
          // One practice retry for each missed scored question.
          _questions.add(
            ref
                .read(trainingEngineProvider)
                .regenerateQuestionOptions(
                  question,
                  _allWords,
                  _settings,
                  AppLocalizations.of(context)!,
                  _customList,
                ),
          );
        }
      }
      if (!_isRush) {
        _updateAnswerStreak(
          isCorrect && !_hintedQuestions.contains(answeredIndex),
        );
      }
    });

    if (_settings.playSoundEffects) {
      try {
        final player = _audioPlayer ??= AudioPlayer();
        await player.stop();
        await player.play(
          AssetSource(isCorrect ? 'sounds/true.mp3' : 'sounds/false.mp3'),
        );
      } on Exception catch (error) {
        debugPrint('Unable to play answer feedback: $error');
      }
    }

    final shouldPlayVoice = !_isRush && _settings.autoPlayVoice;
    if (shouldPlayVoice) {
      if (_settings.playSoundEffects) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      if (!mounted || _currentIndex != answeredIndex || _isFinishing) return;
      await _playVoice();
    }
    if (!_settings.autoAdvanceToNextQuestion) return;
    await Future.delayed(
      shouldPlayVoice
          ? AppConstants.audioAdvanceDelay
          : const Duration(seconds: 1),
    );
    if (mounted && _currentIndex == answeredIndex && !_confirmingExit) {
      _goForward();
    }
  }

  void _updateAnswerStreak(bool recalledUnaided) {
    if (!recalledUnaided) {
      if (_currentTrainingStreak >= _streakThreshold) {
        _pulseController.reset();
        if (_settings.hapticFeedbackEnabled) HapticFeedback.heavyImpact();
      }
      _currentTrainingStreak = 0;
      return;
    }

    _currentTrainingStreak++;
    if (_currentTrainingStreak < _streakThreshold) return;
    _pulseController.forward(from: 0).then((_) {
      if (mounted) _pulseController.reverse();
    });
    if (_settings.hapticFeedbackEnabled) {
      if (_currentTrainingStreak == _streakThreshold) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _goForward() {
    if (_isFinishing || !_userAnswers.containsKey(_currentIndex)) return;

    if (_isRush && !_isLastRushQuestion && _rushQuestions!.moveNext()) {
      _questions.add(_rushQuestions!.current);
    }

    if (_isLastRushQuestion || _currentIndex + 1 == _questions.length) {
      _finishTraining();
      return;
    }

    _clearAnswerControls();
    setState(() => _currentIndex++);
    _playVoiceOnAppearIfNeeded();
  }

  void _goBack() {
    if (_isRush || _isFinishing || _currentIndex == 0) return;
    _clearAnswerControls();
    setState(() => _currentIndex--);
    _playVoiceOnAppearIfNeeded();
  }

  void _clearAnswerControls() {
    _textController.clear();
    _selectedCharIndices.clear();
    _selectedMultiIndices.clear();
  }

  Future<void> _finishTraining() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    try {
      if (_isRush) {
        await _finishRush();
      } else {
        await _finishStudyOrReview();
      }
    } on Exception catch (error) {
      debugPrint('Unable to save the training session: $error');
      if (!mounted) return;
      setState(() => _isFinishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.trainingSaveFailed),
        ),
      );
    }
  }

  Future<void> _finishRush() async {
    final skills = summarizePracticeSkills(_firstAttemptsByWord());
    final result = RushSession()
      ..date = DateTime.now()
      ..customListId = widget.customListId
      ..correctAnswers = _userAnswers.length - _wrongQuestions.length
      ..answeredQuestions = _userAnswers.length
      ..totalWords = _initialQuestionsCount
      ..errorLimit = widget.rushErrorLimit!;
    await ref.read(databaseServiceProvider).saveRushSession(result);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RushResultScreen(
          result: result,
          listName: _customList!.name,
          skills: skills,
          missedWords: [
            for (final index in _wrongQuestions) _questions[index].word,
          ],
        ),
      ),
    );
  }

  Map<int, List<PracticeAttempt>> _firstAttemptsByWord() {
    final attempts = <int, List<PracticeAttempt>>{};
    for (
      var index = 0;
      index < _questions.length && index < _initialQuestionsCount;
      index++
    ) {
      if (!_userAnswers.containsKey(index)) continue;
      final question = _questions[index];
      final answer = _wrongQuestions.contains(index)
          ? PracticeAnswer.incorrect
          : _hintedQuestions.contains(index)
          ? PracticeAnswer.assisted
          : PracticeAnswer.independent;
      attempts.putIfAbsent(question.word.id, () => []).add((
        questionType: question.type,
        answer: answer,
      ));
    }
    return attempts;
  }

  Future<void> _finishStudyOrReview() async {
    final db = ref.read(databaseServiceProvider);
    final allWords = await db.getAllWords();
    final wordsMap = {for (final word in allWords) word.id: word};
    final mistakes = <Word>[];
    final progressChanges = <WordProgressChange>[];
    final attemptsByWord = _firstAttemptsByWord();
    final independentlyRecalledReviewIds = <int>{};

    for (final entry in attemptsByWord.entries) {
      if (_scheduledReviewIds.contains(entry.key) &&
          entry.value.any(
            (attempt) => attempt.answer == PracticeAnswer.independent,
          )) {
        independentlyRecalledReviewIds.add(entry.key);
      }
      final word = wordsMap[entry.key];
      if (word == null) continue;

      if (entry.value.any(
        (attempt) => attempt.answer == PracticeAnswer.incorrect,
      )) {
        mistakes.add(word);
      }
      if (widget.isReviewMode) continue;

      final oldProgress = word.progress;
      final newProgress = learningProgressAfterSession(
        oldProgress,
        entry.value,
      );
      progressChanges.add(
        WordProgressChange(
          word: word,
          oldProgress: oldProgress,
          newProgress: newProgress,
        ),
      );
    }

    final advancedReviewCount = await db.saveTrainingSession(
      widget.customListId,
      progressChanges: progressChanges,
      independentlyRecalledReviewIds: independentlyRecalledReviewIds,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TrainingResultScreen(
          customListId: widget.customListId,
          mistakes: mistakes,
          progressChanges: progressChanges,
          skills: summarizePracticeSkills(attemptsByWord),
          isReviewMode: widget.isReviewMode,
          scheduledReviewCount: _scheduledReviewIds.length,
          advancedReviewCount: advancedReviewCount,
        ),
      ),
    );
  }

  void _handleUnavailableImage(Question question) {
    if (!mounted || _questions[_currentIndex] != question) return;
    final alreadyAnswered = _userAnswers.containsKey(_currentIndex);
    final canReplace =
        question.type == QuestionType.imageToJap && !alreadyAnswered;
    if (!canReplace) return;

    final l10n = AppLocalizations.of(context)!;
    final replacement = ref
        .read(trainingEngineProvider)
        .replaceUnavailableImageQuestion(
          question,
          _allWords,
          _settings,
          l10n,
          _customList,
        );
    _clearAnswerControls();
    setState(() {
      _wordsWithUnavailableImage.add(question.word.id);
      _questions[_currentIndex] = replacement;
      _imageReplacement = replacement;
    });
    _playVoiceOnAppearIfNeeded();
  }

  Future<void> _showHint(Question question, QuestionHint hint) async {
    if (_userAnswers.containsKey(_currentIndex)) return;
    setState(() {
      _hintedQuestions.add(_currentIndex);
      if (hint.kind == QuestionHintKind.hideOption) {
        _selectedMultiIndices.remove(question.options.indexOf(hint.value));
      }
    });

    final l10n = AppLocalizations.of(context)!;
    final message = switch (hint.kind) {
      QuestionHintKind.mnemonic => hint.value,
      QuestionHintKind.firstCharacter => l10n.trainingHintFirstCharacter(
        hint.value,
      ),
      QuestionHintKind.hideOption => l10n.trainingHintOptionRemoved,
    };
    final effect = !widget.isReviewMode
        ? l10n.trainingHintLearningEffect
        : _scheduledReviewIds.contains(question.word.id)
        ? l10n.trainingHintReviewEffect
        : null;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lightbulb_outline),
        title: Text(l10n.trainingHint),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (effect != null) ...[
              const SizedBox(height: 12),
              Text(effect, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
        scrollable: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  String? _hiddenOption(Question question) {
    if (!_hintedQuestions.contains(_currentIndex)) return null;
    final hint = question.hint;
    return hint?.kind == QuestionHintKind.hideOption ? hint!.value : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(AppLocalizations.of(context)!.noWordsForTraining),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final q = _questions[_currentIndex];
    final isRetry = _currentIndex >= _initialQuestionsCount;
    final progressText = isRetry
        ? l10n.trainingRetryProgress(
            _currentIndex - _initialQuestionsCount + 1,
            _questions.length - _initialQuestionsCount,
          )
        : '${_currentIndex + 1} / $_initialQuestionsCount';
    final hasAnswered = _userAnswers.containsKey(_currentIndex);
    final selectedOption = _userAnswers[_currentIndex];
    final hintUsed = _hintedQuestions.contains(_currentIndex);
    final hintsDisabled = widget.isReviewMode
        ? _settings.reviewHintsDisabled
        : _settings.learningHintsDisabled;
    final hint = _isRush || hasAnswered || hintsDisabled ? null : q.hint;
    final reviewSkill = widget.reviewSkill;
    final modeLabel = reviewSkill != null
        ? practiceSkillLabel(l10n, reviewSkill)
        : !widget.isReviewMode
        ? l10n.trainingStudyMode
        : !widget.updateReviewSchedule
        ? l10n.trainingMistakesMode
        : _scheduledReviewIds.isNotEmpty
        ? l10n.trainingScheduledReviewMode
        : l10n.trainingReviewMode;

    bool showTranslation = false;
    String mainText = q.prompt;
    String? subText = _isRush ? null : q.subtitle;

    if (hasAnswered) {
      mainText = q.word.japanese;
      subText = q.word.reading;
      showTranslation = true;
    }

    bool showImage = false;
    if (!_isRush &&
        q.word.imageUrl != null &&
        q.word.imageUrl!.isNotEmpty &&
        (q.type == QuestionType.imageToJap ||
            !_wordsWithUnavailableImage.contains(q.word.id))) {
      if (hasAnswered) {
        showImage = true;
      } else if (q.type == QuestionType.imageToJap) {
        showImage = true;
      } else if (q.type == QuestionType.transToJap ||
          q.type == QuestionType.transToJapInput ||
          q.type == QuestionType.transToJapConstructor ||
          q.type == QuestionType.japToReading ||
          q.type == QuestionType.readingToJap) {
        showImage = true;
      }
    }

    final primaryColor = Theme.of(context).colorScheme.primary;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final extraToolbarHeight = MediaQuery.textScalerOf(context).scale(36) - 36;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _isFinishing || _confirmingExit) return;

        _confirmingExit = true;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.finishTrainingTitle),
            content: Text(AppLocalizations.of(context)!.finishTrainingDesc),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  AppLocalizations.of(context)!.exit,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        );

        _confirmingExit = false;
        if (shouldPop ?? false) {
          if (context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          toolbarHeight: _isRush
              ? kToolbarHeight + extraToolbarHeight.clamp(0.0, 72.0)
              : null,
          title: _isRush
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.rushResultInProgress(progressText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.rushErrorLimit == 0
                          ? l10n.rushResultErrors(_wrongQuestions.length)
                          : l10n.rushResultErrorsWithLimit(
                              _wrongQuestions.length,
                              widget.rushErrorLimit!,
                            ),
                      style: Theme.of(context).textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : Text(
                  isRetry
                      ? progressText
                      : l10n.trainingModeWithProgress(modeLabel, progressText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          actions: [
            if (hint != null)
              IconButton(
                tooltip: hintUsed ? l10n.trainingHintUsed : l10n.trainingHint,
                onPressed: () => _showHint(q, hint),
                icon: Icon(
                  hintUsed ? Icons.lightbulb : Icons.lightbulb_outline,
                ),
              ),
          ],
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -300) {
              _goForward();
            } else if (details.primaryVelocity! > 300 && !_isRush) {
              _goBack();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (q == _imageReplacement)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        l10n.trainingImageQuestionReplaced,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
                if (!isKeyboardOpen) ...[
                  Expanded(
                    flex: 2,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final isStreakActive =
                            _currentTrainingStreak >= _streakThreshold;
                        final glowColor = isStreakActive
                            ? Colors.red
                            : primaryColor;
                        final pulseValue = _pulseController.value;
                        final baseAlphaTop = isStreakActive
                            ? 0.4 + (pulseValue * 0.4)
                            : 0.4;
                        final blurTop = isStreakActive
                            ? 30.0 + (pulseValue * 20.0)
                            : 30.0;

                        final baseAlphaCard = isStreakActive
                            ? 0.1 + (pulseValue * 0.2)
                            : 0.1;
                        final blurCard = isStreakActive
                            ? 20.0 + (pulseValue * 15.0)
                            : 20.0;

                        return Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: -5,
                              left: 48,
                              right: 48,
                              child: Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: glowColor.withValues(
                                        alpha: baseAlphaTop,
                                      ),
                                      blurRadius: blurTop,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: glowColor.withValues(
                                      alpha: baseAlphaCard,
                                    ),
                                    blurRadius: blurCard,
                                    offset: Offset.zero,
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                          ],
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.white.withValues(alpha: 0.8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    primaryColor.withValues(alpha: 0.1),
                                    primaryColor.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 0.4],
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (showImage)
                                      Expanded(
                                        flex: 4,
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                          child: WordImage(
                                            key: ValueKey(q),
                                            source: q.word.imageUrl!,
                                            fit: BoxFit.cover,
                                            onLoadError: () =>
                                                _handleUnavailableImage(q),
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      flex: showImage ? 5 : 1,
                                      child: Stack(
                                        children: [
                                          GestureDetector(
                                            onLongPress: mainText.isEmpty
                                                ? null
                                                : () {
                                                    Clipboard.setData(
                                                      ClipboardData(
                                                        text: mainText,
                                                      ),
                                                    );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.copiedToClipboard,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                            child: Center(
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    if (q.isVoice &&
                                                        !hasAnswered)
                                                      Column(
                                                        children: [
                                                          IconButton(
                                                            icon: Icon(
                                                              Icons.volume_up,
                                                              size: showImage
                                                                  ? 56
                                                                  : 80,
                                                              color:
                                                                  primaryColor,
                                                            ),
                                                            onPressed:
                                                                _playVoice,
                                                          ),
                                                          SizedBox(
                                                            height: showImage
                                                                ? 8
                                                                : 16,
                                                          ),
                                                          Text(
                                                            AppLocalizations.of(
                                                              context,
                                                            )!.listenToTheWord,
                                                            style: TextStyle(
                                                              fontSize:
                                                                  showImage
                                                                  ? 18
                                                                  : 24,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    else ...[
                                                      AutoSizeText(
                                                        !hasAnswered &&
                                                                q.type ==
                                                                    QuestionType
                                                                        .imageToJap
                                                            ? l10n.trainingImagePrompt
                                                            : mainText,
                                                        style: TextStyle(
                                                          fontSize: showImage
                                                              ? 32
                                                              : 48,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                        maxLines: 3,
                                                        minFontSize: showImage
                                                            ? 16
                                                            : 24,
                                                      ),
                                                      if (subText != null &&
                                                          subText.isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                top: showImage
                                                                    ? 4.0
                                                                    : 8.0,
                                                              ),
                                                          child: Text(
                                                            subText,
                                                            style: TextStyle(
                                                              fontSize:
                                                                  showImage
                                                                  ? 18
                                                                  : 24,
                                                              color: Theme.of(context)
                                                                  .extension<
                                                                    AppColorsExtension
                                                                  >()!
                                                                  .textSecondary,
                                                            ),
                                                          ),
                                                        ),
                                                      if (showTranslation)
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                top: showImage
                                                                    ? 8.0
                                                                    : 16.0,
                                                              ),
                                                          child: Text(
                                                            q.word.translation,
                                                            style: TextStyle(
                                                              fontSize:
                                                                  showImage
                                                                  ? 16
                                                                  : 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (!_isRush &&
                                              (hasAnswered ||
                                                  _canPlaySupplementaryVoice(
                                                    q,
                                                  )))
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.volume_up,
                                                  size: 32,
                                                  color: primaryColor,
                                                ),
                                                onPressed: _playVoice,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ), // closes ClipRRect
                    ), // closes AnimatedBuilder
                  ), // closes Expanded
                  const SizedBox(height: 24),
                ],
                if (isKeyboardOpen)
                  Expanded(
                    flex: 1,
                    child: Card(
                      elevation: 2,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: !hasAnswered && q.isVoice
                                  ? IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(
                                        Icons.volume_up,
                                        size: 48,
                                        color: primaryColor,
                                      ),
                                      onPressed: _playVoice,
                                    )
                                  : AutoSizeText(
                                      mainText,
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      minFontSize: 16,
                                    ),
                            ),
                          ),
                          if (!_isRush &&
                              (hasAnswered || _canPlaySupplementaryVoice(q)))
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: Icon(
                                  Icons.volume_up,
                                  size: 28,
                                  color: primaryColor,
                                ),
                                onPressed: _playVoice,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  flex: 3,
                  child: _buildAnswerArea(q, hasAnswered, selectedOption),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!_isRush) ...[
                      Expanded(
                        child: GlowButton(
                          onPressed: _currentIndex > 0 && !_isFinishing
                              ? _goBack
                              : null,
                          isPrimary: false,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!.back),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: GlowButton(
                        onPressed: hasAnswered && !_isFinishing
                            ? _goForward
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _isLastRushQuestion
                                    ? l10n.rushResultShow
                                    : l10n.forward,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerArea(
    Question q,
    bool hasAnswered,
    String? selectedOption,
  ) {
    if (q.isTextInput) {
      return _buildTextInputArea(q, hasAnswered, selectedOption);
    } else if (q.isConstructor) {
      return _buildConstructorArea(q, hasAnswered, selectedOption);
    } else if (q.isMultiSelection) {
      return _buildMultiSelectionArea(q, hasAnswered, selectedOption);
    } else {
      return _buildMultipleChoiceArea(q, hasAnswered, selectedOption);
    }
  }

  Widget _buildTextInputArea(
    Question q,
    bool hasAnswered,
    String? selectedOption,
  ) {
    Color? borderColor;
    if (hasAnswered) {
      bool isCorrect = selectedOption?.trim() == q.correctAnswer.trim();
      if (q.type == QuestionType.transToJapInput ||
          q.type == QuestionType.voiceToJapInput) {
        isCorrect =
            (selectedOption?.trim() == q.word.japanese.trim()) ||
            (q.word.reading != null &&
                selectedOption?.trim() == q.word.reading!.trim());
      }
      if (isCorrect) {
        borderColor = Theme.of(
          context,
        ).extension<AppColorsExtension>()!.success;
      } else {
        borderColor = Theme.of(context).colorScheme.error;
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!hasAnswered)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  enabled: !hasAnswered,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.typeYourAnswer,
                    border: OutlineInputBorder(
                      borderSide: borderColor != null
                          ? BorderSide(color: borderColor, width: 2)
                          : const BorderSide(),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: borderColor != null
                          ? BorderSide(color: borderColor, width: 2)
                          : const BorderSide(),
                    ),
                  ),
                  onSubmitted: (val) {
                    if (!hasAnswered && val.trim().isNotEmpty) {
                      _onOptionSelected(val.trim());
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _textController,
                builder: (context, value, child) {
                  return IconButton(
                    icon: Icon(Icons.send),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: (!hasAnswered && value.text.trim().isNotEmpty)
                        ? () => _onOptionSelected(value.text.trim())
                        : null,
                  );
                },
              ),
            ],
          ),
        if (hasAnswered)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  )!.yourAnswer(selectedOption ?? ''),
                  style: TextStyle(
                    color:
                        (() {
                          bool isCorrect =
                              selectedOption?.trim() == q.correctAnswer.trim();
                          if (q.type == QuestionType.transToJapInput ||
                              q.type == QuestionType.voiceToJapInput) {
                            isCorrect =
                                (selectedOption?.trim() ==
                                    q.word.japanese.trim()) ||
                                (q.word.reading != null &&
                                    selectedOption?.trim() ==
                                        q.word.reading!.trim());
                          }
                          return isCorrect;
                        })()
                        ? Theme.of(
                            context,
                          ).extension<AppColorsExtension>()!.success
                        : Theme.of(context).colorScheme.error,
                    fontSize: 18,
                  ),
                ),
                if (!(() {
                  bool isCorrect =
                      selectedOption?.trim() == q.correctAnswer.trim();
                  if (q.type == QuestionType.transToJapInput ||
                      q.type == QuestionType.voiceToJapInput) {
                    isCorrect =
                        (selectedOption?.trim() == q.word.japanese.trim()) ||
                        (q.word.reading != null &&
                            selectedOption?.trim() == q.word.reading!.trim());
                  }
                  return isCorrect;
                })())
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.correctAnswer(q.correctAnswer),
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).extension<AppColorsExtension>()!.success,
                        fontSize: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildConstructorArea(
    Question q,
    bool hasAnswered,
    String? selectedOption,
  ) {
    final constructedWord = _selectedCharIndices
        .map((i) => q.options[i])
        .join('');

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!hasAnswered) ...[
            Container(
              constraints: const BoxConstraints(minHeight: 70),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _selectedCharIndices.isEmpty
                  ? const Center(
                      child: Text(" ", style: TextStyle(fontSize: 24)),
                    )
                  : Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: List.generate(_selectedCharIndices.length, (
                        index,
                      ) {
                        final charIndex = _selectedCharIndices[index];
                        final char = q.options[charIndex];
                        final chipWidget = InputChip(
                          label: Text(
                            char,
                            style: const TextStyle(fontSize: 20),
                          ),
                          onDeleted: () {
                            setState(() {
                              _selectedCharIndices.removeAt(index);
                            });
                          },
                          deleteIcon: const Icon(Icons.close, size: 18),
                        );

                        return DragTarget<int>(
                          onWillAcceptWithDetails: (details) => true,
                          onAcceptWithDetails: (details) {
                            setState(() {
                              final oldIndex = details.data;
                              if (oldIndex != index) {
                                final item = _selectedCharIndices.removeAt(
                                  oldIndex,
                                );
                                _selectedCharIndices.insert(index, item);
                              }
                            });
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Draggable<int>(
                              data: index,
                              feedback: Material(
                                color: Colors.transparent,
                                child: chipWidget,
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: chipWidget,
                              ),
                              child: chipWidget,
                            );
                          },
                        );
                      }),
                    ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(q.options.length, (index) {
                final isSelected = _selectedCharIndices.contains(index);
                return ElevatedButton(
                  onPressed: hasAnswered
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _selectedCharIndices.remove(index);
                            } else {
                              _selectedCharIndices.add(index);
                            }
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.grey[300] : null,
                    foregroundColor: isSelected ? Colors.grey[600] : null,
                  ),
                  child: Text(q.options[index], style: TextStyle(fontSize: 20)),
                );
              }),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (!hasAnswered && constructedWord.isNotEmpty)
                  ? () => _onOptionSelected(constructedWord)
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                AppLocalizations.of(context)!.submitAnswer,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
          if (hasAnswered)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.yourAnswer(selectedOption ?? ''),
                    style: TextStyle(
                      color: selectedOption == q.correctAnswer
                          ? Theme.of(
                              context,
                            ).extension<AppColorsExtension>()!.success
                          : Theme.of(context).colorScheme.error,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (selectedOption != q.correctAnswer)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.correctAnswer(q.correctAnswer),
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).extension<AppColorsExtension>()!.success,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectionArea(
    Question q,
    bool hasAnswered,
    String? selectedOption,
  ) {
    final hiddenOption = _hiddenOption(q);
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(q.options.length, (index) {
              final isSelected = _selectedMultiIndices.contains(index);
              final option = q.options[index];
              if (option == hiddenOption) return const SizedBox.shrink();
              Color? buttonColor;
              Color? textColor;

              if (hasAnswered) {
                final correctSet = q.correctAnswer
                    .split('/')
                    .map((e) => e.trim())
                    .toSet();
                final selectedSet =
                    selectedOption?.split('/').map((e) => e.trim()).toSet() ??
                    {};
                if (correctSet.contains(option)) {
                  buttonColor = Theme.of(
                    context,
                  ).extension<AppColorsExtension>()!.success;
                  textColor = buttonColor;
                } else if (selectedSet.contains(option)) {
                  buttonColor = Theme.of(context).colorScheme.error;
                  textColor = buttonColor;
                }
              }

              return ElevatedButton(
                onPressed: hasAnswered
                    ? null
                    : () {
                        setState(() {
                          if (isSelected) {
                            _selectedMultiIndices.remove(index);
                          } else {
                            _selectedMultiIndices.add(index);
                          }
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      buttonColor ??
                      (isSelected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2)
                          : null),
                  foregroundColor:
                      textColor ??
                      (isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: Text(option, style: const TextStyle(fontSize: 18)),
              );
            }),
          ),
          const SizedBox(height: 24),
          if (!hasAnswered)
            ElevatedButton(
              onPressed: _selectedMultiIndices.isNotEmpty
                  ? () {
                      final selectedVals = _selectedMultiIndices
                          .map((i) => q.options[i])
                          .toList();
                      selectedVals.sort();
                      _onOptionSelected(selectedVals.join(' / '));
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                AppLocalizations.of(context)!.submitAnswer,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          if (hasAnswered)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.yourAnswer(selectedOption ?? ''),
                    style: TextStyle(
                      color: (() {
                        final selectedSet =
                            selectedOption
                                ?.split('/')
                                .map((e) => e.trim())
                                .toSet() ??
                            {};
                        final correctSet = q.correctAnswer
                            .split('/')
                            .map((e) => e.trim())
                            .toSet();
                        final isCorrect =
                            selectedSet.length == correctSet.length &&
                            selectedSet.containsAll(correctSet);
                        return isCorrect
                            ? Theme.of(
                                context,
                              ).extension<AppColorsExtension>()!.success
                            : Theme.of(context).colorScheme.error;
                      })(),
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!(() {
                    final selectedSet =
                        selectedOption
                            ?.split('/')
                            .map((e) => e.trim())
                            .toSet() ??
                        {};
                    final correctSet = q.correctAnswer
                        .split('/')
                        .map((e) => e.trim())
                        .toSet();
                    return selectedSet.length == correctSet.length &&
                        selectedSet.containsAll(correctSet);
                  })())
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.correctAnswer(q.correctAnswer),
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).extension<AppColorsExtension>()!.success,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceArea(
    Question q,
    bool hasAnswered,
    String? selectedOption,
  ) {
    final hiddenOption = _hiddenOption(q);
    final options = q.options
        .where((option) => option != hiddenOption)
        .toList();
    return ListView.builder(
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];

        Color? buttonColor;
        Color? textColor;

        bool isPrimary = false;
        if (hasAnswered) {
          if (option == q.correctAnswer) {
            buttonColor = Theme.of(
              context,
            ).extension<AppColorsExtension>()!.success;
            textColor = buttonColor;
          } else if (option == selectedOption) {
            buttonColor = Theme.of(context).colorScheme.error;
            textColor = buttonColor;
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: GlowButton(
            color: buttonColor ?? Theme.of(context).colorScheme.surface,
            isPrimary: isPrimary,
            padding: const EdgeInsets.all(20),
            borderRadius: 12,
            width: double.infinity,
            onPressed: () => _onOptionSelected(option),
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: option));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.copiedToClipboard,
                    ),
                  ),
                );
              },
              child: AutoSizeText(
                option,
                style: TextStyle(
                  fontSize: 20,
                  color: textColor ?? Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                minFontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }
}
