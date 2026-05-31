import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/models/word.dart';
import '../domain/training_engine.dart';
import '../data/services/database_service.dart';
import 'training_result_screen.dart';
import '../utils/constants.dart';

final ttsProvider = Provider<FlutterTts>((ref) {
  final tts = FlutterTts();
  tts.setLanguage("ja-JP");
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

  // Maps question index to the user's selected answer string.
  final Map<int, String> _userAnswers = {};

  bool _isLoading = true;

  @override
  void dispose() {
    _audioPlayer.dispose();
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
    if (widget.customListId != null) {
      final lists = await db.getCustomLists();
      final list = lists.firstWhere((l) => l.id == widget.customListId);
      list.words.loadSync();
      sourceWords = list.words.toList();
    } else {
      sourceWords = await db.getAllWords();
    }

    if (sourceWords.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    _questions = engine.generateSession(
      sourceWords,
      settings,
      isReviewMode: widget.isReviewMode,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playVoiceIfNeeded() async {
    final settings = await ref.read(databaseServiceProvider).getSettings();
    if (settings.autoPlayVoice) {
      if (settings.playSoundEffects) {
        // Wait for sound effect to finish
        await Future.delayed(const Duration(milliseconds: 500));
      }
      _playVoice();
    }
  }

  Future<void> _playVoice() async {
    if (_questions.isEmpty || _currentIndex >= _questions.length) return;
    final q = _questions[_currentIndex];
    await ref.read(ttsProvider).speak(q.word.japanese);
  }

  void _onOptionSelected(String option) async {
    if (_userAnswers.containsKey(_currentIndex)) return; // Already answered

    setState(() {
      _userAnswers[_currentIndex] = option;
    });

    _playVoiceIfNeeded();

    final q = _questions[_currentIndex];
    final isCorrect = option == q.correctAnswer;
    final wordId = q.word.id;

    final settings = await ref.read(databaseServiceProvider).getSettings();
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

    if (settings.autoAdvanceToNextQuestion) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      _goForward();
    }
  }

  void _goForward() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finishTraining();
    }
  }

  void _goBack() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _finishTraining() async {
    final db = ref.read(databaseServiceProvider);

    final allWords = await db.getAllWords();
    final wordsMap = {for (var w in allWords) w.id: w};

    final mistakesList = <Word>[];

    if (!widget.isReviewMode) {
      // Wrong answers reset to 0
      for (var id in _wrongWordIds) {
        final w = wordsMap[id];
        if (w != null) {
          mistakesList.add(w);
          await db.updateWordProgress(w, 0);
        }
      }

      // Correct answers get +1
      for (var id in _correctFirstTryWordIds) {
        if (!_wrongWordIds.contains(id)) {
          final w = wordsMap[id];
          if (w != null && w.progress < 5) {
            await db.updateWordProgress(w, w.progress + 1);
          }
        }
      }
    } else {
      // Just collect mistakes for the result screen
      for (var id in _wrongWordIds) {
        final w = wordsMap[id];
        if (w != null) mistakesList.add(w);
      }
    }

    await db.saveTrainingSession(widget.customListId);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TrainingResultScreen(mistakes: mistakesList),
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
    final showTranslation = hasAnswered && (q.type == 0 || q.type == 1);

    final primaryColor = Theme.of(context).colorScheme.primary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Завершить тренировку?'),
            content: const Text(
              'Ваш прогресс в этой сессии не будет сохранен.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Выйти', style: TextStyle(color: ColorConstants.error)),
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
        appBar: AppBar(title: Text(progressText), centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 4,
                  child: Stack(
                    children: [
                      GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: q.prompt));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.copiedToClipboard,
                              ),
                            ),
                          );
                        },
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  q.prompt,
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (q.subtitle != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    q.subtitle!,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: ColorConstants.textGrey,
                                    ),
                                  ),
                                ),
                              if (showTranslation)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Text(
                                    q.word.translation,
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (!(q.type == 3 && !hasAnswered))
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
              ),
              const SizedBox(height: 24),
              Expanded(
                flex: 3,
                child: ListView.builder(
                  itemCount: q.options.length,
                  itemBuilder: (context, index) {
                    final option = q.options[index];

                    Color buttonColor = ColorConstants.textWhite;
                    Color textColor = ColorConstants.textPrimary;

                    if (hasAnswered) {
                      if (option == q.correctAnswer) {
                        buttonColor = ColorConstants.successMedium;
                        textColor = ColorConstants.textWhite;
                      } else if (option == selectedOption) {
                        buttonColor = ColorConstants.errorMedium;
                        textColor = ColorConstants.textWhite;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: textColor,
                          padding: const EdgeInsets.all(20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _onOptionSelected(option),
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
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _currentIndex > 0 ? _goBack : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Назад'),
                  ),
                  ElevatedButton.icon(
                    onPressed: hasAnswered ? _goForward : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Вперед'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
