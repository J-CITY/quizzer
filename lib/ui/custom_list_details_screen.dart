import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/custom_list.dart';
import '../data/services/database_service.dart';
import 'training_screen.dart'; // We will create this next

class CustomListDetailsScreen extends ConsumerStatefulWidget {
  final CustomList customList;

  const CustomListDetailsScreen({super.key, required this.customList});

  @override
  ConsumerState<CustomListDetailsScreen> createState() => _CustomListDetailsScreenState();
}

class _CustomListDetailsScreenState extends ConsumerState<CustomListDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Load links on start
    widget.customList.words.loadSync();
  }

  @override
  Widget build(BuildContext context) {
    // We get words from the IsarLinks object
    final words = widget.customList.words.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customList.name),
      ),
      body: words.isEmpty
          ? const Center(child: Text('В этом списке пока нет слов'))
          : ListView.builder(
              itemCount: words.length,
              itemBuilder: (context, index) {
                final word = words[index];
                final isLearned = word.progress >= 5;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: isLearned ? Colors.green.shade50 : null,
                  child: ListTile(
                    title: Text(
                      word.japanese,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isLearned ? Colors.green.shade900 : null,
                      ),
                    ),
                    subtitle: Text(word.translation),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            value: word.progress / 5,
                            backgroundColor: Colors.grey.shade200,
                            color: isLearned ? Colors.green : Colors.blue,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Checkbox(
                          value: isLearned,
                          activeColor: Colors.green,
                          onChanged: (val) async {
                            if (val != null) {
                              await ref.read(databaseServiceProvider).toggleWordLearned(word, val);
                              setState(() {}); // refresh UI
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Training Screen for this specific list
          Navigator.push(context, MaterialPageRoute(builder: (_) => TrainingScreen(customListId: widget.customList.id)));
        },
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.play_arrow, size: 32),
      ),
    );
  }
}
