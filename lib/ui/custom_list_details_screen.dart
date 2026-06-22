import 'dart:ui';
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
import 'widgets/acrylic_card.dart';
import 'widgets/glow_button.dart';
import 'widgets/progress_bar.dart';
import 'edit_custom_list_screen.dart';
import 'edit_word_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    if (!mounted) return;
    final selectedList = await showDialog<dynamic>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.addToAnotherList),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: localLists.length + 1,
              itemBuilder: (context, i) {
                if (i == localLists.length) {
                  return ListTile(
                    leading: const Icon(Icons.add),
                    title: Text(AppLocalizations.of(context)!.createLocalList),
                    onTap: () => Navigator.pop(context, 'create'),
                  );
                }
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

    if (selectedList == 'create') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const EditCustomListScreen(isLocalOnly: true),
        ),
      );
      return;
    }

    if (selectedList != null && selectedList is CustomList) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.wordsAdded)),
        );
      }
    }
  }

  void _showWordDetails(Word word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final primaryColor = Theme.of(context).colorScheme.primary;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (word.imageUrl != null && word.imageUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: word.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.customList.googleSheetId == null || widget.customList.googleSheetId!.isEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              size: 28,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditWordScreen(word: word),
                                ),
                              ).then((_) {
                                setState(() {});
                              });
                            },
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.volume_up,
                            size: 32,
                            color: primaryColor,
                          ),
                          onPressed: () async {
                            await ref
                                .read(ttsProvider)
                                .setLanguage(widget.customList.language);

                            final textToSpeak =
                                (word.reading != null && word.reading!.isNotEmpty)
                                ? word.reading!
                                : word.japanese;

                            await ref.read(ttsProvider).speak(textToSpeak);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                if (word.reading != null && word.reading!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.wordReading(word.reading!),
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(
                        context,
                      ).extension<AppColorsExtension>()!.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.wordTranslation(word.translation),
                  style: TextStyle(fontSize: 20),
                ),
                if (word.mnemonic != null && word.mnemonic!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.wordMnemonic(word.mnemonic!),
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(
                        context,
                      ).extension<AppColorsExtension>()!.textSecondary,
                    ),
                  ),
                ],
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
                Row(
                  children: [
                    Expanded(
                      child: GlowButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(AppLocalizations.of(context)!.close),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                Text(
                  AppLocalizations.of(context)!.allWordsLearned,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              GlowButton(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school),
                    const SizedBox(width: 8),
                    Text(
                      hasUnlearned
                          ? AppLocalizations.of(context)!.learnBtn
                          : AppLocalizations.of(context)!.reviewBtn,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlowButton(
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
                isPrimary: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.repeat),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.reviewBtn,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
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
    return PopScope(
      canPop: _mode == _ListMode.normal,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() {
          _mode = _ListMode.normal;
          _selectedWordIds.clear();
        });
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surface.withOpacity(0.5),
          elevation: 0,
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
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
                  } else if (val == 'settings') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditCustomListScreen(customList: widget.customList),
                      ),
                    ).then((_) => setState(() {}));
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
                  PopupMenuItem(
                    value: 'settings',
                    child: Text(AppLocalizations.of(context)!.editListTitle),
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
                  PopupMenuItem(
                    value: 'reset',
                    child: Text(AppLocalizations.of(context)!.resetProgress),
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
        body: Column(
          children: [
            ThinProgressBar(
              total: words.length,
              learned: words.where((w) => w.progress >= 5).length,
              inProgress: words
                  .where((w) => w.progress > 0 && w.progress < 5)
                  .length,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchWords,
                  hintStyle: TextStyle(
                    color: Theme.of(context)
                        .extension<AppColorsExtension>()!
                        .textSecondary
                        .withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context)
                        .extension<AppColorsExtension>()!
                        .textSecondary
                        .withValues(alpha: 0.6),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
            Expanded(
              child: () {
                final filteredWords = words.where((w) {
                  final q = _searchQuery.toLowerCase();
                  return w.japanese.toLowerCase().contains(q) ||
                      w.translation.toLowerCase().contains(q);
                }).toList();

                if (filteredWords.isEmpty) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.listEmpty),
                  );
                }

                final bool isEditingMode = _mode == _ListMode.selectToDelete && !isGoogleSheetList;

                if (_searchQuery.isNotEmpty || !isEditingMode) {
                  return ListView.builder(
                    itemCount: filteredWords.length,
                    itemBuilder: (context, index) {
                      final word = filteredWords[index];
                      final isLearned = word.progress >= 5;

                      return AcrylicCard(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        color: _selectedWordIds.contains(word.id)
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1)
                            : (isLearned
                                  ? Theme.of(context)
                                        .extension<AppColorsExtension>()!
                                        .successBackground
                                  : null),
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
                              color: isLearned
                                  ? Theme.of(context)
                                        .extension<AppColorsExtension>()!
                                        .successText
                                  : null,
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
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        color: isLearned
                                            ? Theme.of(context)
                                                  .extension<
                                                    AppColorsExtension
                                                  >()!
                                                  .success
                                            : Theme.of(context)
                                                  .extension<
                                                    AppColorsExtension
                                                  >()!
                                                  .iconBlue,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Checkbox(
                                      value: isLearned,
                                      activeColor: Theme.of(context)
                                          .extension<AppColorsExtension>()!
                                          .success,
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
                            Clipboard.setData(
                              ClipboardData(text: word.japanese),
                            );
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
                        ),
                      );
                    },
                  );
                } else {
                  filteredWords.sort(
                    (a, b) => a.orderIndex.compareTo(b.orderIndex),
                  );
                  return ReorderableListView.builder(
                    itemCount: filteredWords.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final word = filteredWords.removeAt(oldIndex);
                      filteredWords.insert(newIndex, word);
                      await ref
                          .read(databaseServiceProvider)
                          .updateWordsOrder(filteredWords);
                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      final word = filteredWords[index];
                      final isLearned = word.progress >= 5;

                      return AcrylicCard(
                        key: ValueKey(word.id),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        color: _selectedWordIds.contains(word.id)
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1)
                            : (isLearned
                                  ? Theme.of(context)
                                        .extension<AppColorsExtension>()!
                                        .successBackground
                                  : null),
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
                              color: isLearned
                                  ? Theme.of(context)
                                        .extension<AppColorsExtension>()!
                                        .successText
                                  : null,
                            ),
                          ),
                          subtitle: Text(word.translation),
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(
                              Icons.drag_handle,
                              color: Colors.grey,
                            ),
                          ),
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
                            Clipboard.setData(
                              ClipboardData(text: word.japanese),
                            );
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
                        ),
                      );
                    },
                  );
                }
              }(),
            ),
          ],
        ),
        floatingActionButton: _mode == _ListMode.normal
            ? SizedBox(
                width: 64,
                height: 64,
                child: GlowButton(
                  padding: EdgeInsets.zero,
                  borderRadius: 100,
                  onPressed: _startTraining,
                  child: const Icon(Icons.play_arrow, size: 32),
                ),
              )
            : SizedBox(
                height: 56,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlowButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      borderRadius: 100,
                      isPrimary: false,
                      onPressed: () => setState(() {
                        _mode = _ListMode.normal;
                        _selectedWordIds.clear();
                      }),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    const SizedBox(width: 16),
                    GlowButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      borderRadius: 100,
                      onPressed: _selectedWordIds.isEmpty
                          ? null
                          : () {
                              if (_mode == _ListMode.selectToDelete) {
                                _deleteSelectedWords();
                              } else {
                                _addSelectedToAnotherList();
                              }
                            },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _mode == _ListMode.selectToDelete
                                ? Icons.delete
                                : Icons.add,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _mode == _ListMode.selectToDelete
                                ? AppLocalizations.of(context)!.deleteBtn
                                : AppLocalizations.of(context)!.addBtn,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
