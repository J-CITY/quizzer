import 'package:flutter/material.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'settings_screen.dart';
import 'custom_lists_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzer'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'settings',
                  child: Text(AppLocalizations.of(context)!.settingsTitle),
                ),
              ],
            )
          ],
        ),
        body: const CustomListsTab(),
      );
  }
}
