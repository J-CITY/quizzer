import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/services/database_service.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dbService = DatabaseService();
  await dbService.init();

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
      ],
      child: const QuizzerApp(),
    ),
  );
}

class QuizzerApp extends StatelessWidget {
  const QuizzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quizzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
