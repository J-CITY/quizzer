import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/database_service.dart';
import '../data/models/settings.dart' as app;

final settingsProvider = FutureProvider<app.Settings>((ref) async {
  return ref.watch(databaseServiceProvider).getSettings();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                initialValue: settings.questionsCount.toString(),
                decoration: const InputDecoration(labelText: 'Количество вопросов в тренировке'),
                keyboardType: TextInputType.number,
                onFieldSubmitted: (val) {
                  settings.questionsCount = int.tryParse(val) ?? 50;
                  ref.read(databaseServiceProvider).saveSettings(settings);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: settings.sheetId,
                decoration: const InputDecoration(
                  labelText: 'ID Google Таблицы',
                  hintText: 'Например: 1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms',
                ),
                onFieldSubmitted: (val) {
                  settings.sheetId = val;
                  ref.read(databaseServiceProvider).saveSettings(settings);
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Уведомления'),
                subtitle: const Text('Напоминать о словах, которые пора повторить'),
                value: settings.notificationsEnabled,
                onChanged: (val) {
                  settings.notificationsEnabled = val;
                  ref.read(databaseServiceProvider).saveSettings(settings);
                  ref.refresh(settingsProvider);
                },
              ),
              SwitchListTile(
                title: const Text('Авто-озвучка вопросов'),
                subtitle: const Text('Японские слова будут озвучиваться при появлении карточки'),
                value: settings.autoPlayVoice,
                onChanged: (val) {
                  settings.autoPlayVoice = val;
                  ref.read(databaseServiceProvider).saveSettings(settings);
                  ref.refresh(settingsProvider);
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка загрузки настроек')),
      ),
    );
  }
}
