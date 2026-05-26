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

final ttsProvider = Provider<FlutterTts>((ref) {
  final tts = FlutterTts();
  tts.setLanguage("ja-JP");
  return tts;
});

class TrainingScreen extends ConsumerStatefulWidget {
  final int? customListId;

  const TrainingScreen({super.key, this.customListId});

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Question> _questions = [];
  int _currentIndex = 0;
  final Set<int> _wrongWordIds = {};
  final Set<int> _correctFirstTryWordIds = {};

  bool _isLoading = true;
  String? _selectedOption;
  bool _isAnswerRevealed = false;

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

    _questions = engine.generateSession(sourceWords, settings);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playVoiceIfNeeded() async {
    final settings = await ref.read(databaseServiceProvider).getSettings();
    if (settings.autoPlayVoice) {
      _playVoice();
    }
  }

  Future<void> _playVoice() async {
    if (_questions.isEmpty || _currentIndex >= _questions.length) return;
    final q = _questions[_currentIndex];
    await ref.read(ttsProvider).speak(q.word.japanese);
  }

  void _onOptionSelected(String option) async {
    if (_isAnswerRevealed) return; // Ignore multiple clicks

    setState(() {
      _selectedOption = option;
      _isAnswerRevealed = true;
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
      // Append question to the end
      _questions.add(q);
    }

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isAnswerRevealed = false;
      });
    } else {
      _finishTraining();
    }
  }

  Future<void> _finishTraining() async {
    final db = ref.read(databaseServiceProvider);

    final allWords = await db.getAllWords();
    final wordsMap = {for (var w in allWords) w.id: w};

    final mistakesList = <Word>[];

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

    return Scaffold(
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
                            Text(
                              q.prompt,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (q.subtitle != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  q.subtitle!,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(
                          Icons.volume_up,
                          size: 32,
                          color: Colors.deepPurple,
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

                  Color buttonColor = Colors.white;
                  Color textColor = Colors.black87;

                  if (_isAnswerRevealed) {
                    if (option == q.correctAnswer) {
                      buttonColor = Colors.green.shade400;
                      textColor = Colors.white;
                    } else if (option == _selectedOption) {
                      buttonColor = Colors.red.shade400;
                      textColor = Colors.white;
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
          ],
        ),
      ),
    );
  }
}
