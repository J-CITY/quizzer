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
      isReviewMode: widget.isReviewMode,
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
    if (settings.autoPlayVoice) {
      // Do not play if the prompt is translation (types 3, 6, 7)
      if (q.type == 3 || q.type == 6 || q.type == 7) {
        return;
      }

      _playVoice();
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

    final textToSpeak = (q.word.reading != null && q.word.reading!.isNotEmpty)
        ? q.word.reading!
        : q.word.japanese;

    await ref.read(ttsProvider).speak(textToSpeak);
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

    bool showTranslation = false;
    String mainText = q.prompt;
    String? subText = q.subtitle;

    if (hasAnswered) {
      if (q.type != 2) {
        showTranslation = true;
      }

      if (q.type == 3 ||
          q.type == 4 ||
          q.type == 5 ||
          q.type == 6 ||
          q.type == 7) {
        mainText = q.word.japanese;
        subText = q.word.reading;
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
                child: const Text(
                  'Выйти',
                  style: TextStyle(color: ColorConstants.error),
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
        appBar: AppBar(title: Text(progressText), centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isKeyboardOpen) ...[
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
                                  AppLocalizations.of(
                                    context,
                                  )!.copiedToClipboard,
                                ),
                              ),
                            );
                          },
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if ((q.type == 4 || q.type == 5) &&
                                    !hasAnswered)
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.volume_up,
                                          size: 80,
                                          color: primaryColor,
                                        ),
                                        onPressed: _playVoice,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.listenToTheWord,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ],
                                  )
                                else ...[
                                  AutoSizeText(
                                    mainText,
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    minFontSize: 24,
                                  ),
                                  if (subText != null && subText.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        subText,
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
                              ],
                            ),
                          ),
                        ),
                        // Hide small mic if:
                        // 1. Not answered and type is Trans->Jap (to avoid hint)
                        // 2. Not answered and type is Auditory (because big mic is shown)
                        if (!(!hasAnswered &&
                            (q.type == 3 ||
                                q.type == 6 ||
                                q.type == 7 ||
                                q.type == 4 ||
                                q.type == 5)))
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
              ],
              if (isKeyboardOpen)
                Expanded(
                  flex: 1,
                  child: Card(
                    elevation: 2,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AutoSizeText(
                          mainText,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          minFontSize: 16,
                        ),
                      ),
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

  Widget _buildAnswerArea(
    Question q,
    bool hasAnswered,
    String? selectedOption,
  ) {
    if (q.type == 6) {
      return _buildTextInputArea(q, hasAnswered, selectedOption);
    } else if (q.type == 7) {
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
      if (selectedOption == q.correctAnswer) {
        borderColor = ColorConstants.successMedium;
      } else {
        borderColor = ColorConstants.errorMedium;
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
                  icon: const Icon(Icons.send),
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
                  'Ваш ответ: $selectedOption',
                  style: TextStyle(
                    color: selectedOption == q.correctAnswer
                        ? ColorConstants.successMedium
                        : ColorConstants.errorMedium,
                    fontSize: 18,
                  ),
                ),
                if (selectedOption != q.correctAnswer)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Правильный ответ: ${q.correctAnswer}',
                      style: TextStyle(
                        color: ColorConstants.successMedium,
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
            style: const TextStyle(fontSize: 24),
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
              child: Text(
                q.options[index],
                style: const TextStyle(fontSize: 20),
              ),
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
            style: const TextStyle(fontSize: 18),
          ),
        ),
        if (hasAnswered)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              children: [
                Text(
                  'Ваш ответ: $selectedOption',
                  style: TextStyle(
                    color: selectedOption == q.correctAnswer
                        ? ColorConstants.successMedium
                        : ColorConstants.errorMedium,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (selectedOption != q.correctAnswer)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Правильный ответ: ${q.correctAnswer}',
                      style: TextStyle(
                        color: ColorConstants.successMedium,
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
    );
  }
}
