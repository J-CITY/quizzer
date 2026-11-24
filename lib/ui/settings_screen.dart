import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../data/services/database_service.dart';
import '../data/models/settings.dart' as app;
import '../data/services/google_sheets_service.dart';
import '../data/services/notification_service.dart';
import '../utils/constants.dart';
import '../ui/widgets/settings_group.dart';
import '../ui/widgets/settings_tile.dart';
import '../data/services/profile_service.dart';
import '../main.dart';
import '../core/feature_flags.dart';
import 'widgets/rush_settings_sheet.dart';

final settingsProvider = FutureProvider.autoDispose<app.Settings>((ref) async {
  return ref.watch(databaseServiceProvider).getSettings();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _updateSettings(
    app.Settings settings,
    VoidCallback update,
  ) async {
    update();
    await ref.read(databaseServiceProvider).saveSettings(settings);
    if (mounted) ref.invalidate(settingsProvider);
  }

  Future<void> _showDefaultRushSettings(app.Settings settings) async {
    final configuration = await showRushSettingsSheet(
      context,
      initialErrorLimit: settings.rushErrorLimit,
    );
    if (!mounted ||
        configuration == null ||
        configuration.errorLimit == settings.rushErrorLimit) {
      return;
    }
    await _updateSettings(settings, () {
      settings.defaultRushErrorLimit = configuration.errorLimit;
    });
  }

  Future<void> _pickTime(
    BuildContext context,
    app.Settings settings,
    bool isStart,
  ) async {
    final timeStr = isStart
        ? settings.notificationTimeStart
        : settings.notificationTimeEnd;
    final parts = timeStr.split(':');
    final initialTime = TimeOfDay(
      hour: parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 10) : 10,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _updateSettings(settings, () {
        if (isStart) {
          settings.notificationTimeStart = formatted;
        } else {
          settings.notificationTimeEnd = formatted;
        }
      });
    }
  }

  void _ensureOneQuestionType(app.Settings settings) {
    if (!settings.questionWordToTranslate &&
        !settings.questionTranslateToWord &&
        !settings.questionWordToReading &&
        !settings.questionReadingToWord &&
        !settings.questionVoiceToTranslate &&
        !settings.questionVoiceToWord &&
        !settings.questionVoiceToWordInput &&
        !settings.questionVoiceToWordConstructor &&
        !settings.questionTranslateToWordInput &&
        !settings.questionTranslateToWordConstructor &&
        !settings.questionImageToWord) {
      settings.questionWordToTranslate = true;
    }
  }

  Future<void> _showNumberDialog(String title, int initialValue, Function(int) onSave) async {
    final controller = TextEditingController(text: initialValue.toString());
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null) {
                onSave(val);
              }
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuestionTypesDialog(app.Settings settings) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            Widget buildCheck(String title, String desc, bool value, Function(bool) onChanged) {
              return CheckboxListTile(
                title: Text(title),
                value: value,
                secondary: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(title),
                        content: Text(desc),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                onChanged: (val) {
                  if (val != null) {
                    setStateBottomSheet(() {
                      onChanged(val);
                    });
                    _updateSettings(settings, () {
                      onChanged(val);
                      _ensureOneQuestionType(settings);
                    });
                  }
                },
              );
            }
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      AppLocalizations.of(context)!.questionTypes,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    buildCheck(AppLocalizations.of(context)!.questionWordToTranslate, AppLocalizations.of(context)!.questionWordToTranslateDesc, settings.questionWordToTranslate, (v) => settings.questionWordToTranslate = v),
                    buildCheck(AppLocalizations.of(context)!.questionTranslateToWord, AppLocalizations.of(context)!.questionTranslateToWordDesc, settings.questionTranslateToWord, (v) => settings.questionTranslateToWord = v),
                    buildCheck(AppLocalizations.of(context)!.questionWordToReading, AppLocalizations.of(context)!.questionWordToReadingDesc, settings.questionWordToReading, (v) => settings.questionWordToReading = v),
                    buildCheck(AppLocalizations.of(context)!.questionReadingToWord, AppLocalizations.of(context)!.questionReadingToWordDesc, settings.questionReadingToWord, (v) => settings.questionReadingToWord = v),
                    buildCheck(AppLocalizations.of(context)!.questionVoiceToTranslate, AppLocalizations.of(context)!.questionVoiceToTranslateDesc, settings.questionVoiceToTranslate, (v) => settings.questionVoiceToTranslate = v),
                    buildCheck(AppLocalizations.of(context)!.questionVoiceToWord, AppLocalizations.of(context)!.questionVoiceToWordDesc, settings.questionVoiceToWord, (v) => settings.questionVoiceToWord = v),
                    buildCheck(AppLocalizations.of(context)!.questionVoiceToWordInput, AppLocalizations.of(context)!.questionVoiceToWordInputDesc, settings.questionVoiceToWordInput, (v) => settings.questionVoiceToWordInput = v),
                    buildCheck(AppLocalizations.of(context)!.questionVoiceToWordConstructor, AppLocalizations.of(context)!.questionVoiceToWordConstructorDesc, settings.questionVoiceToWordConstructor, (v) => settings.questionVoiceToWordConstructor = v),
                    buildCheck(AppLocalizations.of(context)!.questionTranslateToWordInput, AppLocalizations.of(context)!.questionTranslateToWordInputDesc, settings.questionTranslateToWordInput, (v) => settings.questionTranslateToWordInput = v),
                    buildCheck(AppLocalizations.of(context)!.questionTranslateToWordConstructor, AppLocalizations.of(context)!.questionTranslateToWordConstructorDesc, settings.questionTranslateToWordConstructor, (v) => settings.questionTranslateToWordConstructor = v),
                    buildCheck(AppLocalizations.of(context)!.questionImageToWord, AppLocalizations.of(context)!.questionImageToWordDesc, settings.questionImageToWord, (v) => settings.questionImageToWord = v),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _getFrequencyText(int minutes) {
    switch (minutes) {
      case 30: return AppLocalizations.of(context)!.freq30m;
      case 60: return AppLocalizations.of(context)!.freq1h;
      case 90: return AppLocalizations.of(context)!.freq1_5h;
      case 120: return AppLocalizations.of(context)!.freq2h;
      case 180: return AppLocalizations.of(context)!.freq3h;
      case 360: return AppLocalizations.of(context)!.freq6h;
      case 1440: return AppLocalizations.of(context)!.freq1d;
      default: return '$minutes мин';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final accentColor = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settingsTitle)),
      body: settingsAsync.when(
        data: (settings) {
          return Scrollbar(
            interactive: true,
            child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              SettingsGroup(
                title: AppLocalizations.of(context)!.settingsGroupTraining,
                children: [
                  SettingsTile(
                    title: AppLocalizations.of(context)!.settingsQuestionsCount,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settings.questionsCount.toString(),
                          style: TextStyle(color: accentColor, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: () {
                      _showNumberDialog(
                        AppLocalizations.of(context)!.settingsQuestionsCount,
                        settings.questionsCount,
                        (val) {
                          _updateSettings(settings, () {
                            int newCount = val < 1 ? 1 : val;
                            settings.questionsCount = newCount;
                          });
                        },
                      );
                    },
                  ),
                  SettingsTile(
                    title: AppLocalizations.of(context)!.settingsLearningQueueSize,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settings.learningQueueSize.toString(),
                          style: TextStyle(color: accentColor, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: () {
                      _showNumberDialog(
                        AppLocalizations.of(context)!.settingsLearningQueueSize,
                        settings.learningQueueSize,
                        (val) {
                          _updateSettings(settings, () {
                            int newSize = val < 1 ? 1 : val;
                            settings.learningQueueSize = newSize;
                          });
                        },
                      );
                    },
                  ),
                  SettingsTile(
                    title: AppLocalizations.of(context)!.settingsWordRepetitions,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settings.targetWordRepetitions.toString(),
                          style: TextStyle(color: accentColor, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: () {
                      _showNumberDialog(
                        AppLocalizations.of(context)!.settingsWordRepetitions,
                        settings.targetWordRepetitions,
                        (val) {
                          _updateSettings(settings, () {
                            int newSize = val < 1 ? 1 : val;
                            settings.targetWordRepetitions = newSize;
                          });
                        },
                      );
                    },
                  ),
                  SettingsTile(
                    title: AppLocalizations.of(context)!.questionTypes,
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => _showQuestionTypesDialog(settings),
                  ),
                  SwitchListTile(
                    title: Text(l10n.settingsLearningHints),
                    value: !settings.learningHintsDisabled,
                    onChanged: (enabled) => _updateSettings(settings, () {
                      settings.learningHintsDisabled = !enabled;
                    }),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: Text(l10n.settingsReviewHints),
                    value: !settings.reviewHintsDisabled,
                    onChanged: (enabled) => _updateSettings(settings, () {
                      settings.reviewHintsDisabled = !enabled;
                    }),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SettingsTile(
                    title: l10n.settingsRushErrorLimit,
                    subtitle: l10n.rushErrorLimitSummary(settings.rushErrorLimit),
                    showDivider: false,
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => _showDefaultRushSettings(settings),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SettingsGroup(
                title: AppLocalizations.of(context)!.settingsGroupProcess,
                children: [
                  SettingsTile(
                    title: AppLocalizations.of(context)!.settingsAutoTts,
                    subtitle: AppLocalizations.of(context)!.settingsAutoTtsDesc,
                    trailing: Switch(
                      value: settings.autoPlayVoice,
                      onChanged: (val) {
                        _updateSettings(settings, () {
                          settings.autoPlayVoice = val;
                        });
                      },
                    ),
                  ),
                  SettingsTile(
                    title: AppLocalizations.of(context)!.settingsSoundEffects,
                    subtitle: AppLocalizations.of(context)!.settingsSoundEffectsDesc,
                    trailing: Switch(
                      value: settings.playSoundEffects,
                      onChanged: (val) {
                        _updateSettings(settings, () {
                          settings.playSoundEffects = val;
                        });
                      },
                    ),
                  ),
                  SettingsTile(
                    title: AppLocalizations.of(context)!.hapticFeedback,
                    subtitle: AppLocalizations.of(context)!.hapticFeedbackDesc,
                    trailing: Switch(
                      value: settings.hapticFeedbackEnabled,
                      onChanged: (val) {
                        _updateSettings(settings, () {
                          settings.hapticFeedbackEnabled = val;
                        });
                      },
                    ),
                  ),
                  SettingsTile(
                    title: AppLocalizations.of(context)!.settingsAutoAdvance,
                    subtitle: AppLocalizations.of(context)!.settingsAutoAdvanceDesc,
                    showDivider: false,
                    trailing: Switch(
                      value: settings.autoAdvanceToNextQuestion,
                      onChanged: (val) {
                        _updateSettings(settings, () {
                          settings.autoAdvanceToNextQuestion = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SettingsGroup(
                title: AppLocalizations.of(context)!.settingsGroupDictionary,
                children: [
                  SettingsTile(
                    title: AppLocalizations.of(context)!.settingsSimilarWords,
                    subtitle: AppLocalizations.of(context)!.settingsSimilarWordsDesc,
                    trailing: Switch(
                      value: settings.useSimilarWordsForOptions,
                      onChanged: (val) {
                        _updateSettings(settings, () {
                          settings.useSimilarWordsForOptions = val;
                        });
                      },
                    ),
                  ),
                  SettingsTile(
                    title: AppLocalizations.of(context)!.settingsSpoilWords,
                    subtitle: AppLocalizations.of(context)!.settingsSpoilWordsDesc,
                    trailing: Switch(
                      value: settings.useSpoiledWordsForOptions,
                      onChanged: (val) {
                        _updateSettings(settings, () {
                          settings.useSpoiledWordsForOptions = val;
                        });
                      },
                    ),
                  ),
                  SettingsTile(
                    title: AppLocalizations.of(context)!.settingsConfusableSheet,
                    subtitle: settings.confusableCharactersSheetId?.isEmpty ?? true ? AppLocalizations.of(context)!.notSet : settings.confusableCharactersSheetId,
                    showDivider: false,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(AppLocalizations.of(context)!.confusableFormatHintTitle),
                                content: Text(AppLocalizations.of(context)!.confusableFormatHintDesc),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.sync),
                      onPressed: () async {
                        if (settings.confusableCharactersSheetId == null || settings.confusableCharactersSheetId!.isEmpty) {
                          // Allow editing if empty
                          final controller = TextEditingController(text: settings.confusableCharactersSheetId);
                          await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(AppLocalizations.of(context)!.settingsConfusableSheet),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(border: OutlineInputBorder()),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
                                TextButton(
                                  onPressed: () {
                                    _updateSettings(settings, () {
                                      settings.confusableCharactersSheetId = controller.text;
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        
                        try {
                          await _updateSettings(settings, () {});
                          final groups = await GoogleSheetsService.fetchConfusableGroups(settings.confusableCharactersSheetId!);
                          await _updateSettings(settings, () {
                            settings.customConfusableGroups = groups;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.syncSuccess)));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                    ),
                    ],
                    ),
                    onTap: () async {
                      final controller = TextEditingController(text: settings.confusableCharactersSheetId);
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(AppLocalizations.of(context)!.settingsConfusableSheet),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
                            TextButton(
                              onPressed: () {
                                _updateSettings(settings, () {
                                  settings.confusableCharactersSheetId = controller.text;
                                });
                                Navigator.pop(context);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SettingsGroup(
                title: AppLocalizations.of(context)!.settingsGroupNotifications,
                children: [
                  SettingsTile(
                    title: AppLocalizations.of(context)!.settingsNotifications,
                    subtitle: AppLocalizations.of(context)!.settingsNotificationsDesc,
                    trailing: Switch(
                      value: settings.notificationsEnabled,
                      onChanged: (val) {
                        _updateSettings(settings, () {
                          settings.notificationsEnabled = val;
                        });
                        if (val) {
                          NotificationService.updateSchedule(settings.notificationIntervalMinutes);
                        } else {
                          if (!settings.streakNotificationsEnabled) {
                            NotificationService.cancelSchedule();
                          }
                        }
                      },
                    ),
                  ),
                  SettingsTile(
                    title: AppLocalizations.of(context)!.streakNotificationsTitle,
                    subtitle: AppLocalizations.of(context)!.streakNotificationsSubtitle,
                    trailing: Switch(
                      value: settings.streakNotificationsEnabled,
                      onChanged: (val) {
                        _updateSettings(settings, () {
                          settings.streakNotificationsEnabled = val;
                        });
                        if (val || settings.notificationsEnabled) {
                          NotificationService.updateSchedule(settings.notificationIntervalMinutes);
                        } else {
                          NotificationService.cancelSchedule();
                        }
                      },
                    ),
                  ),
                  if (settings.notificationsEnabled) ...[
                    SettingsTile(
                      title: AppLocalizations.of(context)!.notificationFrequency,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getFrequencyText(settings.notificationIntervalMinutes),
                            style: TextStyle(color: accentColor, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      onTap: () async {
                        final val = await showDialog<int>(
                          context: context,
                          builder: (context) => SimpleDialog(
                            title: Text(AppLocalizations.of(context)!.notificationFrequency),
                            children: [30, 60, 90, 120, 180, 360, 1440].map((e) {
                              return SimpleDialogOption(
                                onPressed: () => Navigator.pop(context, e),
                                child: Text(_getFrequencyText(e)),
                              );
                            }).toList(),
                          ),
                        );
                        if (val != null) {
                          _updateSettings(settings, () {
                            settings.notificationIntervalMinutes = val;
                          });
                          NotificationService.updateSchedule(val);
                        }
                      },
                    ),
                    SettingsTile(
                      title: AppLocalizations.of(context)!.notificationTimeWindow,
                      subtitle: '${settings.notificationTimeStart} - ${settings.notificationTimeEnd}',
                      showDivider: false,
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () async {
                        await _pickTime(context, settings, true);
                        if (context.mounted) {
                          await _pickTime(context, settings, false);
                        }
                      },
                    ),
                  ] else ...[
                    // Just to not leave trailing divider if hidden
                    const SizedBox(height: 1),
                  ],
                  const Divider(height: 1),
                  SettingsTile(
                    title: AppLocalizations.of(context)!.randomWordNotifTitle,
                    subtitle: AppLocalizations.of(context)!.randomWordNotifDesc,
                    trailing: Switch(
                      value: settings.randomWordNotificationEnabled,
                      onChanged: (val) {
                        _updateSettings(settings, () {
                          settings.randomWordNotificationEnabled = val;
                        });
                        if (val) {
                          NotificationService.updateRandomWordSchedule(settings.randomWordNotificationIntervalMinutes);
                        } else {
                          NotificationService.cancelRandomWordSchedule();
                        }
                      },
                    ),
                  ),
                  if (settings.randomWordNotificationEnabled) ...[
                    SettingsTile(
                      title: AppLocalizations.of(context)!.notificationFrequency,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getFrequencyText(settings.randomWordNotificationIntervalMinutes),
                            style: TextStyle(color: accentColor, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      onTap: () async {
                        final val = await showDialog<int>(
                          context: context,
                          builder: (context) => SimpleDialog(
                            title: Text(AppLocalizations.of(context)!.notificationFrequency),
                            children: [30, 60, 90, 120, 180, 360, 1440].map((e) {
                              return SimpleDialogOption(
                                onPressed: () => Navigator.pop(context, e),
                                child: Text(_getFrequencyText(e)),
                              );
                            }).toList(),
                          ),
                        );
                        if (val != null) {
                          _updateSettings(settings, () {
                            settings.randomWordNotificationIntervalMinutes = val;
                          });
                          NotificationService.updateRandomWordSchedule(val);
                        }
                      },
                    ),
                    SettingsTile(
                      title: AppLocalizations.of(context)!.randomWordNotifList,
                      showDivider: false,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FutureBuilder<String>(
                            future: settings.randomWordNotificationListId == null
                                ? Future.value(AppLocalizations.of(context)!.randomListOption)
                                : ref.read(databaseServiceProvider).getCustomLists().then(
                                    (lists) => lists.firstWhere(
                                      (l) => l.id == settings.randomWordNotificationListId,
                                      orElse: () => throw Exception(),
                                    ).name,
                                  ).catchError((_) => 'Unknown'),
                            builder: (context, snapshot) {
                              return ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 150),
                                child: Text(
                                  snapshot.data ?? '...',
                                  style: TextStyle(color: accentColor, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      onTap: () async {
                        final lists = await ref.read(databaseServiceProvider).getCustomLists();
                        if (context.mounted) {
                          final selected = await showModalBottomSheet<int?>(
                            context: context,
                            builder: (context) {
                              return ListView(
                                children: [
                                  ListTile(
                                    title: Text(AppLocalizations.of(context)!.randomListOption),
                                    onTap: () => Navigator.pop(context, -1), // -1 will represent null (all words)
                                  ),
                                  ...lists.map((l) => ListTile(
                                    title: Text(l.name),
                                    onTap: () => Navigator.pop(context, l.id),
                                  )),
                                ],
                              );
                            },
                          );
                          
                          if (selected != null) {
                            _updateSettings(settings, () {
                              settings.randomWordNotificationListId = selected == -1 ? null : selected;
                            });
                          }
                        }
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 1),
                  ]
                ],
              ),
              const SizedBox(height: 16),
              SettingsGroup(
                title: AppLocalizations.of(context)!.settingsGroupAbout,
                children: [
                  SettingsTile(
                    title: AppLocalizations.of(context)!.aboutDeveloper,
                    subtitle: AppConstants.developerName,
                  ),
                  SettingsTile(
                    title: AppLocalizations.of(context)!.contactDeveloper,
                    subtitle: AppConstants.developerEmail,
                    showDivider: false,
                    trailing: const Icon(Icons.copy, color: Colors.grey, size: 20),
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: AppConstants.developerEmail));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.emailCopied)),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SettingsGroup(
                title: AppLocalizations.of(context)!.settingsGroupStorage,
                children: [
                  SettingsTile(
                    title: AppLocalizations.of(context)!.exportProfile,
                    showDivider: true,
                    trailing: const Icon(Icons.upload_file, color: Colors.blue),
                    onTap: () async {
                      await ProfileService.exportProfile(context, ref.read(databaseServiceProvider));
                    },
                  ),
                  SettingsTile(
                    title: AppLocalizations.of(context)!.importProfile,
                    showDivider: true,
                    trailing: const Icon(Icons.download, color: Colors.green),
                    onTap: () async {
                      await ProfileService.importProfile(context, ref.read(databaseServiceProvider));
                      ref.refresh(settingsProvider);
                    },
                  ),
                  SettingsTile(
                    title: AppLocalizations.of(context)!.clearImageCache,
                    showDivider: false,
                    trailing: const Icon(Icons.delete_outline, color: Colors.red),
                    onTap: () async {
                      await DefaultCacheManager().emptyCache();
                      PaintingBinding.instance.imageCache.clear();
                      PaintingBinding.instance.imageCache.clearLiveImages();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.imageCacheCleared)),
                        );
                      }
                    },
                  ),
                ],
              ),
              if (FeatureFlags.enableIap && !settings.isAdFree) ...[
                const SizedBox(height: 16),
                SettingsGroup(
                  title: 'IN-APP PURCHASES',
                  children: [
                    SettingsTile(
                      title: AppLocalizations.of(context)!.removeAdsButton,
                      showDivider: true,
                      trailing: const Icon(Icons.monetization_on, color: Colors.amber),
                      onTap: () async {
                        await ref.read(iapServiceProvider).buyRemoveAds(context);
                      },
                    ),
                    SettingsTile(
                      title: AppLocalizations.of(context)!.restorePurchasesButton,
                      showDivider: false,
                      trailing: const Icon(Icons.restore, color: Colors.blue),
                      onTap: () async {
                        await ref.read(iapServiceProvider).restorePurchases();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.purchaseRestored)),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
              if (FeatureFlags.enableCheatMenu) ...[
                const SizedBox(height: 16),
                SettingsGroup(
                  title: AppLocalizations.of(context)!.cheatMenuTitle,
                  children: [
                    SettingsTile(
                      title: AppLocalizations.of(context)!.setStreakTitle,
                      subtitle: AppLocalizations.of(context)!.setStreakDesc,
                      showDivider: true,
                      trailing: const Icon(Icons.edit, color: Colors.blue),
                      onTap: () {
                        _showNumberDialog(
                          AppLocalizations.of(context)!.setStreakTitle,
                          1, // Default value to show
                          (val) async {
                            await ref.read(databaseServiceProvider).setStreakCheat(val);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Стрик успешно обновлен! / Streak updated!')),
                              );
                            }
                          },
                        );
                      },
                    ),
                    SettingsTile(
                      title: 'Restore Auto Backup',
                      showDivider: true,
                      trailing: const Icon(Icons.restore_page, color: Colors.red),
                      onTap: () async {
                        final success = await ProfileService.restoreFromAutoBackup(ref.read(databaseServiceProvider));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(success ? 'Backup restored successfully!' : 'No backup found or failed to restore.')),
                          );
                          ref.refresh(settingsProvider);
                        }
                      },
                    ),
                    SettingsTile(
                      title: AppLocalizations.of(context)!.cheatTestTrainingNotif,
                      showDivider: true,
                      trailing: const Icon(Icons.notifications, color: Colors.blue),
                      onTap: () {
                        NotificationService.testNotification('training', ref.read(databaseServiceProvider));
                      },
                    ),
                    SettingsTile(
                      title: AppLocalizations.of(context)!.cheatTestStreakNotif,
                      showDivider: true,
                      trailing: const Icon(Icons.local_fire_department, color: Colors.orange),
                      onTap: () {
                        NotificationService.testNotification('streak', ref.read(databaseServiceProvider));
                      },
                    ),
                    SettingsTile(
                      title: AppLocalizations.of(context)!.cheatTestRandomNotif,
                      showDivider: false,
                      trailing: const Icon(Icons.shuffle, color: Colors.purple),
                      onTap: () {
                        NotificationService.testNotification('random', ref.read(databaseServiceProvider));
                      },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
            ],
          ));
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
