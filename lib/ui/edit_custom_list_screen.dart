import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/custom_list.dart';
import '../data/models/word.dart';
import '../data/services/database_service.dart';

class EditCustomListScreen extends ConsumerStatefulWidget {
  final CustomList? customList; // If null, we are creating a new list

  const EditCustomListScreen({super.key, this.customList});

  @override
  ConsumerState<EditCustomListScreen> createState() => _EditCustomListScreenState();
}

class _EditCustomListScreenState extends ConsumerState<EditCustomListScreen> {
  late TextEditingController _nameController;
  final Set<int> _selectedWordIds = {};
  List<Word> _allWords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customList?.name ?? '');
    
    if (widget.customList != null) {
      widget.customList!.words.loadSync(); // Ensure links are loaded
      _selectedWordIds.addAll(widget.customList!.words.map((w) => w.id));
    }
    _loadWords();
  }

  Future<void> _loadWords() async {
    final db = ref.read(databaseServiceProvider);
    final words = await db.getAllWords();
    if (mounted) {
      setState(() {
        _allWords = words;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите название списка')));
      return;
    }

    final db = ref.read(databaseServiceProvider);
    final list = widget.customList ?? CustomList();
    list.name = name;
    
    // Map selected IDs back to Word objects
    final selectedWords = _allWords.where((w) => _selectedWordIds.contains(w.id)).toList();
    list.words.clear();
    list.words.addAll(selectedWords);

    await db.saveCustomList(list);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (widget.customList != null) {
      final db = ref.read(databaseServiceProvider);
      await db.deleteCustomList(widget.customList!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customList == null ? 'Новый список' : 'Настройки списка'),
        actions: [
          if (widget.customList != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _delete,
            ),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название списка',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(alignment: Alignment.centerLeft, child: Text('Выберите слова:', style: TextStyle(fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _allWords.length,
                    itemBuilder: (context, index) {
                      final word = _allWords[index];
                      final isSelected = _selectedWordIds.contains(word.id);
                      return CheckboxListTile(
                        title: Text(word.japanese),
                        subtitle: Text(word.translation),
                        value: isSelected,
                        activeColor: Colors.deepPurple,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedWordIds.add(word.id);
                            } else {
                              _selectedWordIds.remove(word.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
