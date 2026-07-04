import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../data/models/word.dart';
import '../utils/constants.dart';
import '../data/services/database_service.dart';
import 'training_screen.dart'; // for ttsProvider
import 'widgets/acrylic_card.dart';
import 'widgets/glow_button.dart';
import 'widgets/ripple_animation.dart';
import '../main.dart'; // To get adsServiceProvider

class TrainingResultScreen extends ConsumerStatefulWidget {
  final List<Word> mistakes;
  final int learnedCount;
  final int inProgressCount;

  const TrainingResultScreen({
    super.key,
    required this.mistakes,
    this.learnedCount = 0,
    this.inProgressCount = 0,
  });

  @override
  ConsumerState<TrainingResultScreen> createState() =>
      _TrainingResultScreenState();
}

class _TrainingResultScreenState extends ConsumerState<TrainingResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(days: 365),
    );
    if (widget.mistakes.isEmpty) {
      _confettiController.play();
    }

    // Show interstitial ad if applicable
    Future.microtask(() async {
      ref.read(adsServiceProvider).showInterstitialAd();
      
      if (widget.mistakes.isEmpty) {
        final settings = await ref.read(databaseServiceProvider).getSettings();
        if (settings.hapticFeedbackEnabled) {
          HapticFeedback.mediumImpact();
          Future.delayed(const Duration(milliseconds: 150), () {
            HapticFeedback.heavyImpact();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.trainingResultsTitle),
        automaticallyImplyLeading: false, // Hide back button
      ),
      body: Column(
        children: [
          if (widget.mistakes.isEmpty)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                      const Spacer(flex: 2),
                      Text(
                        AppLocalizations.of(context)!.trainingResultsPerfect,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(flex: 1),
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          ConfettiWidget(
                            confettiController: _confettiController,
                            blastDirection: -3.14159 / 2, // Upwards
                            maxBlastForce: 80,
                            minBlastForce: 20,
                            emissionFrequency: 0.02,
                            numberOfParticles: 3,
                            gravity: 0.1,
                          ),
                          ConfettiWidget(
                            confettiController: _confettiController,
                            blastDirection: -3.14159 / 2 - 0.5, // Slightly Left
                            maxBlastForce: 80,
                            minBlastForce: 20,
                            emissionFrequency: 0.02,
                            numberOfParticles: 2,
                            gravity: 0.1,
                          ),
                          ConfettiWidget(
                            confettiController: _confettiController,
                            blastDirection: -3.14159 / 2 + 0.5, // Slightly Right
                            maxBlastForce: 80,
                            minBlastForce: 20,
                            emissionFrequency: 0.02,
                            numberOfParticles: 2,
                            gravity: 0.1,
                          ),
                          RippleAnimation(
                            color: primaryColor,
                            minRadius: 80,
                            ripplesCount: 4,
                            duration: const Duration(seconds: 2),
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.6),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.check,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      AcrylicCard(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem(
                                widget.learnedCount.toString(),
                                AppLocalizations.of(context)!.statLearned,
                              ),
                              _buildStatItem(
                                widget.inProgressCount.toString(),
                                AppLocalizations.of(context)!.statInProgress,
                              ),
                              _buildStatItem(
                                widget.mistakes.length.toString(),
                                AppLocalizations.of(context)!.statMistakes,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 3),
                    ],
                  ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.trainingResultsMotivation,
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AcrylicCard(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            widget.learnedCount.toString(),
                            AppLocalizations.of(context)!.statLearned,
                          ),
                          _buildStatItem(
                            widget.inProgressCount.toString(),
                            AppLocalizations.of(context)!.statInProgress,
                          ),
                          _buildStatItem(
                            widget.mistakes.length.toString(),
                            AppLocalizations.of(context)!.statMistakes,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.trainingResultsMistakes(
                      widget.mistakes.length.toString(),
                    ),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.mistakes.length,
                itemBuilder: (context, index) {
                  final word = widget.mistakes[index];
                  return AcrylicCard(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      title: Text(
                        word.japanese,
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      subtitle: Text(
                        '${word.reading != null ? "${word.reading}\n" : ""}${word.translation}',
                      ),
                      isThreeLine: word.reading != null,
                      trailing: IconButton(
                        icon: Icon(Icons.volume_up, color: primaryColor),
                        onPressed: () {
                          final textToSpeak =
                              (word.reading != null && word.reading!.isNotEmpty)
                              ? word.reading!
                              : word.japanese;
                          ref.read(ttsProvider).speak(textToSpeak);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  // Navigate back to the home screen
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  AppLocalizations.of(context)!.close,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(
              context,
            ).extension<AppColorsExtension>()!.textSecondary,
          ),
        ),
      ],
    );
  }
}
