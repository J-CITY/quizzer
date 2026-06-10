import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../data/models/word.dart';
import '../domain/training_engine.dart';
import '../data/services/database_service.dart';
import 'training_result_screen.dart';
import '../utils/constants.dart';
import 'widgets/glow_button.dart';

final ttsProvider = Provider<FlutterTts>((ref) {
  final tts = FlutterTts();
  tts.setLanguage("ja-JP");
  tts.awaitSpeakCompletion(true);
  return tts;
});

class TrainingScreen extends ConsumerStatefulWidget {
  final int? customListId;
  final bool isReviewMode;

  const TrainingScreen({
    super.key,
    this.customListId,
    this.isReviewMode = false,
  });

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Question> _questions = [];
  int _currentIndex = 0;
  final Set<int> _wrongWordIds = {};
  final Set<int> _correctFirstTryWordIds = {};

  final TextEditingController _textController = TextEditingController();
  final List<int> _selectedCharIndices = [];

  // Maps question index to the user's selected answer string.
  final Map<int, String> _userAnswers = {};

  bool _isLoading = true;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    final db = ref.read(databaseServiceProvider);
    final settings = await db.getSettings();
    final engine = ref.read(trainingEngineProvider);

    List<Word> sourceWords;
    String listLanguage = 'ja-JP';

    if (widget.customListId != null) {
      final lists = await db.getCustomLists();
      final list = lists.firstWhere((l) => l.id == widget.customListId);
      listLanguage = list.language;

      if (!widget.isReviewMode) {
        await db.updateLearningQueue(list, settings.learningQueueSize);
        await list.learningQueue.load();
        sourceWords = list.learningQueue.toList();

        // If queue is completely empty (meaning no unlearned words left at all),
        // fallback to all words just in case, though usually handled by UI.
        if (sourceWords.isEmpty) {
          list.words.loadSync();
          sourceWords = list.words.toList();
        }
      } else {
        list.words.loadSync();
        sourceWords = list.words.toList();
      }
    } else {
      sourceWords = await db.getAllWords();
    }

    await ref.read(ttsProvider).setLanguage(listLanguage);

    if (sourceWords.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    _questions = engine.generateSession(
      sourceWords,
      settings,
      AppLocalizations.of(context)!,
      isReviewMode: widget.isReviewMode,
      customList: widget.customListId != null
          ? (await db.getCustomLists()).firstWhere(
              (l) => l.id == widget.customListId,
            )
          : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      _playVoiceOnAppearIfNeeded();
    }
  }

  Future<void> _playVoiceOnAppearIfNeeded() async {
    if (_questions.isEmpty || _currentIndex >= _questions.length) return;
    final q = _questions[_currentIndex];

    final settings = await ref.read(databaseServiceProvider).getSettings();
    if (settings.autoPlayVoice ||
        q.type == QuestionType.voiceToTrans ||
        q.type == QuestionType.voiceToJap) {
      // Do not play if the prompt is translation (types 3, 6, 7) or image (type 10)
      if (q.type == QuestionType.transToJap ||
          q.type == QuestionType.transToJapInput ||
          q.type == QuestionType.transToJapConstructor ||
          q.type == QuestionType.imageToJap) {
        return;
      }

      _playVoice();
    }
  }

  Future<void> _playVoice() async {
    if (_questions.isEmpty || _currentIndex >= _questions.length) return;
    final q = _questions[_currentIndex];

    final textToSpeak = (q.word.reading != null && q.word.reading!.isNotEmpty)
        ? q.word.reading!
        : q.word.japanese;

    await ref.read(ttsProvider).speak(textToSpeak);
  }

