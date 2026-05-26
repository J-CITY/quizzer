import 'package:flutter/material.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import '../data/models/word.dart';

class TrainingResultScreen extends StatelessWidget {
  final List<Word> mistakes;

  const TrainingResultScreen({super.key, required this.mistakes});

  @override
  Widget build(BuildContext context) {
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
              mistakes.isEmpty ? AppLocalizations.of(context)!.trainingResultsPerfect : AppLocalizations.of(context)!.trainingResultsMistakes(mistakes.length.toString()),
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
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      title: Text(word.japanese, style: TextStyle(fontSize: 18, color: Colors.red)),
                      subtitle: Text('${word.reading != null ? "${word.reading}\n" : ""}${word.translation}'),
                      isThreeLine: word.reading != null,
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
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () {
                  // Navigate back to the home screen
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(AppLocalizations.of(context)!.close, style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
