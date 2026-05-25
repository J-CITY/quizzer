import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../data/models/custom_list.dart';
import '../data/services/database_service.dart';
import 'custom_list_details_screen.dart';
import 'edit_custom_list_screen.dart';

final customListsStreamProvider = StreamProvider.autoDispose<List<CustomList>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.isar.customLists.where().watch(fireImmediately: true);
});

class CustomListsTab extends ConsumerWidget {
  const CustomListsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(customListsStreamProvider);

    return Scaffold(
      body: listsAsync.when(
        data: (lists) {
          if (lists.isEmpty) {
            return const Center(child: Text('У вас пока нет кастомных списков', style: TextStyle(fontSize: 16, color: Colors.grey)));
          }
          return ListView.builder(
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(list.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text('Слов: ${list.words.length}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EditCustomListScreen(customList: list)));
                    },
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CustomListDetailsScreen(customList: list)));
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка загрузки списков: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const EditCustomListScreen()));
        },
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
