import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/word.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'profile_service.dart';
import 'word_image_files.dart';
import '../models/custom_list.dart';
import '../models/rush_session.dart';
import '../models/settings.dart';
import '../models/training_session.dart';
import '../models/word_progress_change.dart';
import '../../utils/atomic_file_write.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService should be overridden in main.dart');
});

class DatabaseService {
  late final Isar isar;

  static const _schemas = [
    WordSchema,
    CustomListSchema,
    SettingsSchema,
    TrainingSessionSchema,
    RushSessionSchema,
  ];
  static const _recoveredPrefix = 'recovered_';
  static final _recoveredName = RegExp(r'^recovered_[0-9a-f-]{36}$');

  File _activeDatabaseMarker(Directory directory) =>
      File('${directory.path}/quizzer_active_database');

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final marker = _activeDatabaseMarker(directory);
    var name = Isar.defaultName;
    if (await marker.exists()) {
      name = (await marker.readAsString()).trim();
      if (!_recoveredName.hasMatch(name) ||
          !await File('${directory.path}/$name.isar').exists()) {
        throw const FileSystemException('The active database is missing or invalid');
      }
    }

    final existing = Isar.getInstance(name);
    if (existing != null) {
      isar = existing;
      await _initSettings();
      return;
    }

    final databaseFile = File('${directory.path}/$name.isar');
    File? beforeOpenCopy;
    if (await databaseFile.exists()) {
      await _checkIsarMetadata(databaseFile);
      beforeOpenCopy = await _preserveBeforeOpen(databaseFile);
    }
    isar = await Isar.open(_schemas, directory: directory.path, name: name);
    try {
      if (beforeOpenCopy == null) {
        await _initSettings();
      } else if (await isar.settings.get(0) == null) {
        // An initialized Quizzer database always has this singleton.
        // Keep the source copy if the engine opened an empty replacement.
        throw FileSystemException(
          'The existing profile is unavailable',
          beforeOpenCopy.path,
        );
      }
    } catch (_) {
      await isar.close();
      rethrow;
    }
    if (beforeOpenCopy != null) {
      try {
        if (await beforeOpenCopy.exists()) await beforeOpenCopy.delete();
      } on FileSystemException {
        // Leaving the pre-open copy is safe when it cannot be removed.
      }
    }
  }

  static Future<File> _preserveBeforeOpen(File file) async {
    final preserved = File('${file.path}.before-open');
    if (await preserved.exists()) return preserved;
    final temporary = File('${preserved.path}.${const Uuid().v4()}.tmp');
    try {
      await file.copy(temporary.path);
      if (!await preserved.exists()) await temporary.rename(preserved.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
    return preserved;
  }

  static Future<void> _checkIsarMetadata(File file) async {
    // Isar 3's MDBX metadata stores its format version followed by the
    // seven magic bytes. MDBX can recover from another metadata page.
    const metadataOffset = 21;
    const magic = [0x11, 0x4c, 0xef, 0xbd, 0x9d, 0x65, 0x59];
    const metadataPageSizes = [256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536];
    final reader = await file.open();
    try {
      final prefix = await reader.read(
        2 * metadataPageSizes.last + metadataOffset + magic.length,
      );
      bool hasMagicAt(int offset) {
        final start = offset + metadataOffset;
        if (start + magic.length > prefix.length) return false;
        for (final (index, byte) in magic.indexed) {
          if (prefix[start + index] != byte) return false;
        }
        return true;
      }

      if (hasMagicAt(0)) return;
      for (final pageSize in metadataPageSizes) {
        if (hasMagicAt(pageSize) || hasMagicAt(2 * pageSize)) return;
      }
      throw FileSystemException('Isar metadata is missing or invalid', file.path);
    } finally {
      await reader.close();
    }
  }

  /// Restores a backup into a new database and selects it after a successful import.
  Future<void> initFromAutoBackup() async {
    final directory = await getApplicationDocumentsDirectory();
    final name = '$_recoveredPrefix${const Uuid().v4()}';
    isar = await Isar.open(
      _schemas,
      directory: directory.path,
      name: name,
      relaxedDurability: false,
    );
    try {
      if (!await ProfileService.restoreFromAutoBackup(this)) {
        throw const FormatException('Unable to restore the local profile backup');
      }
      await _initSettings();
      await writeFileAtomically(_activeDatabaseMarker(directory), name);
    } catch (_) {
      await isar.close();
      rethrow;
    }
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

    // Fix Isar default value for new fields (minInt)
    if (settings.targetWordRepetitions < 1) {
      settings.targetWordRepetitions = 3;
      needsSave = true;
    }

    if (settings.randomWordNotificationIntervalMinutes < 1) {
      settings.randomWordNotificationIntervalMinutes = 60;
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

          final currentImage = lWord.imageUrl;
          if (currentImage != dWord.imageUrl &&
              WordImageFiles.managedReference(currentImage) == null) {
            if (currentImage != null && WordImageFiles.isRemote(currentImage)) {
              try {
                CachedNetworkImage.evictFromCache(currentImage);
              } catch (_) {}
            }
            lWord.imageUrl = dWord.imageUrl;
          }

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

  Future<List<Word>> getAllWords() async {
    return await isar.words.where().findAll();
  }

  Future<void> toggleWordLearned(Word word, bool isLearned) async {
    final saved = await isar.writeTxn(() async {
      final current = await isar.words.get(word.id);
      if (current == null) return null;

      final now = DateTime.now();
      if (isLearned && !current.isLearned) {
        current.beginReviewSchedule(now);
      } else if (!isLearned) {
        current.clearReviewSchedule();
      }
      current.progress = isLearned ? 5 : 0;
      current.isManuallyLearned = isLearned;
      current.lastTrained = now;
      await isar.words.put(current);
      return current;
    });
    if (saved != null) {
      word
        ..progress = saved.progress
        ..isManuallyLearned = saved.isManuallyLearned
        ..lastTrained = saved.lastTrained
        ..nextReviewAt = saved.nextReviewAt
        ..reviewIntervalIndex = saved.reviewIntervalIndex;
    }
  }

  Future<void> resetProgressForList(CustomList list) async {
    await isar.writeTxn(() async {
      final current = await isar.customLists.get(list.id);
      if (current == null) return;
      await current.words.load();
      final words = current.words.toList();
      for (final word in words) {
        word
          ..progress = 0
          ..isManuallyLearned = false
          ..clearReviewSchedule();
      }
      await isar.words.putAll(words);
    });
    await list.words.load(overrideChanges: true);
  }

  Future<void> updateWord(Word word) async {
    await isar.writeTxn(() async {
      final current = await isar.words.get(word.id);
      if (current == null) return;
      current
        ..japanese = word.japanese
        ..reading = word.reading
        ..translation = word.translation
        ..mnemonic = word.mnemonic
        ..imageUrl = word.imageUrl;
      await isar.words.put(current);
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
      final ids = words.map((word) => word.id).toList();
      final current = await isar.words.getAll(ids);
      for (final (index, word) in current.indexed) {
        word?.orderIndex = index;
      }
      await isar.words.putAll(current.nonNulls.toList());
    });
    for (final (index, word) in words.indexed) {
      word.orderIndex = index;
    }
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
    final lists = await isar.customLists.where().findAll();
    bool needsSave = false;
    for (var list in lists) {
      if (list.targetWordRepetitions < 1) {
        list.targetWordRepetitions = 3;
        needsSave = true;
      }
    }
    if (needsSave) {
      await isar.writeTxn(() async {
        await isar.customLists.putAll(lists);
      });
    }
    return lists;
  }

  Future<void> saveCustomList(CustomList list) async {
    await isar.writeTxn(() async {
      await isar.customLists.put(list);
      await list.words.save();
    });
  }

  Future<bool> saveRushErrorLimitOverride(int listId, int? limit) async {
    if (limit != null && RushSession.parseErrorLimit(limit) == null) {
      throw ArgumentError.value(limit, 'limit');
    }
    return isar.writeTxn(() async {
      final list = await isar.customLists.get(listId);
      if (list == null) return false;
      list.rushErrorLimitOverride = limit;
      await isar.customLists.put(list);
      return true;
    });
  }

  Future<void> deleteCustomList(int id) async {
    final list = await isar.customLists.get(id);
    if (list != null) {
      await isar.writeTxn(() async {
        await isar.customLists.delete(id);
        final sessions = await isar.rushSessions
            .where()
            .customListIdEqualTo(id)
            .findAll();
        for (final session in sessions) {
          session.customListId = null;
        }
        await isar.rushSessions.putAll(sessions);
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

  Future<int> saveTrainingSession(
    int? customListId, {
    List<WordProgressChange> progressChanges = const [],
    Set<int> independentlyRecalledReviewIds = const {},
  }) async {
    return isar.writeTxn(() async {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day);
      for (final change in progressChanges) {
        if (change.oldProgress == change.newProgress) continue;

        final word = await isar.words.get(change.word.id);
        if (word == null ||
            word.isManuallyLearned ||
            word.progress != change.oldProgress) {
          continue;
        }

        final wasLearned = word.isLearned;
        word.progress = change.newProgress;
        if (word.isLearned && !wasLearned) {
          word.timesLearned += 1;
          word.beginReviewSchedule(now);
        } else if (!word.isLearned) {
          word.clearReviewSchedule();
        }
        word.lastTrained = now;
        await isar.words.put(word);
      }

      var rescheduledCount = 0;
      for (final wordId in independentlyRecalledReviewIds) {
        final word = await isar.words.get(wordId);
        if (word == null || !word.advanceReviewIfDue(now)) continue;
        word.lastTrained = now;
        await isar.words.put(word);
        rescheduledCount++;
      }

      final session = TrainingSession()
        ..date = date
        ..customListId = customListId;
      await isar.trainingSessions.put(session);
      return rescheduledCount;
    });
  }

  Future<List<TrainingSession>> getAllTrainingSessions() async {
    return await isar.trainingSessions.where().findAll();
  }

  Future<void> saveRushSession(RushSession session) async {
    await isar.writeTxn(() async {
      final listId = session.customListId;
      if (listId != null && await isar.customLists.get(listId) == null) {
        session.customListId = null;
      }
      await isar.rushSessions.put(session);
    });
  }

  Future<List<RushSession>> getRushSessions({int? customListId}) {
    final sessions = isar.rushSessions.where();
    if (customListId == null) return sessions.sortByDateDesc().findAll();
    return sessions.customListIdEqualTo(customListId).sortByDateDesc().findAll();
  }

  Future<void> setStreakCheat(int desiredStreak) async {
    final existingSessions = await isar.trainingSessions.where().findAll();
    final existingDates = existingSessions
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet();

    await isar.writeTxn(() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (desiredStreak > 0) {
        final sessionsToAdd = <TrainingSession>[];
        for (int i = 0; i < desiredStreak; i++) {
          final checkDate = today.subtract(Duration(days: i));
          if (!existingDates.contains(checkDate)) {
            sessionsToAdd.add(
              TrainingSession()
                ..date = checkDate
                ..customListId = null,
            );
          }
        }

        if (sessionsToAdd.isNotEmpty) {
          await isar.trainingSessions.putAll(sessionsToAdd);
        }

        final breakingDate = today.subtract(Duration(days: desiredStreak));
        final sessionsToDelete = existingSessions.where((s) {
          final d = DateTime(s.date.year, s.date.month, s.date.day);
          return d == breakingDate;
        }).map((s) => s.id).toList();

        if (sessionsToDelete.isNotEmpty) {
          await isar.trainingSessions.deleteAll(sessionsToDelete);
        }
      } else {
        final sessionsToDelete = existingSessions.where((s) {
          final d = DateTime(s.date.year, s.date.month, s.date.day);
          return d == today || d == today.subtract(const Duration(days: 1));
        }).map((s) => s.id).toList();

        if (sessionsToDelete.isNotEmpty) {
          await isar.trainingSessions.deleteAll(sessionsToDelete);
        }
      }
    });
  }
}
