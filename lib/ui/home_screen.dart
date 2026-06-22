import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import '../data/services/notification_service.dart';
import '../utils/constants.dart';
import 'settings_screen.dart';
import 'custom_lists_tab.dart';
import 'statistics_screen.dart';
import 'search_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/database_service.dart';
import 'tutorial_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    await NotificationService.requestPermissions();
  }

  bool _isTutorialChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isTutorialChecked) {
      _isTutorialChecked = true;
      _checkTutorial();
    }
  }

  Future<void> _checkTutorial() async {
    final db = ref.read(databaseServiceProvider);
    final settings = await db.getSettings();
    if (!settings.hasSeenTutorial && mounted) {
      _showTutorial();
    }
  }

  void _showTutorial() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => TutorialScreen(
          onDone: () {
            Navigator.pop(context);
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  final List<Widget> _tabs = [
    const StatisticsScreen(),
    const CustomListsTab(),
    const SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Text(
          _currentIndex == 0
              ? AppLocalizations.of(context)!.statistics
              : _currentIndex == 1
              ? AppLocalizations.of(context)!.wordLists
              : AppLocalizations.of(context)!.tabSearch,
        ),
        centerTitle: true,
        leading: _currentIndex == 0
            ? IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: AppLocalizations.of(context)?.tutorialButtonTooltip,
                onPressed: _showTutorial,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      extendBody: true,
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: BottomNavigationBar(
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Theme.of(
                  context,
                ).textTheme.bodySmall?.color,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.65),
                elevation: 0,
                currentIndex: _currentIndex,
                onTap: (idx) {
                  setState(() {
                    _currentIndex = idx;
                  });
                },
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.bar_chart),
                    label: AppLocalizations.of(context)!.statistics,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.list),
                    label: AppLocalizations.of(context)!.tabCustomLists,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.search),
                    label: AppLocalizations.of(context)!.tabSearch,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
