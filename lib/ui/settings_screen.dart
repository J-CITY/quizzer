import 'package:flutter/material.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/database_service.dart';
import '../data/models/settings.dart' as app;
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
        !settings.questionReading) {
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
                initialValue: settings.questionsCount.toString(),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.settingsQuestionsCount,
                ),
                keyboardType: TextInputType.number,
                onFieldSubmitted: (val) {
                  _updateSettings(settings, () {
                    settings.questionsCount = int.tryParse(val) ?? 50;
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
                    title: Text(AppLocalizations.of(context)!.questionReading),
                    value: settings.questionReading,
                    onChanged: (val) {
                      if (val != null) {
                        _updateSettings(settings, () {
                          settings.questionReading = val;
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
