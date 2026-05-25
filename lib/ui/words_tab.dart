import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../data/models/word.dart';
import '../data/services/database_service.dart';
import '../data/services/google_sheets_service.dart';
import 'training_screen.dart'; // We will create this later

// Provider to watch the stream of words from Isar Database
final wordsStreamProvider = StreamProvider.autoDispose<List<Word>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.isar.words.where().watch(fireImmediately: true);
});

// Provider for search query
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

// Provider that combines words and search query
final filteredWordsProvider = Provider.autoDispose<List<Word>>((ref) {
  final words = ref.watch(wordsStreamProvider).value ?? [];
  final query = ref.watch(searchQueryProvider).toLowerCase();
  
  if (query.isEmpty) return words;
  
  return words.where((w) {
    final searchJap = w.japanese.toLowerCase();
    final searchTrans = w.translation.toLowerCase();
    final searchRead = w.reading?.toLowerCase() ?? '';
    return searchJap.contains(query) || searchTrans.contains(query) || searchRead.contains(query);
  }).toList();
});

class WordsTab extends ConsumerStatefulWidget {
  const WordsTab({super.key});

  @override
  ConsumerState<WordsTab> createState() => _WordsTabState();
}

class _WordsTabState extends ConsumerState<WordsTab> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    // Start sync automatically on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncData();
    });
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    try {
      final db = ref.read(databaseServiceProvider);
      final settings = await db.getSettings();
      
      if (settings.sheetId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Укажите ID Google Таблицы в настройках')),
          );
        }
        return;
      }

      final downloaded = await ref.read(googleSheetsServiceProvider).fetchWords(settings.sheetId);
      await db.syncWords(downloaded);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось обновить слова. Проверьте подключение к сети.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _showWordDetails(Word word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(word.japanese, style: const TextStyle(fontSize: 28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (word.reading != null && word.reading!.isNotEmpty)
              Text('Чтение: ${word.reading}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Перевод: ${word.translation}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text('Прогресс: ${word.progress} / 5', style: const TextStyle(color: Colors.grey)),
            Text('Посл. тренировка: ${word.lastTrained?.toString().substring(0, 10) ?? "Никогда"}', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = ref.watch(filteredWordsProvider);

    return Scaffold(
      body: Column(
        children: [
          // Search Bar & Sync indicator
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Поиск (ru/jp)...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                  ),
                ),
                if (_isSyncing)
                  const Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: _syncData,
                    tooltip: 'Синхронизировать',
                  ),
              ],
            ),
          ),
          
          // Words List
          Expanded(
            child: words.isEmpty
                ? const Center(child: Text('Нет слов для отображения'))
                : ListView.builder(
                    itemCount: words.length,
                    itemBuilder: (context, index) {
                      final word = words[index];
                      final isLearned = word.progress >= 5;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: isLearned ? Colors.green.shade50 : null,
                        child: ListTile(
                          onTap: () => _showWordDetails(word),
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
                              // Circular Progress Bar
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
                              // Checkbox
                              Checkbox(
                                value: isLearned,
                                activeColor: Colors.green,
                                onChanged: (val) {
                                  if (val != null) {
                                    ref.read(databaseServiceProvider).toggleWordLearned(word, val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Training Screen for "All Words"
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainingScreen()));
        },
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.play_arrow, size: 32),
      ),
    );
  }
}
