import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'database_service.dart';
import 'word_image_files.dart';
import '../models/settings.dart';
import '../models/custom_list.dart';
import '../models/rush_session.dart';
import '../models/word.dart';
import '../models/training_session.dart';
import '../../utils/atomic_file_write.dart';
import '../../utils/constants.dart';

class ProfileService {
  static Future<void> exportProfile(BuildContext context, DatabaseService db) async {
    try {
      final jsonStr = jsonEncode(await _exportData(db, includeLocalImages: true));

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${AppConstants.appName.toLowerCase()}_profile_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);

      if (context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'My ${AppConstants.appName} Profile',
            sharePositionOrigin: box != null
                ? box.localToGlobal(Offset.zero) & box.size
                : null,
          ),
        );

        if (!context.mounted || result.status == ShareResultStatus.dismissed) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.exportSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is WordImageProfileException
              ? l10n.profileImageAttachmentError
              : l10n.profileExportFailed)),
        );
      }
    }
  }

  static Future<File> _getAutoBackupFile() async {
    final docDir = await getApplicationDocumentsDirectory();
    return File('${docDir.path}/auto_backup.json');
  }

  static Future<void> createAutoBackup(DatabaseService db) async {
    try {
      final data = await _exportData(db);
      final file = await _getAutoBackupFile();
      
      // Safety guard: prevent overwriting a populated backup with an empty database
      if (file.existsSync() && (data['words'] as List).isEmpty) {
        try {
          final jsonStr = await file.readAsString();
          final oldData = jsonDecode(jsonStr) as Map<String, dynamic>;
          final oldWords = oldData['words'] as List<dynamic>?;
          if (oldWords != null && oldWords.isNotEmpty) {
            debugPrint('Safety check: preventing empty database from overwriting existing populated auto backup.');
            return;
          }
        } catch (_) {}
      }

      await writeFileAtomically(file, jsonEncode(data));
    } catch (e) {
      debugPrint('Failed to create auto backup: $e');
    }
  }

  static Future<Map<String, dynamic>> _exportData(
    DatabaseService db, {
    bool includeLocalImages = false,
  }) async {
    final settings = await db.getSettings();
    final lists = await db.getCustomLists();
    final words = await db.getAllWords();
    final sessions = await db.getAllTrainingSessions();
    final rushSessions = await db.getRushSessions();

    for (final list in lists) {
      await list.words.load();
      await list.learningQueue.load();
    }

    return {
      'settings': _settingsToJson(settings),
      'customLists': lists.map(_customListToJson).toList(),
      'words': [
        for (final word in words)
          {
            ..._wordToJson(word),
            if (includeLocalImages)
              'imageUrl': WordImageFiles.managedReference(word.imageUrl) ?? word.imageUrl,
          },
      ],
      'trainingSessions': sessions.map(_trainingSessionToJson).toList(),
      'rushSessions': rushSessions.map(_rushSessionToJson).toList(),
      if (includeLocalImages)
        'localImages': await WordImageFiles.exportImages(
          words.map((word) => word.imageUrl),
        ),
    };
  }

  static Future<bool> hasAutoBackup() async {
    final file = await _getAutoBackupFile();
    return file.existsSync();
  }

  static Future<bool> restoreFromAutoBackup(DatabaseService db) async {
    try {
      final file = await _getAutoBackupFile();
      if (!file.existsSync()) return false;

      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (data['settings'] is! Map<String, dynamic> ||
          data['words'] is! List ||
          data['customLists'] is! List) {
        throw const FormatException('Invalid automatic profile backup');
      }
      
      await _importData(db, data);
      return true;
    } catch (e) {
      debugPrint('Failed to restore auto backup: $e');
      return false;
    }
  }

  static Future<void> importProfile(BuildContext context, DatabaseService db) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        if (await file.length() > WordImageFiles.maxProfileFileBytes) {
          throw const WordImageProfileException();
        }
        final jsonStr = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonStr);

        await _importData(db, data);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.importSuccess)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is WordImageProfileException
              ? l10n.profileImageAttachmentError
              : '${l10n.importError}: $e')),
        );
      }
    }
  }

  static Future<void> _importData(DatabaseService db, Map<String, dynamic> data) async {
    final words = data['words'] as List<dynamic>?;
    final imageSources = words
        ?.whereType<Map<String, dynamic>>()
        .map((word) => word['imageUrl'])
        .whereType<String>();
    final images = await WordImageFiles.importImages(
      data['localImages'],
      imageSources ?? const [],
    );
    try {
      await _writeProfile(db, data, images);
    } catch (_) {
      await WordImageFiles.removeImportedImages(images.values);
      rethrow;
    }
  }

  static Future<void> _writeProfile(
    DatabaseService db,
    Map<String, dynamic> data,
    Map<String, ImportedWordImage> images,
  ) async {
    await db.isar.writeTxn(() async {
      // Import settings
      if (data.containsKey('settings')) {
        final settingsMap = data['settings'] as Map<String, dynamic>;
        final newSettings = _settingsFromJson(settingsMap);
        await db.isar.settings.put(newSettings);
      }

      // Import Words
      Map<int, int> oldToNewWordIdMap = {};
      if (data.containsKey('words')) {
        final wordsList = data['words'] as List<dynamic>;
        await db.isar.words.clear();
        for (var wMap in wordsList) {
          final oldId = wMap['id'] as int;
          final word = _wordFromJson(wMap);
          final image = images[WordImageFiles.managedReference(word.imageUrl)];
          if (image != null) word.imageUrl = image.reference;
          await db.isar.words.put(word);
          oldToNewWordIdMap[oldId] = word.id;
        }
      }

      // Import Custom Lists
      Map<int, int> oldToNewListIdMap = {};
      final replacesLists = data.containsKey('customLists');
      if (replacesLists) {
        final listsList = data['customLists'] as List<dynamic>;
        await db.isar.customLists.clear();
        for (var lMap in listsList) {
          final oldId = lMap['id'] as int;
          final list = _customListFromJson(lMap);
          await db.isar.customLists.put(list);
          oldToNewListIdMap[oldId] = list.id;

          // Restore links
          final wordsIds = (lMap['words'] as List<dynamic>).cast<int>();
          final learningQueueIds = (lMap['learningQueue'] as List<dynamic>).cast<int>();

          for (var wid in wordsIds) {
            final newId = oldToNewWordIdMap[wid];
            if (newId != null) {
              final word = await db.isar.words.get(newId);
              if (word != null) {
                list.words.add(word);
              }
            }
          }
          for (var wid in learningQueueIds) {
            final newId = oldToNewWordIdMap[wid];
            if (newId != null) {
              final word = await db.isar.words.get(newId);
              if (word != null) {
                list.learningQueue.add(word);
              }
            }
          }
          await list.words.save();
          await list.learningQueue.save();
        }
      }

      // Import Training Sessions
      if (data.containsKey('trainingSessions')) {
        final sessionsList = data['trainingSessions'] as List<dynamic>;
        await db.isar.trainingSessions.clear();
        for (var sMap in sessionsList) {
          final session = _trainingSessionFromJson(sMap);
          if (session.customListId != null) {
            session.customListId = oldToNewListIdMap[session.customListId];
          }
          await db.isar.trainingSessions.put(session);
        }
      }

      if (replacesLists || data.containsKey('rushSessions')) {
        await db.isar.rushSessions.clear();
        final sessions = (data['rushSessions'] as List?) ?? [];
        for (final sessionMap in sessions) {
          final session = _rushSessionFromJson(sessionMap);
          final listId = session.customListId;
          if (replacesLists) {
            session.customListId = oldToNewListIdMap[listId];
          } else if (listId != null &&
              await db.isar.customLists.get(listId) == null) {
            session.customListId = null;
          }
          await db.isar.rushSessions.put(session);
        }
      }
    });
  }

  // Mappers

  static Map<String, dynamic> _settingsToJson(Settings settings) {
    return {
      'id': settings.id,
      'questionsCount': settings.questionsCount,
      'learningQueueSize': settings.learningQueueSize,
      'targetWordRepetitions': settings.targetWordRepetitions,
      'notificationsEnabled': settings.notificationsEnabled,
      'streakNotificationsEnabled': settings.streakNotificationsEnabled,
      'notificationIntervalMinutes': settings.notificationIntervalMinutes,
      'notificationTimeStart': settings.notificationTimeStart,
      'notificationTimeEnd': settings.notificationTimeEnd,
      'autoPlayVoice': settings.autoPlayVoice,
      'playSoundEffects': settings.playSoundEffects,
      'hapticFeedbackEnabled': settings.hapticFeedbackEnabled,
      'questionWordToTranslate': settings.questionWordToTranslate,
      'questionTranslateToWord': settings.questionTranslateToWord,
      'questionWordToReading': settings.questionWordToReading,
      'questionReadingToWord': settings.questionReadingToWord,
      'questionVoiceToTranslate': settings.questionVoiceToTranslate,
      'questionVoiceToWord': settings.questionVoiceToWord,
      'questionVoiceToWordInput': settings.questionVoiceToWordInput,
      'questionVoiceToWordConstructor': settings.questionVoiceToWordConstructor,
      'questionTranslateToWordInput': settings.questionTranslateToWordInput,
      'questionTranslateToWordConstructor': settings.questionTranslateToWordConstructor,
      'autoAdvanceToNextQuestion': settings.autoAdvanceToNextQuestion,
      'learningHintsDisabled': settings.learningHintsDisabled,
      'reviewHintsDisabled': settings.reviewHintsDisabled,
      'defaultRushErrorLimit': settings.defaultRushErrorLimit,
      'useSimilarWordsForOptions': settings.useSimilarWordsForOptions,
      'useSpoiledWordsForOptions': settings.useSpoiledWordsForOptions,
      'confusableCharactersSheetId': settings.confusableCharactersSheetId,
      'customConfusableGroups': settings.customConfusableGroups,
      'questionImageToWord': settings.questionImageToWord,
      'hasSeenTutorial': settings.hasSeenTutorial,
      'flashcardShowWord': settings.flashcardShowWord,
      'flashcardShowReading': settings.flashcardShowReading,
      'flashcardShowTranslation': settings.flashcardShowTranslation,
      'flashcardShowImage': settings.flashcardShowImage,
      'randomWordNotificationEnabled': settings.randomWordNotificationEnabled,
      'randomWordNotificationIntervalMinutes': settings.randomWordNotificationIntervalMinutes,
      'randomWordNotificationListId': settings.randomWordNotificationListId,
      'flashcardShuffleCards': settings.flashcardShuffleCards,
    };
  }

  static Settings _settingsFromJson(Map<String, dynamic> map) {
    return Settings()
      ..id = map['id'] ?? 0
      ..questionsCount = map['questionsCount'] ?? 50
      ..learningQueueSize = map['learningQueueSize'] ?? 50
      ..targetWordRepetitions = map['targetWordRepetitions'] ?? 3
      ..notificationsEnabled = map['notificationsEnabled'] ?? true
      ..streakNotificationsEnabled = map['streakNotificationsEnabled'] ?? false
      ..notificationIntervalMinutes = map['notificationIntervalMinutes'] ?? 60
      ..notificationTimeStart = map['notificationTimeStart'] ?? '10:00'
      ..notificationTimeEnd = map['notificationTimeEnd'] ?? '22:00'
      ..autoPlayVoice = map['autoPlayVoice'] ?? false
      ..playSoundEffects = map['playSoundEffects'] ?? true
      ..hapticFeedbackEnabled = map['hapticFeedbackEnabled'] ?? true
      ..questionWordToTranslate = map['questionWordToTranslate'] ?? true
      ..questionTranslateToWord = map['questionTranslateToWord'] ?? true
      ..questionWordToReading = map['questionWordToReading'] ?? true
      ..questionReadingToWord = map['questionReadingToWord'] ?? true
      ..questionVoiceToTranslate = map['questionVoiceToTranslate'] ?? true
      ..questionVoiceToWord = map['questionVoiceToWord'] ?? true
      ..questionVoiceToWordInput = map['questionVoiceToWordInput'] ?? true
      ..questionVoiceToWordConstructor = map['questionVoiceToWordConstructor'] ?? true
      ..questionTranslateToWordInput = map['questionTranslateToWordInput'] ?? true
      ..questionTranslateToWordConstructor = map['questionTranslateToWordConstructor'] ?? true
      ..autoAdvanceToNextQuestion = map['autoAdvanceToNextQuestion'] ?? true
      ..learningHintsDisabled = map['learningHintsDisabled'] == true
      ..reviewHintsDisabled = map['reviewHintsDisabled'] == true
      ..defaultRushErrorLimit = RushSession.parseErrorLimit(
        map['defaultRushErrorLimit'],
      )
      ..useSimilarWordsForOptions = map['useSimilarWordsForOptions'] ?? false
      ..useSpoiledWordsForOptions = map['useSpoiledWordsForOptions'] ?? false
      ..confusableCharactersSheetId = map['confusableCharactersSheetId']
      ..customConfusableGroups = (map['customConfusableGroups'] as List?)?.cast<String>() ?? []
      ..questionImageToWord = map['questionImageToWord'] ?? true
      ..hasSeenTutorial = map['hasSeenTutorial'] ?? false
      ..flashcardShowWord = map['flashcardShowWord'] ?? true
      ..flashcardShowReading = map['flashcardShowReading'] ?? true
      ..flashcardShowTranslation = map['flashcardShowTranslation'] ?? true
      ..flashcardShowImage = map['flashcardShowImage'] ?? true
      ..randomWordNotificationEnabled = map['randomWordNotificationEnabled'] ?? false
      ..randomWordNotificationIntervalMinutes = map['randomWordNotificationIntervalMinutes'] ?? 60
      ..randomWordNotificationListId = map['randomWordNotificationListId']
      ..flashcardShuffleCards = map['flashcardShuffleCards'] ?? false;
  }

  static Map<String, dynamic> _customListToJson(CustomList list) {
    return {
      'id': list.id,
      'name': list.name,
      'googleSheetId': list.googleSheetId,
      'googleSheetTabName': list.googleSheetTabName,
      'language': list.language,
      'syncOnStartup': list.syncOnStartup,
      'words': list.words.map((e) => e.id).toList(),
      'learningQueue': list.learningQueue.map((e) => e.id).toList(),
      'useCustomTrainingSettings': list.useCustomTrainingSettings,
      'questionsCount': list.questionsCount,
      'learningQueueSize': list.learningQueueSize,
      'targetWordRepetitions': list.targetWordRepetitions,
      'rushErrorLimitOverride': list.rushErrorLimitOverride,
      'useCustomQuestionSettings': list.useCustomQuestionSettings,
      'questionWordToTranslate': list.questionWordToTranslate,
      'questionTranslateToWord': list.questionTranslateToWord,
      'questionWordToReading': list.questionWordToReading,
      'questionReadingToWord': list.questionReadingToWord,
      'questionVoiceToTranslate': list.questionVoiceToTranslate,
      'questionVoiceToWord': list.questionVoiceToWord,
      'questionVoiceToWordInput': list.questionVoiceToWordInput,
      'questionVoiceToWordConstructor': list.questionVoiceToWordConstructor,
      'questionTranslateToWordInput': list.questionTranslateToWordInput,
      'questionTranslateToWordConstructor': list.questionTranslateToWordConstructor,
      'emoji': list.emoji,
      'isPinned': list.isPinned,
      'questionImageToWord': list.questionImageToWord,
      'flashcardShuffleCards': list.flashcardShuffleCards,
    };
  }

  static CustomList _customListFromJson(Map<String, dynamic> map) {
    return CustomList()
      ..name = map['name'] ?? 'Imported List'
      ..googleSheetId = map['googleSheetId']
      ..googleSheetTabName = map['googleSheetTabName']
      ..language = map['language'] ?? 'ja-JP'
      ..syncOnStartup = map['syncOnStartup'] ?? false
      ..useCustomTrainingSettings = map['useCustomTrainingSettings'] ?? false
      ..questionsCount = map['questionsCount'] ?? 20
      ..learningQueueSize = map['learningQueueSize'] ?? 20
      ..targetWordRepetitions = map['targetWordRepetitions'] ?? 3
      ..rushErrorLimitOverride = RushSession.parseErrorLimit(
        map['rushErrorLimitOverride'],
      )
      ..useCustomQuestionSettings = map['useCustomQuestionSettings'] ?? false
      ..questionWordToTranslate = map['questionWordToTranslate'] ?? true
      ..questionTranslateToWord = map['questionTranslateToWord'] ?? true
      ..questionWordToReading = map['questionWordToReading'] ?? true
      ..questionReadingToWord = map['questionReadingToWord'] ?? true
      ..questionVoiceToTranslate = map['questionVoiceToTranslate'] ?? true
      ..questionVoiceToWord = map['questionVoiceToWord'] ?? true
      ..questionVoiceToWordInput = map['questionVoiceToWordInput'] ?? true
      ..questionVoiceToWordConstructor = map['questionVoiceToWordConstructor'] ?? true
      ..questionTranslateToWordInput = map['questionTranslateToWordInput'] ?? true
      ..questionTranslateToWordConstructor = map['questionTranslateToWordConstructor'] ?? true
      ..emoji = map['emoji']
      ..isPinned = map['isPinned'] ?? false
      ..questionImageToWord = map['questionImageToWord'] ?? true
      ..flashcardShuffleCards = map['flashcardShuffleCards'] ?? false;
  }

  static Map<String, dynamic> _wordToJson(Word word) {
    return {
      'id': word.id,
      'sheetId': word.sheetId,
      'japanese': word.japanese,
      'reading': word.reading,
      'translation': word.translation,
      'imageUrl': word.imageUrl,
      'mnemonic': word.mnemonic,
      'progress': word.progress,
      'lastTrained': word.lastTrained?.toIso8601String(),
      'nextReviewAt': word.nextReviewAt?.toUtc().toIso8601String(),
      'reviewIntervalIndex': word.reviewIntervalIndex,
      'timesLearned': word.timesLearned,
      'isManuallyLearned': word.isManuallyLearned,
      'orderIndex': word.orderIndex,
    };
  }

  static Word _wordFromJson(Map<String, dynamic> map) {
    final nextReviewAt = map['nextReviewAt'];
    final reviewIntervalIndex = map['reviewIntervalIndex'];
    return Word()
      ..sheetId = map['sheetId'] ?? 0
      ..japanese = map['japanese'] ?? ''
      ..reading = map['reading']
      ..translation = map['translation'] ?? ''
      ..imageUrl = map['imageUrl']
      ..mnemonic = map['mnemonic']
      ..progress = map['progress'] ?? 0
      ..nextReviewAt = nextReviewAt is String
          ? DateTime.tryParse(nextReviewAt)
          : null
      ..reviewIntervalIndex = reviewIntervalIndex is int
          ? reviewIntervalIndex
          : null
      ..timesLearned = map['timesLearned'] ?? 0
      ..isManuallyLearned = map['isManuallyLearned'] ?? false
      ..orderIndex = map['orderIndex'] ?? 0
      ..lastTrained = map['lastTrained'] != null ? DateTime.tryParse(map['lastTrained']) : null;
  }

  static Map<String, dynamic> _trainingSessionToJson(TrainingSession session) {
    return {
      'id': session.id,
      'date': session.date.toIso8601String(),
      'customListId': session.customListId,
    };
  }

  static TrainingSession _trainingSessionFromJson(Map<String, dynamic> map) {
    return TrainingSession()
      ..date = DateTime.parse(map['date'])
      ..customListId = map['customListId'];
  }

  static Map<String, dynamic> _rushSessionToJson(RushSession session) {
    return {
      'customListId': session.customListId,
      'date': session.date.toUtc().toIso8601String(),
      'correctAnswers': session.correctAnswers,
      'answeredQuestions': session.answeredQuestions,
      'totalWords': session.totalWords,
      'errorLimit': session.errorLimit,
    };
  }

  static RushSession _rushSessionFromJson(Map<String, dynamic> map) {
    return RushSession()
      ..customListId = map['customListId']
      ..date = DateTime.parse(map['date'])
      ..correctAnswers = map['correctAnswers']
      ..answeredQuestions = map['answeredQuestions']
      ..totalWords = map['totalWords']
      ..errorLimit =
          RushSession.parseErrorLimit(map['errorLimit']) ??
          RushSession.defaultErrorLimit;
  }
}
