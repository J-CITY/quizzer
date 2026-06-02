import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizzer/data/models/word.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/custom_list.dart';
import '../data/services/database_service.dart';
import '../data/services/google_sheets_service.dart';
import 'training_screen.dart';
import '../utils/constants.dart';

class CustomListDetailsScreen extends ConsumerStatefulWidget {
  final CustomList customList;

  const CustomListDetailsScreen({super.key, required this.customList});

  @override
  ConsumerState<CustomListDetailsScreen> createState() =>
      _CustomListDetailsScreenState();
}

enum _ListMode { normal, selectToAdd, selectToDelete }

class _CustomListDetailsScreenState
    extends ConsumerState<CustomListDetailsScreen> {
  _ListMode _mode = _ListMode.normal;
  final Set<int> _selectedWordIds = {};
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    widget.customList.words.loadSync();
  }

  Future<void> _sync() async {
    if (widget.customList.googleSheetId == null ||
        widget.customList.googleSheetId!.isEmpty) {
      return;
    }

    setState(() => _isSyncing = true);
    try {
      final words = await GoogleSheetsService.fetchWords(
        widget.customList.googleSheetId!,
      );
      final db = ref.read(databaseServiceProvider);
      await db.syncWordsForList(widget.customList, words);
      widget.customList.words.loadSync();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorNetwork)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _deleteList() async {
    final db = ref.read(databaseServiceProvider);
    await db.deleteCustomList(widget.customList.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _resetProgress() async {
    final db = ref.read(databaseServiceProvider);
    await db.isar.writeTxn(() async {
      for (var word in widget.customList.words) {
        word.progress = 0;
        await db.isar.words.put(word);
      }
    });
    setState(() {});
  }

  Future<void> _deleteSelectedWords() async {
    final db = ref.read(databaseServiceProvider);
    final wordsToRemove = widget.customList.words
        .where((w) => _selectedWordIds.contains(w.id))
        .toList();

    await db.isar.writeTxn(() async {
      widget.customList.words.removeAll(wordsToRemove);
      await widget.customList.words.save();
    });

    await db.cleanUpOrphanedWords();

    setState(() {
      _mode = _ListMode.normal;
      _selectedWordIds.clear();
    });
  }

  Future<void> _addSelectedToAnotherList() async {
    final db = ref.read(databaseServiceProvider);
    final allLists = await db.getCustomLists();
    final localLists = allLists
        .where(
          (l) =>
              l.id != widget.customList.id &&
              l.language == widget.customList.language &&
              (l.googleSheetId == null || l.googleSheetId!.isEmpty),
        )
        .toList();

    if (localLists.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет доступных локальных списков')),
        );
      }
      return;
    }

    if (!mounted) return;
    final selectedList = await showDialog<CustomList>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.addToAnotherList),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: localLists.length,
              itemBuilder: (context, i) {
                final l = localLists[i];
                return ListTile(
                  title: Text(l.name),
                  onTap: () => Navigator.pop(context, l),
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedList != null) {
      final wordsToAdd = widget.customList.words
          .where((w) => _selectedWordIds.contains(w.id))
          .toList();
      await db.isar.writeTxn(() async {
        selectedList.words.addAll(wordsToAdd);
        await selectedList.words.save();
      });

      setState(() {
        _mode = _ListMode.normal;
        _selectedWordIds.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Слова добавлены')));
      }
    }
  }

  void _showWordDetails(Word word) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final primaryColor = Theme.of(context).colorScheme.primary;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(text: word.japanese));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.copiedToClipboard,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        word.japanese,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.volume_up, size: 32, color: primaryColor),
                    onPressed: () async {
                      await ref.read(ttsProvider).setLanguage(widget.customList.language);
                      
                      final textToSpeak = (word.reading != null && word.reading!.isNotEmpty) 
                          ? word.reading! 
                          : word.japanese;
                          
                      await ref.read(ttsProvider).speak(textToSpeak);
                    },
                  ),
                ],
              ),
              if (word.reading != null && word.reading!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.wordReading(word.reading!),
                  style: TextStyle(fontSize: 18, color: Theme.of(context).extension<AppColorsExtension>()!.textSecondary),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.wordTranslation(word.translation),
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(
                  context,
                )!.wordProgress(word.progress.toString()),
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.wordLastTrained(
                  word.lastTrained != null
                      ? '${word.lastTrained!.day.toString().padLeft(2, '0')}.${word.lastTrained!.month.toString().padLeft(2, '0')}.${word.lastTrained!.year}'
                      : AppLocalizations.of(context)!.never,
                ),
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _startTraining() {
    final words = widget.customList.words.toList();
    if (words.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noWordsForTraining),
        ),
      );
      return;
    }

    final hasUnlearned = words.any((w) => w.progress < 5);
    final primaryColor = Theme.of(context).colorScheme.primary;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!hasUnlearned) ...[
                const Text(
                  'Все слова изучены 🎉',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              if (hasUnlearned)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrainingScreen(
                          customListId: widget.customList.id,
                          isReviewMode: false,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.school),
                  label: const Text('Учить', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (hasUnlearned) const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrainingScreen(
                        customListId: widget.customList.id,
                        isReviewMode: true,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.repeat),
                label: const Text('Повторить', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: hasUnlearned
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                      : primaryColor,
                  foregroundColor: hasUnlearned ? primaryColor : Colors.white,
                  elevation: hasUnlearned ? 0 : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.customList.words.toList();
    final isGoogleSheetList =
        widget.customList.googleSheetId != null &&
        widget.customList.googleSheetId!.isNotEmpty;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customList.name),
        actions: [
          if (_mode == _ListMode.normal && isGoogleSheetList)
            _isSyncing
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(icon: Icon(Icons.sync), onPressed: _sync),
          if (_mode == _ListMode.normal)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'delete') {
                  _deleteList();
                } else if (val == 'edit') {
                  setState(() => _mode = _ListMode.selectToDelete);
                } else if (val == 'add_to_other') {
                  setState(() => _mode = _ListMode.selectToAdd);
                } else if (val == 'reset') {
                  _resetProgress();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Text(AppLocalizations.of(context)!.deleteList),
                ),
                if (!isGoogleSheetList)
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(AppLocalizations.of(context)!.editList),
                  ),
                PopupMenuItem(
                  value: 'add_to_other',
                  child: Text(AppLocalizations.of(context)!.addToAnotherList),
                ),
                const PopupMenuItem(
                  value: 'reset',
                  child: Text('Сбросить прогресс'),
                ),
              ],
            ),
          if (_mode != _ListMode.normal)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => setState(() {
                _mode = _ListMode.normal;
                _selectedWordIds.clear();
              }),
            ),
        ],
      ),
      body: words.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.listEmpty))
          : ListView.builder(
              itemCount: words.length,
              itemBuilder: (context, index) {
                final word = words[index];
                final isLearned = word.progress >= 5;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  color: _selectedWordIds.contains(word.id)
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                      : (isLearned ? Theme.of(context).extension<AppColorsExtension>()!.successBackground : null),
                  child: ListTile(
                    leading: _mode != _ListMode.normal
                        ? Checkbox(
                            value: _selectedWordIds.contains(word.id),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedWordIds.add(word.id);
                                } else {
                                  _selectedWordIds.remove(word.id);
                                }
                              });
                            },
                          )
                        : null,
                    title: Text(
                      word.japanese,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isLearned ? Theme.of(context).extension<AppColorsExtension>()!.successText : null,
                      ),
                    ),
                    subtitle: Text(word.translation),
                    trailing: _mode == _ListMode.normal
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: word.progress / 5,
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  color: isLearned ? Theme.of(context).extension<AppColorsExtension>()!.success : Theme.of(context).extension<AppColorsExtension>()!.iconBlue,
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Checkbox(
                                value: isLearned,
                                activeColor: Theme.of(context).extension<AppColorsExtension>()!.success,
                                onChanged: (val) async {
                                  if (val != null) {
                                    await ref
                                        .read(databaseServiceProvider)
                                        .toggleWordLearned(word, val);
                                    setState(() {});
                                  }
                                },
                              ),
                            ],
                          )
                        : null,
                    onTap: _mode != _ListMode.normal
                        ? () {
                            setState(() {
                              if (_selectedWordIds.contains(word.id)) {
                                _selectedWordIds.remove(word.id);
                              } else {
                                _selectedWordIds.add(word.id);
                              }
                            });
                          }
                        : () => _showWordDetails(word),
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: word.japanese));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.copiedToClipboard,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: _mode == _ListMode.normal
          ? FloatingActionButton(
              onPressed: _startTraining,
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              child: Icon(Icons.play_arrow, size: 32),
            )
          : FloatingActionButton.extended(
              onPressed: _selectedWordIds.isEmpty
                  ? null
                  : () {
                      if (_mode == _ListMode.selectToDelete) {
                        _deleteSelectedWords();
                      } else {
                        _addSelectedToAnotherList();
                      }
                    },
              label: Text(
                _mode == _ListMode.selectToDelete ? 'Удалить' : 'Добавить',
              ),
              icon: Icon(
                _mode == _ListMode.selectToDelete ? Icons.delete : Icons.add,
              ),
              backgroundColor: _selectedWordIds.isEmpty
                  ? Theme.of(context).extension<AppColorsExtension>()!.textSecondary
                  : primaryColor,
              foregroundColor: Colors.white,
            ),
    );
  }
}
