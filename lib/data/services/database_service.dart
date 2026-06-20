import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/custom_list.dart';
import '../models/settings.dart';
import '../models/training_session.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService should be overridden in main.dart');
});

class DatabaseService {
  late final Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    try {
      isar = await Isar.open([
        WordSchema,
        CustomListSchema,
        SettingsSchema,
        TrainingSessionSchema,
      ], directory: dir.path);
    } catch (e) {
      // Fallback for schema mismatch during development
      final file = File('${dir.path}/default.isar');
      final lockFile = File('${dir.path}/default.isar.lock');
      if (file.existsSync()) file.deleteSync();
      if (lockFile.existsSync()) lockFile.deleteSync();

      isar = await Isar.open([
        WordSchema,
        CustomListSchema,
        SettingsSchema,
        TrainingSessionSchema,
      ], directory: dir.path);
    }

    await _initSettings();
    await _applySpacedRepetition();
    await cleanUpOrphanedWords();
  }

  Future<void> _initSettings() async {
    final settings = await isar.settings.get(0);
    if (settings == null) {
      await isar.writeTxn(() async {
        await isar.settings.put(Settings()..id = 0);
      });
    }
  }

  Future<Settings> getSettings() async {
    final settings = (await isar.settings.get(0))!;
    bool needsSave = false;

    // Check if learning queue size is invalid (negative or zero)
    if (settings.learningQueueSize < 1) {
      settings.learningQueueSize = 50; // default safe value;
      needsSave = true;
    }

    if (needsSave) {
      await isar.writeTxn(() async {
        await isar.settings.put(settings);
      });
    }

    return settings;
  }

  Future<void> saveSettings(Settings settings) async {
    await isar.writeTxn(() async {
      await isar.settings.put(settings);
    });
  }

  Future<void> syncWordsForList(
    CustomList list,
    List<Word> downloadedWords,
  ) async {
    await isar.writeTxn(() async {
      await list.words.load();
      final localWordsInList = list.words.toList();
      final localWordsMap = {for (var w in localWordsInList) w.sheetId: w};

      final updatedOrNewWords = <Word>[];
      final downloadedIds = <int>{};

      for (var dWord in downloadedWords) {
        downloadedIds.add(dWord.sheetId);

        if (localWordsMap.containsKey(dWord.sheetId)) {
          final lWord = localWordsMap[dWord.sheetId]!;
          lWord.japanese = dWord.japanese;
          lWord.reading = dWord.reading;
          lWord.translation = dWord.translation;

          if (lWord.imageUrl != dWord.imageUrl) {
            if (lWord.imageUrl != null && lWord.imageUrl!.isNotEmpty) {
              try {
                CachedNetworkImage.evictFromCache(lWord.imageUrl!);
              } catch (_) {}
            }
          }

          lWord.imageUrl = dWord.imageUrl;
          lWord.mnemonic = dWord.mnemonic;
          updatedOrNewWords.add(lWord);
        } else {
          updatedOrNewWords.add(dWord);
        }
      }

      for (int i = 0; i < updatedOrNewWords.length; i++) {
        updatedOrNewWords[i].orderIndex = i;
      }

      await isar.words.putAll(updatedOrNewWords);

      // Replace the custom list's words completely
      list.words.clear();
      list.words.addAll(updatedOrNewWords);
      await isar.customLists.put(list);
      await list.words.save();
    });

    await cleanUpOrphanedWords();
  }

  /// Lowers progress by 1 if a word was learned but hasn't been trained for >= 7 days
  Future<void> _applySpacedRepetition() async {
    final now = DateTime.now();
    final learnedWords = await isar.words.filter().progressEqualTo(5).findAll();

    final wordsToUpdate = <Word>[];
    for (var word in learnedWords) {
      if (word.isManuallyLearned) continue;
      if (word.lastTrained != null) {
        final diff = now.difference(word.lastTrained!).inDays;
        if (diff >= 7) {
          word.progress = 4;
          wordsToUpdate.add(word);
        }
      }
    }

    if (wordsToUpdate.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.words.putAll(wordsToUpdate);
      });
    }
  }

  Future<List<Word>> getAllWords() async {
    return await isar.words.where().findAll();
  }

  Future<void> updateWordProgress(Word word, int newProgress) async {
    word.progress = newProgress;
    word.lastTrained = DateTime.now();
    await isar.writeTxn(() async {
      await isar.words.put(word);
    });
  }

  Future<void> toggleWordLearned(Word word, bool isLearned) async {
    word.progress = isLearned ? 5 : 0;
    word.isManuallyLearned = isLearned;
    // Removed logic of preserving previous progress based on user's comment
    word.lastTrained = DateTime.now();
    await isar.writeTxn(() async {
      await isar.words.put(word);
    });
  }

  Future<void> updateWord(Word word) async {
    await isar.writeTxn(() async {
      await isar.words.put(word);
    });
  }

  Future<void> deleteWordFromList(CustomList list, Word word) async {
    await isar.writeTxn(() async {
      list.words.remove(word);
      await list.words.save();
    });
    await cleanUpOrphanedWords();
  }

  Future<void> updateWordsOrder(List<Word> words) async {
    await isar.writeTxn(() async {
      for (int i = 0; i < words.length; i++) {
        words[i].orderIndex = i;
      }
      await isar.words.putAll(words);
    });
  }

  Future<void> updateLearningQueue(CustomList list, int queueSize) async {
    await isar.writeTxn(() async {
      await list.learningQueue.load();
      await list.words.load();

      // Remove learned words from queue
      final learnedInQueue = list.learningQueue
          .where((w) => w.progress >= 5)
          .toList();
      if (learnedInQueue.isNotEmpty) {
        list.learningQueue.removeAll(learnedInQueue);
      }

      final validQueue = list.learningQueue
          .where((w) => w.progress < 5)
          .toList();
      int needed = queueSize - validQueue.length;

      if (needed > 0) {
        final queueIds = validQueue.map((w) => w.id).toSet();
        final availableUnlearned = list.words
            .where((w) => w.progress < 5 && !queueIds.contains(w.id))
            .toList();

        availableUnlearned.shuffle();
        final newWords = availableUnlearned.take(needed).toList();
        if (newWords.isNotEmpty) {
          list.learningQueue.addAll(newWords);
        }
      } else if (needed < 0) {
        // Shrink the queue if settings changed to a smaller size
        final excess = validQueue.sublist(queueSize);
        list.learningQueue.removeAll(excess);
      }

      await list.learningQueue.save();
    });
  }

  // --- Custom Lists Methods ---

  Future<List<CustomList>> getCustomLists() async {
    return await isar.customLists.where().findAll();
  }

  Future<void> saveCustomList(CustomList list) async {
    await isar.writeTxn(() async {
      await isar.customLists.put(list);
      await list.words.save();
    });
  }

  Future<void> deleteCustomList(int id) async {
    final list = await isar.customLists.get(id);
    if (list != null) {
      await isar.writeTxn(() async {
        await isar.customLists.delete(id);
      });
      await cleanUpOrphanedWords();
    }
  }

  Future<void> cleanUpOrphanedWords() async {
    final lists = await isar.customLists.where().findAll();
    final usedWordIds = <int>{};
    for (var list in lists) {
      await list.words.load();
      usedWordIds.addAll(list.words.map((w) => w.id));
    }
    
    final allWords = await isar.words.where().findAll();
    final wordsToDelete = allWords
        .where((w) => !usedWordIds.contains(w.id))
        .map((w) => w.id)
        .toList();
    
    if (wordsToDelete.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.words.deleteAll(wordsToDelete);
      });
    }
  }

  // --- Training Sessions Methods ---

  Future<void> saveTrainingSession(int? customListId) async {
    final now = DateTime.now();
    // Normalize to midnight
    final date = DateTime(now.year, now.month, now.day);

    await isar.writeTxn(() async {
      final session = TrainingSession()
        ..date = date
        ..customListId = customListId;
      await isar.trainingSessions.put(session);
    });
  }

  Future<List<TrainingSession>> getAllTrainingSessions() async {
    return await isar.trainingSessions.where().findAll();
  }
}
