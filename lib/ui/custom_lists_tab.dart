import 'package:flutter/material.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../data/models/custom_list.dart';
import '../data/services/database_service.dart';
import '../utils/constants.dart';
import 'custom_list_details_screen.dart';
import 'edit_custom_list_screen.dart';
import 'widgets/acrylic_card.dart';
import 'widgets/glow_button.dart';
import 'widgets/progress_bar.dart';

final customListsStreamProvider = StreamProvider.autoDispose<List<CustomList>>((
  ref,
) {
  final db = ref.watch(databaseServiceProvider);
  return db.isar.customLists.where().watch(fireImmediately: true);
});

class CustomListsTab extends ConsumerStatefulWidget {
  const CustomListsTab({super.key});

  @override
  ConsumerState<CustomListsTab> createState() => _CustomListsTabState();
}

class _CustomListsTabState extends ConsumerState<CustomListsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(customListsStreamProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: listsAsync.when(
        data: (lists) {
          final filteredLists = lists.where((l) => l.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchLists,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              Expanded(
                child: filteredLists.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.noCustomLists,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context)
                                .extension<AppColorsExtension>()!
                                .textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredLists.length,
                        itemBuilder: (context, index) {
                          final list = filteredLists[index];
                          final wordsList = list.words.toList();
                          final total = wordsList.length;
                          final learned = wordsList.where((w) => w.progress >= 5).length;
                          final inProgress = wordsList.where((w) => w.progress > 0 && w.progress < 5).length;

                          return AcrylicCard(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: Text(
                                list.emoji ?? '📚',
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(
                                list.name,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.wordsCount(total.toString()),
                                  ),
                                  const SizedBox(height: 8),
                                  ThinProgressBar(
                                    total: total,
                                    learned: learned,
                                    inProgress: inProgress,
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.settings),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditCustomListScreen(customList: list),
                                    ),
                                  );
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CustomListDetailsScreen(customList: list),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            AppLocalizations.of(context)!.errorLoadingLists(err.toString()),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: GlowButton(
          padding: const EdgeInsets.all(16),
          borderRadius: 30,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditCustomListScreen()),
            );
          },
          child: const Icon(Icons.add, size: 32),
        ),
      ),
    );
  }
}
