import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/database_service.dart';
import '../data/models/settings.dart' as app;
import '../data/services/google_sheets_service.dart';
import '../data/services/notification_service.dart';
import '../utils/constants.dart';
import '../ui/widgets/settings_group.dart';
import '../ui/widgets/settings_tile.dart';

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
    ref.invalidate(settingsProvider);
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
            Widget buildCheck(String title, bool value, Function(bool) onChanged) {
              return CheckboxListTile(
                title: Text(title),
                value: value,
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
                    buildCheck(AppLocalizations.of(context)!.questionWordToTranslate, settings.questionWordToTranslate, (v) => settings.questionWordToTranslate = v),
                    buildCheck(AppLocalizations.of(context)!.questionTranslateToWord, settings.questionTranslateToWord, (v) => settings.questionTranslateToWord = v),
                    buildCheck(AppLocalizations.of(context)!.questionWordToReading, settings.questionWordToReading, (v) => settings.questionWordToReading = v),
                    buildCheck(AppLocalizations.of(context)!.questionReadingToWord, settings.questionReadingToWord, (v) => settings.questionReadingToWord = v),
                    buildCheck(AppLocalizations.of(context)!.questionVoiceToTranslate, settings.questionVoiceToTranslate, (v) => settings.questionVoiceToTranslate = v),
                    buildCheck(AppLocalizations.of(context)!.questionVoiceToWord, settings.questionVoiceToWord, (v) => settings.questionVoiceToWord = v),
                    buildCheck(AppLocalizations.of(context)!.questionVoiceToWordInput, settings.questionVoiceToWordInput, (v) => settings.questionVoiceToWordInput = v),
                    buildCheck(AppLocalizations.of(context)!.questionVoiceToWordConstructor, settings.questionVoiceToWordConstructor, (v) => settings.questionVoiceToWordConstructor = v),
                    buildCheck(AppLocalizations.of(context)!.questionTranslateToWordInput, settings.questionTranslateToWordInput, (v) => settings.questionTranslateToWordInput = v),
                    buildCheck(AppLocalizations.of(context)!.questionTranslateToWordConstructor, settings.questionTranslateToWordConstructor, (v) => settings.questionTranslateToWordConstructor = v),
                    buildCheck(AppLocalizations.of(context)!.questionImageToWord, settings.questionImageToWord, (v) => settings.questionImageToWord = v),
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

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settingsTitle)),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
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
                            if (newCount > settings.learningQueueSize) {
                              settings.learningQueueSize = newCount;
                            }
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
                            int newSize = val < settings.questionsCount ? settings.questionsCount : val;
                            settings.learningQueueSize = newSize;
                          });
                        },
                      );
                    },
                  ),
                  SettingsTile(
                    title: AppLocalizations.of(context)!.questionTypes,
                    showDivider: false,
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => _showQuestionTypesDialog(settings),
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
                    trailing: IconButton(
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
              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