  void _onOptionSelected(String option) async {
    if (_userAnswers.containsKey(_currentIndex)) return; // Already answered

    final int answeredIndex = _currentIndex;

    setState(() {
      _userAnswers[_currentIndex] = option;
    });

    final q = _questions[_currentIndex];
    final wordId = q.word.id;
    final settings = await ref.read(databaseServiceProvider).getSettings();

    bool isCorrect = option == q.correctAnswer;
    if (q.type == QuestionType.transToJapInput ||
        q.type == QuestionType.voiceToJapInput) {
      isCorrect =
          (option == q.word.japanese) ||
          (q.word.reading != null && option == q.word.reading);
    }

    if (settings.playSoundEffects) {
      if (isCorrect) {
        await _audioPlayer.play(AssetSource('sounds/true.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/false.mp3'));
      }
    }

    if (isCorrect) {
      if (!_wrongWordIds.contains(wordId)) {
        _correctFirstTryWordIds.add(wordId);
      }
    } else {
      _wrongWordIds.add(wordId);
      if (!widget.isReviewMode) {
        // Append question to the end for repetition only in learn mode
        _questions.add(q);
      }
    }

    if (settings.autoPlayVoice) {
      if (settings.playSoundEffects) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      await _playVoice();
      if (settings.autoAdvanceToNextQuestion) {
        await Future.delayed(AppConstants.audioAdvanceDelay);
        if (mounted && _currentIndex == answeredIndex) {
          _goForward();
        }
      }
    } else {
      if (settings.autoAdvanceToNextQuestion) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted && _currentIndex == answeredIndex) {
          _goForward();
        }
      }
    }
  }

  void _goForward() {
    _textController.clear();
    _selectedCharIndices.clear();
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _playVoiceOnAppearIfNeeded();
    } else {
      _finishTraining();
    }
  }

  void _goBack() {
    _textController.clear();
    _selectedCharIndices.clear();
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _playVoiceOnAppearIfNeeded();
    }
  }

  Future<void> _finishTraining() async {
    final db = ref.read(databaseServiceProvider);

    final allWords = await db.getAllWords();
    final wordsMap = {for (var w in allWords) w.id: w};

    final mistakesList = <Word>[];

    int learnedCount = 0;
    int inProgressCount = 0;

    if (!widget.isReviewMode) {
      // Wrong answers get -1 progress (min 0)
      for (var id in _wrongWordIds) {
        final w = wordsMap[id];
        if (w != null) {
          mistakesList.add(w);
          final newProgress = (w.progress > 0) ? w.progress - 1 : 0;
          await db.updateWordProgress(w, newProgress);
        }
      }

      // Correct answers get +1
      for (var id in _correctFirstTryWordIds) {
        if (!_wrongWordIds.contains(id)) {
          final w = wordsMap[id];
          if (w != null) {
            if (w.progress < 5) {
              await db.updateWordProgress(w, w.progress + 1);
            }
            if (w.progress >= 5) {
              learnedCount++;
            } else {
              inProgressCount++;
            }
          }
        }
      }
    } else {
      // Just collect mistakes for the result screen
      for (var id in _wrongWordIds) {
        final w = wordsMap[id];
        if (w != null) mistakesList.add(w);
      }
      for (var id in _correctFirstTryWordIds) {
        if (!_wrongWordIds.contains(id)) {
          final w = wordsMap[id];
          if (w != null) {
            if (w.progress >= 5) {
              learnedCount++;
            } else {
              inProgressCount++;
            }
          }
        }
      }
    }

    await db.saveTrainingSession(widget.customListId);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TrainingResultScreen(
            mistakes: mistakesList,
            learnedCount: learnedCount,
            inProgressCount: inProgressCount,
          ),
        ),
      );
    }
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

    final q = _questions[_currentIndex];
    final progressText = '${_currentIndex + 1} / ${_questions.length}';
    final hasAnswered = _userAnswers.containsKey(_currentIndex);
    final selectedOption = _userAnswers[_currentIndex];

    bool showTranslation = false;
    String mainText = q.prompt;
    String? subText = q.subtitle;

    if (hasAnswered) {
      if (q.type != QuestionType.japToTrans) {
        showTranslation = true;
      }

      if (q.type == QuestionType.transToJap ||
          q.type == QuestionType.voiceToTrans ||
          q.type == QuestionType.voiceToJap ||
          q.type == QuestionType.voiceToJapInput ||
          q.type == QuestionType.voiceToJapConstructor ||
          q.type == QuestionType.transToJapInput ||
          q.type == QuestionType.transToJapConstructor ||
          q.type == QuestionType.imageToJap) {
        mainText = q.word.japanese;
        subText = q.word.reading;
      }
    }

    bool showImage = false;
    if (q.word.imageUrl != null && q.word.imageUrl!.isNotEmpty) {
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

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

        if (shouldPop ?? false) {
          if (mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(progressText),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -300) {
              if (hasAnswered) {
                if (_currentIndex < _questions.length - 1) {
                  _goForward();
                } else {
                  _finishTraining();
                }
              }
            } else if (details.primaryVelocity! > 300) {
              if (_currentIndex > 0) {
                _goBack();
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isKeyboardOpen) ...[
                  Expanded(
                    flex: 2,
                    child: Stack(
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
                                  color: primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 30,
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
                                color: primaryColor.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: Offset.zero,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Theme.of(context).brightness == Brightness.dark 
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showImage)
                                  Expanded(
                                    flex: 4,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: Image.network(
                                        q.word.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 48,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  flex: showImage ? 5 : 1,
                                  child: Stack(
                                    children: [
                                      GestureDetector(
                                        onLongPress: () {
                                          String textToCopy =
                                              mainText.isNotEmpty
                                              ? mainText
                                              : q.word.japanese;
                                          Clipboard.setData(
                                            ClipboardData(text: textToCopy),
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
                                              if ((q.type == QuestionType.voiceToTrans ||
                                                      q.type == QuestionType.voiceToJap ||
                                                      q.type == QuestionType.voiceToJapInput ||
                                                      q.type == QuestionType.voiceToJapConstructor ||
                                                      q.type == QuestionType.imageToJap) &&
                                                  !hasAnswered)
                                                Column(
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.volume_up,
                                                        size: showImage ? 56 : 80,
                                                        color: primaryColor,
                                                      ),
                                                      onPressed: _playVoice,
                                                    ),
                                                    SizedBox(height: showImage ? 8 : 16),
                                                    Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.listenToTheWord,
                                                      style: TextStyle(
                                                        fontSize: showImage ? 18 : 24,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              else ...[
                                                AutoSizeText(
                                                  mainText,
                                                  style: TextStyle(
                                                    fontSize: showImage ? 32 : 48,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 3,
                                                  minFontSize: showImage ? 16 : 24,
                                                ),
                                                if (subText != null &&
                                                    subText.isNotEmpty)
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      top: showImage ? 4.0 : 8.0,
                                                    ),
                                                    child: Text(
                                                      subText,
                                                      style: TextStyle(
                                                        fontSize: showImage ? 18 : 24,
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
                                                    padding: EdgeInsets.only(
                                                      top: showImage ? 8.0 : 16.0,
                                                    ),
                                                    child: Text(
                                                      q.word.translation,
                                                      style: TextStyle(
                                                        fontSize: showImage ? 16 : 20,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                      // Hide small mic if:
                                      // 1. Not answered and type is Trans->Jap (to avoid hint)
                                      // 2. Not answered and type is Auditory (because big mic is shown)
                                      if (!(!hasAnswered &&
                                          (q.type == QuestionType.transToJap ||
                                              q.type == QuestionType.transToJapInput ||
                                              q.type == QuestionType.transToJapConstructor ||
                                              q.type == QuestionType.voiceToTrans ||
                                              q.type == QuestionType.voiceToJap ||
                                              q.type == QuestionType.voiceToJapInput ||
                                              q.type == QuestionType.voiceToJapConstructor ||
                                              q.type == QuestionType.imageToJap)))
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
                          ),
                        ),
                      ],
                    ),
                  ),
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
                              child: (!hasAnswered &&
                                      (q.type == QuestionType.voiceToTrans ||
                                          q.type == QuestionType.voiceToJap ||
                                          q.type == QuestionType.voiceToJapInput ||
                                          q.type == QuestionType.voiceToJapConstructor ||
                                          q.type == QuestionType.imageToJap))
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
                          if (!(!hasAnswered &&
                              (q.type == QuestionType.transToJap ||
                                  q.type == QuestionType.transToJapInput ||
                                  q.type ==
                                      QuestionType.transToJapConstructor ||
                                  q.type == QuestionType.voiceToTrans ||
                                  q.type == QuestionType.voiceToJap ||
                                  q.type == QuestionType.voiceToJapInput ||
                                  q.type ==
                                      QuestionType.voiceToJapConstructor)))
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
                    Expanded(
                      child: GlowButton(
                        onPressed: _currentIndex > 0 ? _goBack : null,
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
                    Expanded(
                      child: GlowButton(
                        onPressed: hasAnswered ? _goForward : null,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.forward),
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
    if (q.type == QuestionType.transToJapInput ||
        q.type == QuestionType.voiceToJapInput) {
      return _buildTextInputArea(q, hasAnswered, selectedOption);
    } else if (q.type == QuestionType.transToJapConstructor ||
        q.type == QuestionType.voiceToJapConstructor) {
      return _buildConstructorArea(q, hasAnswered, selectedOption);
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
      bool isCorrect = selectedOption == q.correctAnswer;
      if (q.type == QuestionType.transToJapInput ||
          q.type == QuestionType.voiceToJapInput) {
        isCorrect =
            (selectedOption == q.word.japanese) ||
            (q.word.reading != null && selectedOption == q.word.reading);
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
                        (selectedOption == q.correctAnswer ||
                            ((q.type == QuestionType.transToJapInput ||
                                    q.type == QuestionType.voiceToJapInput) &&
                                ((selectedOption == q.word.japanese) ||
                                    (q.word.reading != null &&
                                        selectedOption == q.word.reading))))
                        ? Theme.of(
                            context,
                          ).extension<AppColorsExtension>()!.success
                        : Theme.of(context).colorScheme.error,
                    fontSize: 18,
                  ),
                ),
                if (!(selectedOption == q.correctAnswer ||
                    ((q.type == QuestionType.transToJapInput ||
                            q.type == QuestionType.voiceToJapInput) &&
                        ((selectedOption == q.word.japanese) ||
                            (q.word.reading != null &&
                                selectedOption == q.word.reading)))))
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            constructedWord.isEmpty ? " " : constructedWord,
            style: TextStyle(fontSize: 24),
            textAlign: TextAlign.center,
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
    );
  }

  Widget _buildMultipleChoiceArea(
    Question q,
    bool hasAnswered,
    String? selectedOption,
  ) {
    return ListView.builder(
      itemCount: q.options.length,
      itemBuilder: (context, index) {
        final option = q.options[index];

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
