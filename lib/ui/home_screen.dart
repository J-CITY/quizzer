import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'words_tab.dart';
import 'custom_lists_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quizzer'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Все слова'),
              Tab(text: 'Списки'),
            ],
          ),
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
                const PopupMenuItem(
                  value: 'settings',
                  child: Text('Настройки'),
                ),
              ],
            )
          ],
        ),
        body: const TabBarView(
          children: [
            WordsTab(),
            CustomListsTab(),
          ],
        ),
      ),
    );
  }
}
