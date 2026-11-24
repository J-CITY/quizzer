import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import '../data/models/word.dart';
import '../data/services/database_service.dart';
import '../utils/constants.dart';
import 'widgets/glow_button.dart';
import 'widgets/word_image.dart';
import 'training_screen.dart' show ttsProvider; // Reuse TTS provider

class FlashcardsScreen extends ConsumerStatefulWidget {
  final int? customListId;

  const FlashcardsScreen({super.key, this.customListId});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen>
    with SingleTickerProviderStateMixin {
  List<Word> _words = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isFlipped = false;
  bool _shuffle = false;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  // Settings
  bool _showWord = true;
  bool _showReading = true;
  bool _showTranslation = true;
  bool _showImage = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _initSession();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _initSession() async {
    final db = ref.read(databaseServiceProvider);
    final settings = await db.getSettings();

    _showWord = settings.flashcardShowWord;
    _showReading = settings.flashcardShowReading;
    _showTranslation = settings.flashcardShowTranslation;
    _showImage = settings.flashcardShowImage;

    String listLanguage = 'ja-JP';

    if (widget.customListId != null) {
      final lists = await db.getCustomLists();
      final list = lists.firstWhere((l) => l.id == widget.customListId);
      await list.words.load();
      _words = list.words.toList();
      listLanguage = list.language;
      _shuffle = list.flashcardShuffleCards;
    } else {
      _words = await db.getAllWords();
      _shuffle = settings.flashcardShuffleCards;
    }

    if (_shuffle) {
      _words.shuffle();
    }

    await ref.read(ttsProvider).setLanguage(listLanguage);

    if (mounted) {
      setState(() => _isLoading = false);
      if (settings.autoPlayVoice) {
        _playVoice();
      }
    }
  }

  Future<void> _playVoice() async {
    if (_words.isEmpty || _currentIndex >= _words.length) return;
    final w = _words[_currentIndex];

    final textToSpeak =
        (w.reading != null && w.reading!.isNotEmpty) ? w.reading! : w.japanese;

    if (!Platform.isWindows) {
      await ref.read(ttsProvider).stop();
    }
    await Future.delayed(const Duration(milliseconds: 150));
    await ref.read(ttsProvider).speak(textToSpeak);
  }

  void _flipCard() {
    // If all are selected, nothing to flip to.
    if (_showWord && _showReading && _showTranslation && _showImage) return;

    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    _isFlipped = !_isFlipped;
  }

  void _goForward() {
    if (_currentIndex < _words.length - 1) {
      if (_isFlipped) {
        _isFlipped = false;
        _flipController.value = 0;
      }
      setState(() {
        _currentIndex++;
      });
      _playVoiceIfNeeded();
    } else {
      Navigator.pop(context); // Finish viewing
    }
  }

  void _goBack() {
    if (_currentIndex > 0) {
      if (_isFlipped) {
        _isFlipped = false;
        _flipController.value = 0;
      }
      setState(() {
        _currentIndex--;
      });
      _playVoiceIfNeeded();
    }
  }

  void _playVoiceIfNeeded() async {
    final settings = await ref.read(databaseServiceProvider).getSettings();
    if (settings.autoPlayVoice) {
      _playVoice();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_words.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(AppLocalizations.of(context)!.noWordsFound),
        ),
      );
    }

    final progressText = '${_currentIndex + 1} / ${_words.length}';
    final word = _words[_currentIndex];

    return Scaffold(
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
            _goForward();
          } else if (details.primaryVelocity! > 300) {
            _goBack();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final value = _flipAnimation.value;
                      final isBack = value > 0.5;
                      final angle = value * pi;

                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        alignment: FractionalOffset.center,
                        child: isBack
                            ? Transform(
                                transform: Matrix4.identity()..rotateY(pi),
                                alignment: FractionalOffset.center,
                                child: _buildCardContent(word, false),
                              )
                            : _buildCardContent(word, true),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                          const Icon(Icons.arrow_back),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.back),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GlowButton(
                      onPressed: _goForward,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppLocalizations.of(context)!.forward),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward),
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
    );
  }

  Widget _buildCardContent(Word word, bool isFront) {
    final bool showWord = isFront ? _showWord : !_showWord;
    final bool showReading = isFront ? _showReading : !_showReading;
    final bool showTranslation = isFront ? _showTranslation : !_showTranslation;
    final bool showImage = isFront ? _showImage : !_showImage;
    
    final bool hasImage = showImage && word.imageUrl != null && word.imageUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasImage)
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: WordImage(source: word.imageUrl!),
              ),
            ),
          Expanded(
            flex: hasImage ? 5 : 1,
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (showWord)
                          AutoSizeText(
                            word.japanese,
                            style: TextStyle(
                              fontSize: hasImage ? 32 : 48,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            minFontSize: hasImage ? 16 : 24,
                          ),
                        if (showReading && word.reading != null && word.reading!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: hasImage ? 4.0 : 8.0),
                            child: Text(
                              word.reading!,
                              style: TextStyle(
                                fontSize: hasImage ? 18 : 24,
                                color: Theme.of(context)
                                    .extension<AppColorsExtension>()!
                                    .textSecondary,
                              ),
                            ),
                          ),
                        if (showTranslation)
                          Padding(
                            padding: EdgeInsets.only(top: hasImage ? 8.0 : 16.0),
                            child: Text(
                              word.translation,
                              style: TextStyle(
                                fontSize: hasImage ? 16 : 20,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (showWord || showReading)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: IconButton(
                      iconSize: 48,
                      icon: Icon(
                        Icons.volume_up,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        _playVoice();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
