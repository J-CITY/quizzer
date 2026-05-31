import 'package:flutter/material.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/word.dart';
import '../utils/constants.dart';
import 'training_screen.dart'; // for ttsProvider

class TrainingResultScreen extends ConsumerWidget {
  final List<Word> mistakes;

  const TrainingResultScreen({super.key, required this.mistakes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.trainingResultsTitle),
        automaticallyImplyLeading: false, // Hide back button
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              mistakes.isEmpty
                  ? AppLocalizations.of(context)!.trainingResultsPerfect
                  : AppLocalizations.of(
                      context,
                    )!.trainingResultsMistakes(mistakes.length.toString()),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          if (mistakes.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: mistakes.length,
                itemBuilder: (context, index) {
                  final word = mistakes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      title: Text(
                        word.japanese,
                        style: TextStyle(fontSize: 18, color: ColorConstants.error),
                      ),
                      subtitle: Text(
                        '${word.reading != null ? "${word.reading}\n" : ""}${word.translation}',
                      ),
                      isThreeLine: word.reading != null,
                      trailing: IconButton(
                        icon: Icon(Icons.volume_up, color: primaryColor),
                        onPressed: () {
                          ref.read(ttsProvider).speak(word.japanese);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: ColorConstants.textWhite,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () {
                  // Navigate back to the home screen
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  AppLocalizations.of(context)!.close,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
