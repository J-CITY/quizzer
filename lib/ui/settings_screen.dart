import 'package:flutter/material.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/database_service.dart';
import '../data/models/settings.dart' as app;
import '../data/services/google_sheets_service.dart';
import '../data/services/notification_service.dart';

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
        !settings.questionReadingToWord) {
      settings.questionWordToTranslate = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settingsTitle)),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: ValueKey('qc_${settings.questionsCount}'),
                initialValue: settings.questionsCount.toString(),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.settingsQuestionsCount,
                ),
                keyboardType: TextInputType.number,
                onFieldSubmitted: (val) {
                  _updateSettings(settings, () {
                    int newCount = int.tryParse(val) ?? 50;
                    if (newCount < 1) newCount = 1;
                    if (newCount > settings.learningQueueSize) {
                      settings.learningQueueSize = newCount;
                    }
                    settings.questionsCount = newCount;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: ValueKey('lqs_${settings.learningQueueSize}'),
                initialValue: settings.learningQueueSize.toString(),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.settingsLearningQueueSize,
                ),
                keyboardType: TextInputType.number,
                onFieldSubmitted: (val) {
                  _updateSettings(settings, () {
                    int newSize = int.tryParse(val) ?? 50;
                    if (newSize < settings.questionsCount) {
                      newSize = settings.questionsCount;
                    }
                    settings.learningQueueSize = newSize;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(
                  AppLocalizations.of(context)!.settingsNotifications,
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.settingsNotificationsDesc,
                ),
                value: settings.notificationsEnabled,
                onChanged: (val) {
                  _updateSettings(settings, () {
                    settings.notificationsEnabled = val;
                  });
                  if (val) {
                    NotificationService.updateSchedule(
                      settings.notificationIntervalMinutes,
                    );
                  } else {
                    NotificationService.cancelSchedule();
                  }
                },
              ),
              if (settings.notificationsEnabled) ...[
                ListTile(
                  title: Text(
                    AppLocalizations.of(context)!.notificationFrequency,
                  ),
                  trailing: DropdownButton<int>(
                    value:
                        [
                          30,
                          60,
                          90,
                          120,
                          180,
                          360,
                          1440,
                        ].contains(settings.notificationIntervalMinutes)
                        ? settings.notificationIntervalMinutes
                        : 60,
                    items: [
                      DropdownMenuItem<int>(
                        value: 30,
                        child: Text(AppLocalizations.of(context)!.freq30m),
                      ),
                      DropdownMenuItem<int>(
                        value: 60,
                        child: Text(AppLocalizations.of(context)!.freq1h),
                      ),
                      DropdownMenuItem<int>(
                        value: 90,
                        child: Text(AppLocalizations.of(context)!.freq1_5h),
                      ),
                      DropdownMenuItem<int>(
                        value: 120,
                        child: Text(AppLocalizations.of(context)!.freq2h),
                      ),
                      DropdownMenuItem<int>(
                        value: 180,
                        child: Text(AppLocalizations.of(context)!.freq3h),
                      ),
                      DropdownMenuItem<int>(
                        value: 360,
                        child: Text(AppLocalizations.of(context)!.freq6h),
                      ),
                      DropdownMenuItem<int>(
                        value: 1440,
                        child: Text(AppLocalizations.of(context)!.freq1d),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _updateSettings(settings, () {
                          settings.notificationIntervalMinutes = val;
                        });
                        NotificationService.updateSchedule(val);
                      }
                    },
                  ),
                ),
                ListTile(
                  title: Text(
                    AppLocalizations.of(context)!.notificationTimeWindow,
                  ),
                  subtitle: Text(
                    '${settings.notificationTimeStart} - ${settings.notificationTimeEnd}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () => _pickTime(context, settings, true),
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.timeStart(settings.notificationTimeStart),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _pickTime(context, settings, false),
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.timeEnd(settings.notificationTimeEnd),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.settingsAutoTts),
                subtitle: Text(
                  AppLocalizations.of(context)!.settingsAutoTtsDesc,
                ),
                value: settings.autoPlayVoice,
                onChanged: (val) {
                  _updateSettings(settings, () {
                    settings.autoPlayVoice = val;
                  });
                },
              ),
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.settingsSoundEffects),
                subtitle: Text(
                  AppLocalizations.of(context)!.settingsSoundEffectsDesc,
                ),
                value: settings.playSoundEffects,
                onChanged: (val) {
                  _updateSettings(settings, () {
                    settings.playSoundEffects = val;
                  });
                },
              ),
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.settingsAutoAdvance),
                subtitle: Text(
                  AppLocalizations.of(context)!.settingsAutoAdvanceDesc,
                ),
                value: settings.autoAdvanceToNextQuestion,
                onChanged: (val) {
                  _updateSettings(settings, () {
                    settings.autoAdvanceToNextQuestion = val;
                  });
                },
              ),
              const Divider(),
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.settingsSimilarWords),
                subtitle: Text(AppLocalizations.of(context)!.settingsSimilarWordsDesc),
                value: settings.useSimilarWordsForOptions,
                onChanged: (val) {
                  _updateSettings(settings, () {
                    settings.useSimilarWordsForOptions = val;
                  });
                },
              ),
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.settingsSpoilWords),
                subtitle: Text(AppLocalizations.of(context)!.settingsSpoilWordsDesc),
                value: settings.useSpoiledWordsForOptions,
                onChanged: (val) {
                  _updateSettings(settings, () {
                    settings.useSpoiledWordsForOptions = val;
                  });
                },
              ),
              ListTile(
                title: TextFormField(
                  initialValue: settings.confusableCharactersSheetId ?? '',
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.settingsConfusableSheet,
                  ),
                  onChanged: (val) {
                    settings.confusableCharactersSheetId = val;
                  },
                  onFieldSubmitted: (val) {
                    _updateSettings(settings, () {
                      settings.confusableCharactersSheetId = val;
                    });
                  },
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: AppLocalizations.of(context)!.settingsSyncConfusable,
                  onPressed: () async {
                    if (settings.confusableCharactersSheetId == null || settings.confusableCharactersSheetId!.isEmpty) return;
                    try {
                      // Save it first just in case
                      await _updateSettings(settings, () {});
                      final groups = await GoogleSheetsService.fetchConfusableGroups(settings.confusableCharactersSheetId!);
                      await _updateSettings(settings, () {
                        settings.customConfusableGroups = groups;
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.syncSuccess)),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
              const Divider(),
              ExpansionTile(
                title: Text(AppLocalizations.of(context)!.questionTypes),
                children: [
                  CheckboxListTile(
                    title: Text(
                      AppLocalizations.of(context)!.questionWordToTranslate,
                    ),
                    value: settings.questionWordToTranslate,
                    onChanged: (val) {
                      if (val != null) {
                        _updateSettings(settings, () {
                          settings.questionWordToTranslate = val;
                          _ensureOneQuestionType(settings);
                        });
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: Text(
                      AppLocalizations.of(context)!.questionTranslateToWord,
                    ),
                    value: settings.questionTranslateToWord,
                    onChanged: (val) {
                      if (val != null) {
                        _updateSettings(settings, () {
                          settings.questionTranslateToWord = val;
                          _ensureOneQuestionType(settings);
                        });
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionWordToReading),
                    value: settings.questionWordToReading,
                    onChanged: (val) {
                      if (val != null) {
                        _updateSettings(settings, () {
                          settings.questionWordToReading = val;
                          _ensureOneQuestionType(settings);
                        });
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionReadingToWord),
                    value: settings.questionReadingToWord,
                    onChanged: (val) {
                      if (val != null) {
                        _updateSettings(settings, () {
                          settings.questionReadingToWord = val;
                          _ensureOneQuestionType(settings);
                        });
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionVoiceToTranslate),
                    value: settings.questionVoiceToTranslate,
                    onChanged: (val) {
                      if (val != null) {
                        _updateSettings(settings, () {
                          settings.questionVoiceToTranslate = val;
                          _ensureOneQuestionType(settings);
                        });
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionVoiceToWord),
                    value: settings.questionVoiceToWord,
                    onChanged: (val) {
                      if (val != null) {
                        _updateSettings(settings, () {
                          settings.questionVoiceToWord = val;
                          _ensureOneQuestionType(settings);
                        });
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionTranslateToWordInput),
                    value: settings.questionTranslateToWordInput,
                    onChanged: (val) {
                      if (val != null) {
                        _updateSettings(settings, () {
                          settings.questionTranslateToWordInput = val;
                          _ensureOneQuestionType(settings);
                        });
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionTranslateToWordConstructor),
                    value: settings.questionTranslateToWordConstructor,
                    onChanged: (val) {
                      if (val != null) {
                        _updateSettings(settings, () {
                          settings.questionTranslateToWordConstructor = val;
                          _ensureOneQuestionType(settings);
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(AppLocalizations.of(context)!.errorLoadingSettings),
        ),
      ),
    );
  }
}
