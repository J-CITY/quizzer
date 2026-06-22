import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:isar/isar.dart';
import 'database_service.dart';
import '../models/settings.dart';
import '../models/custom_list.dart';
import '../models/word.dart';
import '../models/training_session.dart';
import '../../utils/constants.dart';

class ProfileService {
  static Future<void> exportProfile(BuildContext context, DatabaseService db) async {
    try {
      final settings = await db.getSettings();
      final lists = await db.getCustomLists();
      final words = await db.getAllWords();
      final sessions = await db.getAllTrainingSessions();

      final data = {
        'settings': _settingsToJson(settings),
        'customLists': lists.map((e) => _customListToJson(e)).toList(),
        'words': words.map((e) => _wordToJson(e)).toList(),
        'trainingSessions': sessions.map((e) => _trainingSessionToJson(e)).toList(),
      };

      final jsonStr = jsonEncode(data);

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${AppConstants.appName.toLowerCase()}_profile_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);

      if (context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'My ${AppConstants.appName} Profile',
          sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.exportSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
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
        final jsonStr = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonStr);

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
              await db.isar.words.put(word);
              oldToNewWordIdMap[oldId] = word.id;
            }
          }

          // Import Custom Lists
          Map<int, int> oldToNewListIdMap = {};
          if (data.containsKey('customLists')) {
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
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.importSuccess)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.importError}: $e')),
        );
      }
    }
  }

  // Mappers

  static Map<String, dynamic> _settingsToJson(Settings settings) {
    return {
      'id': settings.id,
      'questionsCount': settings.questionsCount,
      'learningQueueSize': settings.learningQueueSize,
      'notificationsEnabled': settings.notificationsEnabled,
      'streakNotificationsEnabled': settings.streakNotificationsEnabled,
      'notificationIntervalMinutes': settings.notificationIntervalMinutes,
      'notificationTimeStart': settings.notificationTimeStart,
      'notificationTimeEnd': settings.notificationTimeEnd,
      'autoPlayVoice': settings.autoPlayVoice,
      'playSoundEffects': settings.playSoundEffects,
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
      'useSimilarWordsForOptions': settings.useSimilarWordsForOptions,
      'useSpoiledWordsForOptions': settings.useSpoiledWordsForOptions,
      'confusableCharactersSheetId': settings.confusableCharactersSheetId,
      'customConfusableGroups': settings.customConfusableGroups,
      'questionImageToWord': settings.questionImageToWord,
      'hasSeenTutorial': settings.hasSeenTutorial,
    };
  }

  static Settings _settingsFromJson(Map<String, dynamic> map) {
    return Settings()
      ..id = map['id'] ?? 0
      ..questionsCount = map['questionsCount'] ?? 50
      ..learningQueueSize = map['learningQueueSize'] ?? 50
      ..notificationsEnabled = map['notificationsEnabled'] ?? true
      ..streakNotificationsEnabled = map['streakNotificationsEnabled'] ?? false
      ..notificationIntervalMinutes = map['notificationIntervalMinutes'] ?? 60
      ..notificationTimeStart = map['notificationTimeStart'] ?? '10:00'
      ..notificationTimeEnd = map['notificationTimeEnd'] ?? '22:00'
      ..autoPlayVoice = map['autoPlayVoice'] ?? false
      ..playSoundEffects = map['playSoundEffects'] ?? true
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
      ..useSimilarWordsForOptions = map['useSimilarWordsForOptions'] ?? false
      ..useSpoiledWordsForOptions = map['useSpoiledWordsForOptions'] ?? false
      ..confusableCharactersSheetId = map['confusableCharactersSheetId']
      ..customConfusableGroups = (map['customConfusableGroups'] as List?)?.cast<String>() ?? []
      ..questionImageToWord = map['questionImageToWord'] ?? true
      ..hasSeenTutorial = map['hasSeenTutorial'] ?? false;
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
    };
  }

  static CustomList _customListFromJson(Map<String, dynamic> map) {
    return CustomList()
      ..name = map['name'] ?? 'Imported List'
      ..googleSheetId = map['googleSheetId']
      ..googleSheetTabName = map['googleSheetTabName']
      ..language = map['language'] ?? 'ja-JP'
      ..syncOnStartup = map['syncOnStartup'] ?? false
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
      ..questionImageToWord = map['questionImageToWord'] ?? true;
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
    };
  }

  static Word _wordFromJson(Map<String, dynamic> map) {
    return Word()
      ..sheetId = map['sheetId'] ?? 0
      ..japanese = map['japanese'] ?? ''
      ..reading = map['reading']
      ..translation = map['translation'] ?? ''
      ..imageUrl = map['imageUrl']
      ..mnemonic = map['mnemonic']
      ..progress = map['progress'] ?? 0
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
}
